.pragma library
.import "Encodings.tables.js" as Tables

/*
 * Turns the bytes of a subtitle file into text, in one of VLC's subtitle
 * encodings. Qt's XMLHttpRequest reads a file as UTF-8 only, but hands over
 * its bytes; the list and the tables are written by tools/make-encodings.py.
 *
 * A double-byte encoding (Chinese, Japanese, Korean) needs its table file,
 * qml/js/encodings/<tableFile(key)>.txt, read first and passed to `decode`.
 */

var choices = Tables.choices;

function name(key) {
    for (var i = 0; i < choices.length; i++) {
        if (choices[i].key === key)
            return choices[i].name;
    }
    return key;
}

// The table file a double-byte encoding needs, or "".
function tableFile(key) {
    return Tables.double[key] || "";
}

// "Automatic", as VLC has it: a byte-order mark if there is one, UTF-8 if
// the bytes are valid UTF-8, and otherwise Windows-1252.
function detect(bytes) {
    if (bytes.length >= 3 && bytes[0] === 0xEF && bytes[1] === 0xBB && bytes[2] === 0xBF)
        return "UTF-8";
    if (bytes.length >= 2 && bytes[0] === 0xFF && bytes[1] === 0xFE)
        return "UTF-16LE";
    if (bytes.length >= 2 && bytes[0] === 0xFE && bytes[1] === 0xFF)
        return "UTF-16BE";
    return isUtf8(bytes) ? "UTF-8" : "Windows-1252";
}

function isUtf8(bytes) {
    var i = 0, n = bytes.length;
    while (i < n) {
        var b = bytes[i];
        var more = b < 0x80 ? 0 : (b & 0xE0) === 0xC0 && b >= 0xC2 ? 1 : (b & 0xF0) === 0xE0 ? 2
                 : (b & 0xF8) === 0xF0 && b <= 0xF4 ? 3 : -1;
        if (more < 0 || i + more >= n + (more > 0 ? 0 : 1))
            return false;
        for (var k = 1; k <= more; k++) {
            if ((bytes[i + k] & 0xC0) !== 0x80)
                return false;
        }
        i += more + 1;
    }
    return true;
}

// `bytes`: a Uint8Array. `table`: the contents of the table file, for a
// double-byte encoding.
function decode(bytes, key, table) {
    var how = Tables.unicode[key];
    if (how === "utf8")
        return _utf8(bytes);
    if (how === "utf16be" || how === "utf16le" || how === "utf16")
        return _utf16(bytes, how);
    if (Tables.single[key])
        return _single(bytes, Tables.single[key], Tables.lower[key] || "");
    if (Tables.double[key] && table)
        return _double(bytes, key, table);
    return _utf8(bytes);
}

// ---- the decoders ---------------------------------------------------------------

var BAD = 0xFFFD;

// Character codes to a string, a slice at a time: a call takes only so
// many arguments.
function _text(codes) {
    var parts = [];
    for (var i = 0; i < codes.length; i += 8192)
        parts.push(String.fromCharCode.apply(null, codes.slice(i, i + 8192)));
    return parts.join("");
}

function _utf8(bytes) {
    var codes = [];
    var i = 0, n = bytes.length;
    if (n >= 3 && bytes[0] === 0xEF && bytes[1] === 0xBB && bytes[2] === 0xBF)
        i = 3;
    while (i < n) {
        var b = bytes[i];
        var more = b < 0x80 ? 0 : (b & 0xE0) === 0xC0 ? 1 : (b & 0xF0) === 0xE0 ? 2 : (b & 0xF8) === 0xF0 ? 3 : -1;
        var code = more === 0 ? b : more === 1 ? b & 0x1F : more === 2 ? b & 0x0F : b & 0x07;
        var ok = more >= 0 && i + more < n + (more === 0 ? 1 : 0);
        for (var k = 1; ok && k <= more; k++) {
            if ((bytes[i + k] & 0xC0) !== 0x80)
                ok = false;
            else
                code = (code << 6) | (bytes[i + k] & 0x3F);
        }
        if (!ok) {
            codes.push(BAD);
            i++;
            continue;
        }
        if (code >= 0x10000) {
            code -= 0x10000;
            codes.push(0xD800 + (code >> 10), 0xDC00 + (code & 0x3FF));
        } else {
            codes.push(code);
        }
        i += more + 1;
    }
    return _text(codes);
}

