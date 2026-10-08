.pragma library

/*
 * The music library's arithmetic: what the Audio tab lists under artists,
 * albums, tracks, genres and files, and in which order. The first four tabs
 * and their order are VLC for Android's (docs/VLC-FEATURES.md, "Audio
 * library"); "Files" is ours: every audio file by its file name, as the
 * system's library hands them over, neither sorted nor grouped.
 *
 * A track is what platform/MediaLibrary.qml gives: { url, title, artist,
 * albumArtist, album, genre, date, trackNumber, discNumber, duration, art }.
 */

var TABS = [
    { key: "artists", label: "Artists" },
    { key: "albums", label: "Albums" },
    { key: "tracks", label: "Tracks" },
    { key: "genres", label: "Genres" },
    { key: "files", label: "Files" }
];

// How each tab's list can be ordered; the first is how it comes. After VLC's
// choices for each list, without "insertion date", which the system's
// library does not record. "Files" has none: it is the library's own order.
var SORTS = {
    artists: [
        { key: "name", label: "Name", ascending: "A \u2192 Z", descending: "Z \u2192 A" }
    ],
    albums: [
        { key: "name", label: "Name", ascending: "A \u2192 Z", descending: "Z \u2192 A" },
        { key: "artist", label: "Artist", ascending: "A \u2192 Z", descending: "Z \u2192 A" },
        { key: "date", label: "Release date", ascending: "Oldest first", descending: "Newest first" }
    ],
    tracks: [
        { key: "name", label: "Name", ascending: "A \u2192 Z", descending: "Z \u2192 A" },
        { key: "album", label: "Album", ascending: "A \u2192 Z", descending: "Z \u2192 A" },
        { key: "artist", label: "Artist", ascending: "A \u2192 Z", descending: "Z \u2192 A" },
        { key: "length", label: "Length", ascending: "Shortest first", descending: "Longest first" },
        { key: "modified", label: "Recently added", ascending: "Oldest first", descending: "Newest first" }
    ],
    genres: [
        { key: "name", label: "Name", ascending: "A \u2192 Z", descending: "Z \u2192 A" }
    ],
    files: []
};

function sortInfo(tab, key) {
    var sorts = SORTS[tab] || [];
    for (var i = 0; i < sorts.length; i++)
        if (sorts[i].key === key)
            return sorts[i];
    return sorts.length > 0 ? sorts[0] : null;
}

var UNKNOWN_ARTIST = "Unknown artist";
var UNKNOWN_ALBUM = "Unknown album";
var UNKNOWN_GENRE = "Unknown genre";

function tabIndex(key) {
    for (var i = 0; i < TABS.length; i++)
        if (TABS[i].key === key)
            return i;
    return 0;
}

// The artist a track is listed under: the album's artist where the file names
// one, so that a compilation does not become twenty artists. VLC does the
// same unless "show all artists" is on.
function artistOf(track) {
    return track.albumArtist || track.artist || UNKNOWN_ARTIST;
}

function albumOf(track) {
    return track.album || UNKNOWN_ALBUM;
}

function genreOf(track) {
    return track.genre || UNKNOWN_GENRE;
}

function _text(a, b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    return a < b ? -1 : a > b ? 1 : 0;
}

function _byTitle(a, b) {
    return _text(a.title, b.title);
}

// Within an album: by disc, then track number, then title.
function _byPlace(a, b) {
    return (a.discNumber || 0) - (b.discNumber || 0)
        || (a.trackNumber || 0) - (b.trackNumber || 0)
        || _byTitle(a, b);
}

function _byAlbum(a, b) {
    return _text(albumOf(a), albumOf(b)) || _byPlace(a, b);
}

function _byArtist(a, b) {
    return _text(artistOf(a), artistOf(b)) || _byAlbum(a, b);
}

// The first cover found among some tracks, or "".
function artOf(tracks) {
    for (var i = 0; i < tracks.length; i++)
        if (tracks[i].art)
            return tracks[i].art;
    return "";
}

function _count(n, one, many) {
    return n + " " + (n === 1 ? one : many);
}

// Collects tracks under `keyOf(track)`, and returns the groups in the order
// of their titles, each with its tracks in `order`.
function _groups(tracks, kind, keyOf, titleOf, order) {
    var byKey = {};
    var list = [];
    for (var i = 0; i < tracks.length; i++) {
        var key = keyOf(tracks[i]);
        if (!byKey[key]) {
            byKey[key] = { kind: kind, key: kind + ":" + key, title: titleOf(tracks[i]), tracks: [] };
            list.push(byKey[key]);
        }
        byKey[key].tracks.push(tracks[i]);
    }
    for (var k = 0; k < list.length; k++) {
        list[k].tracks.sort(order);
        list[k].art = artOf(list[k].tracks);
    }
    list.sort(_byTitle);
    return list;
}

function _albumCount(tracks) {
    var seen = {};
    var n = 0;
    for (var i = 0; i < tracks.length; i++) {
        var key = albumOf(tracks[i]);
        if (!seen[key]) {
            seen[key] = true;
            n++;
        }
    }
    return n;
}

function artists(tracks) {
    var list = _groups(tracks, "artist", artistOf, artistOf, _byAlbum);
    for (var i = 0; i < list.length; i++)
        list[i].subtitle = _count(_albumCount(list[i].tracks), "album", "albums")
                           + "  •  " + _count(list[i].tracks.length, "track", "tracks");
    return list;
}

