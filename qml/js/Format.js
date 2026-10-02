.pragma library

// "2:03" or "1:02:03", as VLC shows times.
function clock(ms) {
    var total = Math.floor(Math.max(0, ms) / 1000);
    var h = Math.floor(total / 3600);
    var m = Math.floor((total % 3600) / 60);
    var s = total % 60;
    var tail = (s < 10 ? "0" : "") + s;
    if (h > 0)
        return h + ":" + (m < 10 ? "0" : "") + m + ":" + tail;
    return m + ":" + tail;
}

// "+0:42" or "-1:10".
function signedClock(ms) {
    return (ms >= 0 ? "+" : "-") + clock(Math.abs(ms));
}

// The last part of a path or URL, without the extension, for files that have
// no title of their own.
function baseName(path) {
    var name = decodeURIComponent(path.toString());
    name = name.substring(name.lastIndexOf("/") + 1);
    var dot = name.lastIndexOf(".");
    return dot > 0 ? name.substring(0, dot) : name;
}