// Without a byte-order mark, plain UTF-16 is taken for little endian, unless
// the first byte is 0, as a text starting with a Latin letter would have it
// in big endian.
function _utf16(bytes, how) {
    var i = 0;
    var big = how === "utf16be";
    if (bytes.length >= 2 && ((bytes[0] === 0xFF && bytes[1] === 0xFE) || (bytes[0] === 0xFE && bytes[1] === 0xFF))) {
        if (how === "utf16")
            big = bytes[0] === 0xFE;
        i = 2;
    } else if (how === "utf16") {
        big = bytes.length >= 2 && bytes[0] === 0 && bytes[1] !== 0;
    }
    var codes = [];
    for (; i + 1 < bytes.length; i += 2)
        codes.push(big ? (bytes[i] << 8) | bytes[i + 1] : bytes[i] | (bytes[i + 1] << 8));
    return _text(codes);
}

// `low`: 0x00 to 0x1F, for VISCII, which has six letters there; "" for
// the others.
function _single(bytes, upper, low) {
    var codes = new Array(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
        var b = bytes[i];
        codes[i] = b >= 0x80 ? upper.charCodeAt(b - 0x80) : low !== "" && b < 0x20 ? low.charCodeAt(b) : b;
    }
    return _text(codes);
}

// The table: 128 characters for 0x80 to 0xFF on their own (0 where the byte
// starts a pair), then one for each pair, lead 0x81 to 0xFE by trail 0x40
// to 0xFE; for EUC-JP then one for each 0x8F triple, 0xA1 to 0xFE twice.
function _double(bytes, key, table) {
    var codes = [];
    var n = bytes.length;
    var gb = key === "GB18030" || key === "EUC-CN";
    for (var i = 0; i < n; i++) {
        var b = bytes[i];
        if (b < 0x80) {
            codes.push(b);
            continue;
        }
        var alone = table.charCodeAt(b - 0x80);
        if (alone !== 0) {
            codes.push(alone);
            continue;
        }
        var t = i + 1 < n ? bytes[i + 1] : -1;
        if (gb && t >= 0x30 && t <= 0x39) {
            if (i + 3 < n)
                _gb18030Four(codes, b, t, bytes[i + 2], bytes[i + 3]);
            else
                codes.push(BAD);
            i += 3;
        } else if (key === "EUC-JP" && b === 0x8F) {
            var t2 = i + 2 < n ? bytes[i + 2] : -1;
            codes.push(t >= 0xA1 && t <= 0xFE && t2 >= 0xA1 && t2 <= 0xFE
                       ? table.charCodeAt(128 + 126 * 191 + (t - 0xA1) * 94 + (t2 - 0xA1)) : BAD);
            i += 2;
        } else if (b >= 0x81 && b <= 0xFE && t >= 0x40 && t <= 0xFE) {
            codes.push(table.charCodeAt(128 + (b - 0x81) * 191 + (t - 0x40)));
            i++;
        } else {
            codes.push(BAD);
        }
    }
    return _text(codes);
}

// GB18030's four bytes: by runs in the Basic Multilingual Plane, from
// U+10000 straight on beyond it.
function _gb18030Four(codes, b1, b2, b3, b4) {
    if (b3 < 0x81 || b3 > 0xFE || b4 < 0x30 || b4 > 0x39) {
        codes.push(BAD);
        return;
    }
    var index = (((b1 - 0x81) * 10 + (b2 - 0x30)) * 126 + (b3 - 0x81)) * 10 + (b4 - 0x30);
    if (b1 >= 0x90) {
        var code = 0x10000 + index - 189000;
        if (code < 0x10000 || code > 0x10FFFF) {
            codes.push(BAD);
        } else {
            code -= 0x10000;
            codes.push(0xD800 + (code >> 10), 0xDC00 + (code & 0x3FF));
        }
        return;
    }
    var runs = Tables.gb18030Runs;
    if (index >= 39420 || index < runs[0][0]) {
        codes.push(BAD);
        return;
    }
    var low = 0, high = runs.length - 1;
    while (low < high) {
        var mid = (low + high + 1) >> 1;
        if (runs[mid][0] <= index)
            low = mid;
        else
            high = mid - 1;
    }
    codes.push(runs[low][1] + index - runs[low][0]);
}