// Which album a track belongs to: its album title and the folder its file is
// in. The artist cannot decide: the tracks of one soundtrack often name a
// different artist each, as "album artist" too [device]. The folder keeps two
// albums that share a title apart. Tracks without an album are kept apart by
// artist, as VLC does.
function _albumKey(track) {
    if (!track.album)
        return "\n" + artistOf(track);
    var path = track.url.toString();
    return track.album + "\n" + path.substring(0, path.lastIndexOf("/"));
}

// The one artist all of some tracks share, or "Various artists".
function _sharedArtist(tracks) {
    var first = artistOf(tracks[0]);
    for (var i = 1; i < tracks.length; i++)
        if (artistOf(tracks[i]) !== first)
            return "Various artists";
    return first;
}

function albums(tracks) {
    var list = _groups(tracks, "album", _albumKey, albumOf, _byPlace);
    for (var i = 0; i < list.length; i++) {
        list[i].artist = _sharedArtist(list[i].tracks);
        list[i].date = _dateOf(list[i].tracks);
        list[i].subtitle = list[i].artist + "  \u2022  " + _count(list[i].tracks.length, "track", "tracks");
    }
    return list;
}

// The first date found among some tracks, as the files give it, or "".
function _dateOf(tracks) {
    for (var i = 0; i < tracks.length; i++)
        if (tracks[i].date)
            return tracks[i].date;
    return "";
}

function genres(tracks) {
    var list = _groups(tracks, "genre", genreOf, genreOf, _byArtist);
    for (var i = 0; i < list.length; i++)
        list[i].subtitle = _count(list[i].tracks.length, "track", "tracks");
    return list;
}

function allTracks(tracks) {
    return tracks.slice().sort(_byTitle);
}

// A track's file name, and the folder it is in, for the "Files" tab.
function fileName(track) {
    var path = track.filename || decodeURIComponent(track.url.toString());
    return path.substring(path.lastIndexOf("/") + 1);
}

function folderName(track) {
    var path = track.filename || decodeURIComponent(track.url.toString());
    var folder = path.substring(0, path.lastIndexOf("/"));
    return folder.substring(folder.lastIndexOf("/") + 1);
}

// The tracks a tab is left with when its list is filtered by `text`: by what
// the tab lists, so that an artist, album or genre that matches keeps all of
// its tracks. "Tracks" looks at title, artist and album.
function filtered(tracks, tab, text) {
    var needle = (text || "").trim().toLowerCase();
    if (!needle)
        return tracks;
    function has(value) { return value.toLowerCase().indexOf(needle) >= 0; }
    return tracks.filter(function(t) {
        if (tab === "artists") return has(artistOf(t));
        if (tab === "albums") return has(albumOf(t));
        if (tab === "genres") return has(genreOf(t));
        if (tab === "files") return has(fileName(t));
        return has(t.title) || has(artistOf(t)) || has(albumOf(t));
    });
}

// Only the tracks that are favourites; `favourites` is { url: true }.
function favouritesOnly(tracks, favourites) {
    return tracks.filter(function(t) { return !!favourites[t.url]; });
}

function _number(a, b) { return a - b; }

// Puts a tab's list into the order chosen. Names are in order already.
function _sorted(list, tab, sort, descending) {
    var by = null;
    if (tab === "albums" && sort === "artist")
        by = function(a, b) { return _text(a.artist, b.artist) || _byTitle(a, b); };
    else if (tab === "albums" && sort === "date")
        by = function(a, b) { return _text(a.date, b.date) || _byTitle(a, b); };
    else if (tab === "tracks" && sort === "album")
        by = _byAlbum;
    else if (tab === "tracks" && sort === "artist")
        by = _byArtist;
    else if (tab === "tracks" && sort === "length")
        by = function(a, b) { return _number(a.duration, b.duration) || _byTitle(a, b); };
    else if (tab === "tracks" && sort === "modified")
        by = function(a, b) { return _number(a.modified, b.modified) || _byTitle(a, b); };
    if (by)
        list.sort(by);
    if (descending)
        list.reverse();
    return list;
}

// What a tab lists: groups for artists, albums and genres, tracks for tracks
// and files; in the order chosen for it.
function topLevel(tracks, tab, sort, descending) {
    if (tab === "files") return tracks;
    var list = tab === "artists" ? artists(tracks)
             : tab === "albums" ? albums(tracks)
             : tab === "genres" ? genres(tracks)
             : allTracks(tracks);
    return _sorted(list, tab, sort || "name", !!descending);
}

// The key of the album or the artist a track is listed under, as the groups
// of `albums` and `artists` carry it.
function groupKey(kind, track) {
    return kind + ":" + (kind === "album" ? _albumKey(track) : artistOf(track));
}

function findGroup(groups, key) {
    for (var i = 0; i < groups.length; i++)
        if (groups[i].key === key)
            return groups[i];
    return null;
}

/*
 * The rows of an open group: its tracks, with a heading wherever the album
 * changes when the group is an artist or a genre. A heading is
 * { section: "title" }; a track row is the track itself.
 */
function rowsOf(group) {
    var rows = [];
    var last = null;
    for (var i = 0; i < group.tracks.length; i++) {
        var track = group.tracks[i];
        if (group.kind !== "album") {
            var heading = group.kind === "genre" ? artistOf(track) + " – " + albumOf(track) : albumOf(track);
            if (heading !== last) {
                rows.push({ section: heading });
                last = heading;
            }
        }
        rows.push(track);
    }
    return rows;
}
