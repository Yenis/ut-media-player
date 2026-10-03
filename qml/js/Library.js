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

// --- Grouping ---------------------------------------------------------------

function _folder(video) {
    var path = video.filename || decodeURIComponent(video.url.replace("file://", ""));
    return path.substring(0, path.lastIndexOf("/"));
}

// One entry per folder that holds videos, as VLC's "Group by folder" shows
// them: { key, kind: "folder", title, path, videos }. Folders are in order of
// name; the videos inside keep the order they came in.
function byFolder(videos, descending) {
    var seen = {}, folders = [];
    for (var i = 0; i < videos.length; i++) {
        var path = _folder(videos[i]);
        if (!seen[path]) {
            seen[path] = { key: "folder:" + path, kind: "folder", path: path, videos: [],
                           title: path.substring(path.lastIndexOf("/") + 1) || "/" };
            folders.push(seen[path]);
        }
        seen[path].videos.push(videos[i]);
    }
    folders.sort(function(a, b) {
        var x = a.title.toLowerCase(), y = b.title.toLowerCase();
        var order = x < y ? -1 : (x > y ? 1 : (a.path < b.path ? -1 : 1));
        return descending ? -order : order;
    });
    return folders;
}

// VLC groups videos whose names begin alike. The rule is in its native media
// library, which is not in the reference clone: the first six characters,
// ignoring case and a leading "the ".
var GROUP_PREFIX = 6;

function _prefix(title) {
    var text = title.toLowerCase();
    if (text.indexOf("the ") === 0)
        text = text.substring(4);
    return text.substring(0, GROUP_PREFIX);
}

// What the members' names have in common, for the group's own name.
function _commonTitle(videos) {
    var common = videos[0].title;
    for (var i = 1; i < videos.length; i++) {
        var other = videos[i].title, n = 0;
        while (n < common.length && n < other.length
               && common.charAt(n).toLowerCase() === other.charAt(n).toLowerCase())
            n++;
        common = common.substring(0, n);
    }
    // Cut in the middle of a number ("Holiday 0" from 01 and 02): drop the digits.
    var next = videos[0].title.charAt(common.length);
    if (next >= "0" && next <= "9")
        common = common.replace(/[0-9]+$/, "");
    common = common.replace(/[\s\-_.,(\[]+$/, "");
    return common.length > 0 ? common : videos[0].title.substring(0, GROUP_PREFIX);
}

// "Group by name": videos alone stay as they are; two or more that begin
// alike become { key, kind: "group", title, videos } at the place of the
// first of them.
//
// `manual` is what was arranged by hand, as PlayerStore.videoGroups() gives
// it: a video put into a group goes there, under the group's own name and
// with `groupId` set, and a video kept on its own (group 0) joins nothing.
function byName(videos, manual) {
    var names = manual ? manual.names : {};
    var members = manual ? manual.members : {};
    var buckets = {}, order = [];
    for (var i = 0; i < videos.length; i++) {
        var id = members[videos[i].url];
        var bucket = id > 0 && names[id] !== undefined ? "m" + id
                   : id === 0 ? "alone:" + videos[i].url
                   : "a" + _prefix(videos[i].title);
        if (!buckets[bucket]) {
            buckets[bucket] = [];
            order.push(bucket);
        }
        buckets[bucket].push(videos[i]);
    }
    var items = [];
    for (var k = 0; k < order.length; k++) {
        var inside = buckets[order[k]];
        var byHand = order[k].charAt(0) === "m";
        if (inside.length === 1)
            items.push(inside[0]);
        else if (byHand)
            items.push({ key: "group:" + order[k], kind: "group", videos: inside,
                         groupId: parseInt(order[k].substring(1)), title: names[order[k].substring(1)] });
        else
            items.push({ key: "group:" + order[k], kind: "group", videos: inside, groupId: 0,
                         title: _commonTitle(inside) });
    }
    return items;
}

function commonTitle(videos) {
    return videos.length > 1 ? _commonTitle(videos) : "";
}

// The top level of the list for a grouping: "none", "folder" or "name".
function grouped(videos, grouping, sort, descending, manual) {
    if (grouping === "folder")
        return byFolder(videos, descending && (sort === "name" || sort === "filename"));
    if (grouping === "name")
        return byName(videos, manual);
    return videos;
}

function findGroup(items, key) {
    for (var i = 0; i < items.length; i++)
        if (items[i].key === key)
            return items[i];
    return null;
}

var GROUPINGS = [
    { key: "name", label: "Group by name", short: "By name" },
    { key: "folder", label: "Group by folder", short: "By folder" },
    { key: "none", label: "Do not group videos", short: "Off" }
];

function groupingInfo(key) {
    for (var i = 0; i < GROUPINGS.length; i++)
        if (GROUPINGS[i].key === key)
            return GROUPINGS[i];
    return GROUPINGS[0];
}
