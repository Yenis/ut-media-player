#!/usr/bin/env python3
"""
Writes the subtitle encodings the app can read: qml/js/Encodings.js, with the
list in VLC's order and a table for each single-byte encoding, and one table
file per double-byte encoding in qml/js/encodings/, read only when chosen.

Qt's XMLHttpRequest reads a file as UTF-8 and nothing else, but hands over
its bytes, so the app decodes them itself (docs/PLAN.md, version 0.0.37).
The tables come from Python's codecs, and VISCII, which Python lacks, from
iconv. Run it again only to change the list:

    python3 tools/make-encodings.py
"""
import json
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# VLC's list (res/values/arrays.xml, subtitles_encoding_list), with what each
# is read as here. None: in VLC's list, not read here.
CHOICES = [
    ("UTF-8", "Universal (UTF-8)", "utf8"),
    ("UTF-16", "Universal (UTF-16)", "utf16"),
    ("UTF-16BE", "Universal (big endian UTF-16)", "utf16be"),
    ("UTF-16LE", "Universal (little endian UTF-16)", "utf16le"),
    ("GB18030", "Universal, Chinese (GB18030)", ("double", "gb18030")),
    ("ISO-8859-15", "Western European (Latin-9)", ("single", "iso8859_15")),
    ("Windows-1252", "Western European (Windows-1252)", ("single", "cp1252")),
    ("IBM850", "Western European (IBM 00850)", ("single", "cp850")),
    ("ISO-8859-2", "Eastern European (Latin-2)", ("single", "iso8859_2")),
    ("Windows-1250", "Eastern European (Windows-1250)", ("single", "cp1250")),
    ("ISO-8859-3", "Esperanto (Latin-3)", ("single", "iso8859_3")),
    ("ISO-8859-10", "Nordic (Latin-6)", ("single", "iso8859_10")),
    ("Windows-1251", "Cyrillic (Windows-1251)", ("single", "cp1251")),
    ("KOI8-R", "Russian (KOI8-R)", ("single", "koi8_r")),
    ("KOI8-U", "Ukrainian (KOI8-U)", ("single", "koi8_u")),
    ("ISO-8859-6", "Arabic (ISO 8859-6)", ("single", "iso8859_6")),
    ("Windows-1256", "Arabic (Windows-1256)", ("single", "cp1256")),
    ("ISO-8859-7", "Greek (ISO 8859-7)", ("single", "iso8859_7")),
    ("Windows-1253", "Greek (Windows-1253)", ("single", "cp1253")),
    ("ISO-8859-8", "Hebrew (ISO 8859-8)", ("single", "iso8859_8")),
    ("Windows-1255", "Hebrew (Windows-1255)", ("single", "cp1255")),
    ("ISO-8859-9", "Turkish (ISO 8859-9)", ("single", "iso8859_9")),
    ("Windows-1254", "Turkish (Windows-1254)", ("single", "cp1254")),
    ("TIS-620", "Thai (TIS 620-2533/ISO 8859-11)", ("single", "tis_620")),
    ("Windows-874", "Thai (Windows-874)", ("single", "cp874")),
    ("ISO-8859-13", "Baltic (Latin-7)", ("single", "iso8859_13")),
    ("Windows-1257", "Baltic (Windows-1257)", ("single", "cp1257")),
    ("ISO-8859-14", "Celtic (Latin-8)", ("single", "iso8859_14")),
    ("ISO-8859-16", "South-Eastern European (Latin-10)", ("single", "iso8859_16")),
    ("ISO-2022-CN-EXT", "Simplified Chinese (ISO-2022-CN-EXT)", None),
    ("EUC-CN", "Simplified Chinese Unix (EUC-CN)", ("double", "gb18030")),
    ("ISO-2022-JP-2", "Japanese (7-bits JIS/ISO-2022-JP-2)", None),
    ("EUC-JP", "Japanese Unix (EUC-JP)", ("double", "euc_jp")),
    ("Shift_JIS", "Japanese (Shift JIS)", ("double", "cp932")),
    ("CP949", "Korean (EUC-KR/CP949)", ("double", "cp949")),
    ("ISO-2022-KR", "Korean (ISO-2022-KR)", None),
    ("Big5", "Traditional Chinese (Big5)", ("double", "cp950")),
    ("EUC-TW", "Traditional Chinese Unix (EUC-TW)", None),
    ("HKSCS", "Hong-Kong Supplementary (HKSCS)", None),
    ("VISCII", "Vietnamese (VISCII)", ("single", "VISCII")),
    ("Windows-1258", "Vietnamese (Windows-1258)", ("single", "cp1258")),
]

LEADS = range(0x81, 0xFF)       # a double-byte table: every lead byte...
TRAILS = range(0x40, 0xFF)      # ...by every trail byte
BAD = "�"


