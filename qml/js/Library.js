.pragma library

// How the video list can be ordered, in VLC's order (DisplaySettingsDialog.kt).
// VLC also offers "Insertion date"; the system's library does not record when
// it first saw a file, so that one is left out.
var SORTS = [
    { key: "name", label: "Name", ascending: "A → Z", descending: "Z → A" },
    { key: "filename", label: "File name", ascending: "A → Z", descending: "Z → A" },
    { key: "length", label: "Length", ascending: "Shortest first", descending: "Longest first" },
    { key: "modified", label: "Recently added", ascending: "Oldest first", descending: "Newest first" }
];

function sortInfo(key) {
    for (var i = 0; i < SORTS.length; i++)
        if (SORTS[i].key === key)
            return SORTS[i];
    return SORTS[0];
}

function _fileName(path) {
    return path.substring(path.lastIndexOf("/") + 1).toLowerCase();
}

function _value(video, key) {
    if (key === "filename") return _fileName(video.filename || video.url);
    if (key === "length") return video.duration;
    if (key === "modified") return video.modified;
    return video.title.toLowerCase();
}

// The videos to show: those that pass the filter and the favourites switch,
// in the chosen order. `favourites` is { url: true }.
function arrange(videos, sort, descending, filter, onlyFavourites, favourites) {
    var needle = (filter || "").trim().toLowerCase();
    var kept = [];
    for (var i = 0; i < videos.length; i++) {
        var video = videos[i];
        if (onlyFavourites && !favourites[video.url])
            continue;
        if (needle && video.title.toLowerCase().indexOf(needle) < 0)
            continue;
        kept.push(video);
    }
    var key = sortInfo(sort).key;
    kept.sort(function(a, b) {
        var x = _value(a, key), y = _value(b, key);
        var order = x < y ? -1 : (x > y ? 1 : (a.url < b.url ? -1 : (a.url > b.url ? 1 : 0)));
        return descending ? -order : order;
    });
    return kept;
}
