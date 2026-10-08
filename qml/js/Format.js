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

// "1080p", "SD" and so on, as VLC labels a video's size
// (generateResolutionClass in Kextensions.kt). Empty when the size is unknown.
// The library reports coded sizes, 1920x1088 for 1080p; the steps absorb that.
function resolutionClass(width, height) {
    if (!(width > 0) || !(height > 0))
        return "";
    var shortSide = Math.min(width, height);
    var longSide = Math.max(width, height);
    var steps = [[4320, "8K"], [2160, "4K"], [1440, "1440p"], [1080, "1080p"], [720, "720p"]];
    for (var i = 0; i < steps.length; i++)
        if (shortSide >= steps[i][0] || longSide >= steps[i][0] * 16 / 9)
            return steps[i][1];
    return "SD";
}

// "755 KB", "1.4 GB": a file's size in the units a person reads.
function fileSize(bytes) {
    var units = ["bytes", "KB", "MB", "GB", "TB"];
    var value = Math.max(0, bytes), unit = 0;
    while (value >= 1000 && unit < units.length - 1) {
        value /= 1000;
        unit++;
    }
    return (unit === 0 || value >= 100 ? Math.round(value) : value.toFixed(1)) + " " + units[unit];
}

// The last part of a path or URL, without the extension, for files that have
// no title of their own.
function baseName(path) {
    var name = decodeURIComponent(path.toString());
    name = name.substring(name.lastIndexOf("/") + 1);
    var dot = name.lastIndexOf(".");
    return dot > 0 ? name.substring(0, dot) : name;
}

// The files a media player is for, by the end of their names: what the
// Browse tab lists, and how it tells music from video.
var AUDIO_EXTENSIONS = ["mp3", "flac", "ogg", "oga", "opus", "m4a", "aac", "wav", "wma", "mka", "ape", "aif", "aiff"];
var VIDEO_EXTENSIONS = ["mp4", "m4v", "mkv", "webm", "avi", "mov", "mpg", "mpeg", "ts", "m2ts", "wmv", "flv",
                        "3gp", "ogv"];

// Whether a file is music, going by its name: for files the library does not
// know, which could otherwise only be assumed to have a picture.
function isAudioName(path) {
    var name = path.toString().toLowerCase();
    return AUDIO_EXTENSIONS.indexOf(name.substring(name.lastIndexOf(".") + 1)) >= 0;
}

// Name patterns for a listing of a folder's media files, either case.
function mediaNameFilters() {
    var all = AUDIO_EXTENSIONS.concat(VIDEO_EXTENSIONS);
    var filters = [];
    for (var i = 0; i < all.length; i++) {
        filters.push("*." + all[i]);
        filters.push("*." + all[i].toUpperCase());
    }
    return filters;
}
