.pragma library

/*
 * SubRip (.srt) subtitles: parsing, and finding the cue for a moment.
 */

function _time(text) {
    // 00:01:02,345 - some files use a dot, some drop the hours.
    var m = /(?:(\d+):)?(\d+):(\d+)[,.](\d+)/.exec(text);
    if (!m)
        return -1;
    var ms = (m[4] + "00").substring(0, 3);
    return ((parseInt(m[1] || "0", 10) * 60 + parseInt(m[2], 10)) * 60 + parseInt(m[3], 10)) * 1000
           + parseInt(ms, 10);
}

// The cue's text as Qt's StyledText: <b>, <i>, <u> and <font color> pass
// through as written; position codes like {\an8} go; line breaks become <br>.
function _styled(lines) {
    return lines.map(function(line) {
        return line.replace(/\{\\[^}]*\}/g, "")
                   .replace(/<\/?(?!\/?(b|i|u|font)\b)[^>]*>/gi, "");
    }).join("<br>");
}

// [{ start, end, text }] in playing order; times in milliseconds.
function parse(content) {
    var cues = [];
    // A byte-order mark at the start is not part of the first line.
    if (content.charCodeAt(0) === 0xFEFF)
        content = content.substring(1);
    var blocks = content.replace(/\r\n?/g, "\n").split(/\n{2,}/);
    for (var i = 0; i < blocks.length; i++) {
        var lines = blocks[i].split("\n");
        // The number line is optional; the timing line is the one with the arrow.
        var at = 0;
        while (at < lines.length && lines[at].indexOf("-->") < 0)
            at++;
        if (at >= lines.length)
            continue;
        var times = lines[at].split("-->");
        var start = _time(times[0]);
        var end = _time(times[1]);
        var text = lines.slice(at + 1).filter(function(line) { return line.trim().length > 0; });
        if (start < 0 || end < start || text.length === 0)
            continue;
        cues.push({ start: start, end: end, text: _styled(text) });
    }
    cues.sort(function(a, b) { return a.start - b.start; });
    return cues;
}

// Index of the cue showing at `ms`, or -1. `hint` is the previous answer:
// playback usually stays in the same cue or moves to the next one.
function cueAt(cues, ms, hint) {
    if (cues.length === 0)
        return -1;
    if (hint >= 0 && hint < cues.length && ms >= cues[hint].start && ms < cues[hint].end)
        return hint;
    // The last cue that has started.
    var low = 0, high = cues.length - 1, found = -1;
    while (low <= high) {
        var mid = (low + high) >> 1;
        if (cues[mid].start <= ms) {
            found = mid;
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    return found >= 0 && ms < cues[found].end ? found : -1;
}