def one(codec, data):
    try:
        text = data.decode(codec)
    except UnicodeDecodeError:
        return None
    # One character in the Basic Multilingual Plane, or the app could not
    # index the table by position.
    return text if len(text) == 1 and ord(text) < 0x10000 else None


def viscii(data):
    raw = subprocess.run(["iconv", "-f", "VISCII", "-t", "UTF-8"], input=data,
                         capture_output=True, check=True).stdout.decode("utf-8")
    assert len(raw) == len(data)
    return raw


def single(codec):
    """The upper half, 0x80 to 0xFF; the lower is ASCII in all of them but VISCII."""
    if codec == "VISCII":
        return viscii(bytes(range(0x80, 0x100)))
    return "".join(one(codec, bytes([b])) or BAD for b in range(0x80, 0x100))


def lower(codec):
    """0x00 to 0x1F where they are not ASCII's: VISCII has six letters there."""
    if codec != "VISCII":
        return None
    raw = viscii(bytes(range(0x20)))
    return raw if raw != "".join(chr(b) for b in range(0x20)) else None


def double(codec):
    """The upper half as single bytes where it is one, then the grid of pairs.
    EUC-JP adds its three-byte characters, 0x8F and two bytes 0xA1 to 0xFE."""
    singles = "".join(one(codec, bytes([b])) or "\0" for b in range(0x80, 0x100))
    pairs = "".join(one(codec, bytes([lead, trail])) or BAD for lead in LEADS for trail in TRAILS)
    triples = ""
    if codec == "euc_jp":
        triples = "".join(one(codec, bytes([0x8F, a, b])) or BAD for a in range(0xA1, 0xFF) for b in range(0xA1, 0xFF))
    return singles + pairs + triples


def gb18030_runs():
    """GB18030's four-byte forms below 0x90 count through the rest of the
    Basic Multilingual Plane in order, with jumps: [index, code point] where
    each run starts. Beyond 0x90 they count from U+10000 without jumps."""
    runs = []
    expected = None
    for index in range(39420):
        b1, rest = divmod(index, 12600)
        b2, rest = divmod(rest, 1260)
        b3, b4 = divmod(rest, 10)
        data = bytes([0x81 + b1, 0x30 + b2, 0x81 + b3, 0x30 + b4])
        try:
            code = ord(data.decode("gb18030"))
        except (UnicodeDecodeError, TypeError):
            expected = None
            continue
        if code != expected:
            runs.append([index, code])
        expected = code + 1
    return runs


def main():
    tables = {}
    lowers = {}
    files = {}
    unicode = {}
    choices = [{"key": "", "name": "Automatic"}]
    for key, name, how in CHOICES:
        if how is None:
            continue
        choices.append({"key": key, "name": name})
        if isinstance(how, tuple) and how[0] == "single":
            tables[key] = single(how[1])
            if lower(how[1]):
                lowers[key] = lower(how[1])
        elif isinstance(how, tuple) and how[0] == "double":
            files[key] = how[1]
        else:
            unicode[key] = how
    out = os.path.join(ROOT, "qml", "js", "encodings")
    os.makedirs(out, exist_ok=True)
    for codec in sorted(set(files.values())):
        with open(os.path.join(out, codec + ".txt"), "w", encoding="utf-8", newline="") as f:
            f.write(double(codec))
    left_out = ", ".join(name for key, name, how in CHOICES if how is None)
    with open(os.path.join(ROOT, "qml", "js", "Encodings.tables.js"), "w", encoding="utf-8") as f:
        f.write(".pragma library\n\n")
        f.write("// Written by tools/make-encodings.py; not edited by hand.\n")
        f.write("// In VLC's list but not read here: " + left_out + ".\n\n")
        f.write("var choices = [\n" + ",\n".join("    " + json.dumps(c) for c in choices) + "\n];\n\n")
        f.write("// Unicode, decoded in code.\n")
        f.write("var unicode = " + json.dumps(unicode) + ";\n\n")
        f.write("// The upper half of each single-byte encoding, 0x80 to 0xFF.\n")
        f.write("var single = " + json.dumps(tables, indent=0) + ";\n\n")
        f.write("// 0x00 to 0x1F, for the one that does not leave them to ASCII.\n")
        f.write("var lower = " + json.dumps(lowers) + ";\n\n")
        f.write("// Double-byte encodings: the table file in qml/js/encodings/, without \".txt\".\n")
        f.write("var double = " + json.dumps(files, indent=0) + ";\n\n")
        f.write("// GB18030's four-byte forms in the Basic Multilingual Plane: [index, code point] where a run starts.\n")
        f.write("var gb18030Runs = " + json.dumps(gb18030_runs(), separators=(",", ":")) + ";\n")
    print(len(choices), "choices,", len(unicode), "Unicode,", len(tables), "single-byte,",
          len(set(files.values())), "table files")


main()
