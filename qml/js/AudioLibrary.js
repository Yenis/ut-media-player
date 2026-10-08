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
    for (var i = 0; i < list.length; i++)
        list[i].subtitle = _sharedArtist(list[i].tracks) + "  \u2022  "
                           + _count(list[i].tracks.length, "track", "tracks");
    return list;
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

// What a tab lists: groups for artists, albums and genres, tracks for tracks
// and files.
function topLevel(tracks, tab) {
    if (tab === "files") return tracks;
    if (tab === "artists") return artists(tracks);
    if (tab === "albums") return albums(tracks);
    if (tab === "genres") return genres(tracks);
    return allTracks(tracks);
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
