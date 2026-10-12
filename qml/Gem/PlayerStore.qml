import QtQuick 2.12
import QtQuick.LocalStorage 2.0
import "../js/DbHandle.js" as DbHandle

/*
 * What the player remembers about each file: where it was left, whether it
 * was seen, its bookmarks, and whether it is a favourite; and the playlists.
 * Kept in the app's SQLite database
 * (~/.local/share/gemplayer.yenis/), opened on first use so nothing touches
 * storage before Main.qml has set the app identity.
 */
QtObject {
    id: store

    // Count changes, so views showing progress or bookmarks can refresh.
    property int revision: 0
    property int bookmarkRevision: 0
    property int favouriteRevision: 0
    property int groupRevision: 0
    property int playlistRevision: 0
    property int streamRevision: 0

    // A file counts as finished this close to its end, and as not started this
    // close to its beginning. VLC decides this in its native media library,
    // which is not in the reference clone; these are our own values.
    readonly property int startMargin: 10000
    function endMargin(duration) { return Math.max(10000, duration * 0.02); }

    function db() {
        if (DbHandle.handle)
            return DbHandle.handle;
        var opened = LocalStorage.openDatabaseSync("gemplayer", "1.0", "GemPlayer", 1000000);
        opened.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS media("
                          + "url TEXT PRIMARY KEY, position INTEGER NOT NULL DEFAULT 0, "
                          + "duration INTEGER NOT NULL DEFAULT 0, seen INTEGER NOT NULL DEFAULT 0, "
                          + "played_at INTEGER NOT NULL DEFAULT 0)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS bookmarks("
                          + "url TEXT NOT NULL, position INTEGER NOT NULL, title TEXT NOT NULL, "
                          + "PRIMARY KEY(url, position))");
            tx.executeSql("CREATE TABLE IF NOT EXISTS favourites(url TEXT PRIMARY KEY)");
            // Video groups made by hand. A member row with group 0 keeps a
            // video on its own, out of the groups that form by name.
            tx.executeSql("CREATE TABLE IF NOT EXISTS video_groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS video_group_members(url TEXT PRIMARY KEY, group_id INTEGER NOT NULL)");
            // Single values under a name: the audio queue to come back to.
            tx.executeSql("CREATE TABLE IF NOT EXISTS kept(name TEXT PRIMARY KEY, value TEXT NOT NULL)");
            // Playlists. An item is kept whole, as the players take it, so a
            // playlist shows without the library and can hold a file the
            // library does not know.
            tx.executeSql("CREATE TABLE IF NOT EXISTS playlists(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)");
            // The addresses of streams that were opened, with the names given them.
            tx.executeSql("CREATE TABLE IF NOT EXISTS streams("
                          + "url TEXT PRIMARY KEY, title TEXT NOT NULL, opened_at INTEGER NOT NULL DEFAULT 0)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS playlist_items("
                          + "playlist_id INTEGER NOT NULL, place INTEGER NOT NULL, url TEXT NOT NULL, media TEXT NOT NULL)");
        });
        DbHandle.handle = opened;
        return opened;
    }

    // { position, duration, seen } for a file, or null if it was never played.
    function entry(url) {
        var found = null;
        db().readTransaction(function(tx) {
            var rows = tx.executeSql("SELECT position, duration, seen FROM media WHERE url = ?", [url]).rows;
            if (rows.length > 0)
                found = { position: rows.item(0).position, duration: rows.item(0).duration,
                          seen: rows.item(0).seen };
        });
        return found;
    }

    // Every played file at once, as { url: { position, duration, seen } }, for
    // lists that show progress.
    function entries() {
        var all = {};
        db().readTransaction(function(tx) {
            var rows = tx.executeSql("SELECT url, position, duration, seen FROM media").rows;
            for (var i = 0; i < rows.length; i++)
                all[rows.item(i).url] = { position: rows.item(i).position, duration: rows.item(i).duration,
                                          seen: rows.item(i).seen };
        });
        return all;
    }

    // Where to start a file: 0 unless it was left somewhere in the middle.
    function resumePoint(url) {
        var e = entry(url);
        return e ? e.position : 0;
    }

    function save(url, position, duration) {
        if (!url || duration <= 0)
            return;
        var finished = position >= duration - endMargin(duration);
        var keep = (finished || position < startMargin) ? 0 : Math.round(position);
        db().transaction(function(tx) {
            tx.executeSql("INSERT OR IGNORE INTO media(url) VALUES(?)", [url]);
            tx.executeSql("UPDATE media SET position = ?, duration = ?, played_at = ?, "
                          + "seen = CASE WHEN ? THEN 1 ELSE seen END WHERE url = ?",
                          [keep, Math.round(duration), Date.now(), finished ? 1 : 0, url]);
        });
        revision++;
    }

    // "Mark as played" and "Mark as not played": either way the file starts
    // from its beginning next time.
    function setSeen(url, on, duration) {
        if (!url)
            return;
        db().transaction(function(tx) {
            tx.executeSql("INSERT OR IGNORE INTO media(url) VALUES(?)", [url]);
            tx.executeSql("UPDATE media SET position = 0, seen = ?, "
                          + "duration = CASE WHEN duration > 0 THEN duration ELSE ? END WHERE url = ?",
                          [on ? 1 : 0, Math.round(duration || 0), url]);
        });
        revision++;
    }

    // Played to the end: back to the start, and marked as seen.
    function finish(url, duration) {
        save(url, duration, duration);
    }

    // Every favourite, as { url: true }.
    function favourites() {
        var all = {};
        db().readTransaction(function(tx) {
            var rows = tx.executeSql("SELECT url FROM favourites").rows;
            for (var i = 0; i < rows.length; i++)
                all[rows.item(i).url] = true;
        });
        return all;
    }

    function setFavourite(url, on) {
        if (!url)
            return;
        db().transaction(function(tx) {
            if (on)
                tx.executeSql("INSERT OR IGNORE INTO favourites(url) VALUES(?)", [url]);
            else
                tx.executeSql("DELETE FROM favourites WHERE url = ?", [url]);
        });
        favouriteRevision++;
    }

    // The groups made by hand: { names: { id: name }, members: { url: id } }.
    // A member with id 0 is a video kept on its own.
    function videoGroups() {
        var data = { names: {}, members: {} };
        db().readTransaction(function(tx) {
            var groups = tx.executeSql("SELECT id, name FROM video_groups").rows;
            for (var i = 0; i < groups.length; i++)
                data.names[groups.item(i).id] = groups.item(i).name;
            var members = tx.executeSql("SELECT url, group_id FROM video_group_members").rows;
            for (var k = 0; k < members.length; k++)
                data.members[members.item(k).url] = members.item(k).group_id;
        });
        return data;
    }

    function _assign(tx, urls, id) {
        for (var i = 0; i < urls.length; i++)
            tx.executeSql("INSERT OR REPLACE INTO video_group_members(url, group_id) VALUES(?, ?)", [urls[i], id]);
        // A group nobody is in any more is gone.
        tx.executeSql("DELETE FROM video_groups WHERE id NOT IN (SELECT group_id FROM video_group_members)");
    }

    function createVideoGroup(name, urls) {
        var id = 0;
        db().transaction(function(tx) {
            id = parseInt(tx.executeSql("INSERT INTO video_groups(name) VALUES(?)", [name]).insertId);
            _assign(tx, urls, id);
        });
        groupRevision++;
        return id;
    }

    // Into group `id`; 0 keeps each of them on its own.
    function setVideoGroup(urls, id) {
        db().transaction(function(tx) { _assign(tx, urls, id); });
        groupRevision++;
    }

    function renameVideoGroup(id, name) {
        db().transaction(function(tx) {
            tx.executeSql("UPDATE video_groups SET name = ? WHERE id = ?", [name, id]);
        });
        groupRevision++;
    }

    // Back to the groups that form by name.
    function regroupVideos(urls) {
        db().transaction(function(tx) {
            for (var i = 0; i < urls.length; i++)
                tx.executeSql("DELETE FROM video_group_members WHERE url = ?", [urls[i]]);
            tx.executeSql("DELETE FROM video_groups WHERE id NOT IN (SELECT group_id FROM video_group_members)");
        });
        groupRevision++;
    }

    // [{ position, title }] for a file, in playing order.
    function bookmarks(url) {
        var list = [];
        db().readTransaction(function(tx) {
            var rows = tx.executeSql("SELECT position, title FROM bookmarks WHERE url = ? ORDER BY position", [url]).rows;
            for (var i = 0; i < rows.length; i++)
                list.push({ position: rows.item(i).position, title: rows.item(i).title });
        });
        return list;
    }

    function addBookmark(url, position, title) {
        if (!url)
            return;
        db().transaction(function(tx) {
            tx.executeSql("INSERT OR REPLACE INTO bookmarks(url, position, title) VALUES(?, ?, ?)",
                          [url, Math.round(position), title]);
        });
        bookmarkRevision++;
    }

    // A value kept under a name, as text; "" if there is none.
    function kept(name) {
        var value = "";
        db().readTransaction(function(tx) {
            var rows = tx.executeSql("SELECT value FROM kept WHERE name = ?", [name]).rows;
            if (rows.length > 0)
                value = rows.item(0).value;
        });
        return value;
    }

    function keep(name, value) {
        db().transaction(function(tx) {
            tx.executeSql("INSERT OR REPLACE INTO kept(name, value) VALUES(?, ?)", [name, "" + value]);
        });
    }

    function removeBookmark(url, position) {
        db().transaction(function(tx) {
            tx.executeSql("DELETE FROM bookmarks WHERE url = ? AND position = ?", [url, position]);
        });
        bookmarkRevision++;
    }

    // ---- stream history ---------------------------------------------------------------

    // The streams opened before, the latest first: [{ url, title }].
    function streams() {
        var list = [];
        db().readTransaction(function(tx) {
            var rows = tx.executeSql("SELECT url, title FROM streams ORDER BY opened_at DESC, url").rows;
            for (var i = 0; i < rows.length; i++)
                list.push({ url: rows.item(i).url, title: rows.item(i).title });
        });
        return list;
    }

    // A stream was opened. One that is known keeps the name it was given.
    function noteStream(url, title) {
        if (!url || !title)
            return;
        db().transaction(function(tx) {
            tx.executeSql("INSERT OR IGNORE INTO streams(url, title) VALUES(?, ?)", [url, title]);
            tx.executeSql("UPDATE streams SET opened_at = ? WHERE url = ?", [Date.now(), url]);
        });
        streamRevision++;
    }

    function renameStream(url, title) {
        db().transaction(function(tx) {
            tx.executeSql("UPDATE streams SET title = ? WHERE url = ?", [title, url]);
        });
        streamRevision++;
    }

    function removeStream(url) {
        db().transaction(function(tx) {
            tx.executeSql("DELETE FROM streams WHERE url = ?", [url]);
        });
        streamRevision++;
    }

    // ---- playlists --------------------------------------------------------------------

    // What is kept of an item: enough to list it and to play it.
    function _playlistMedia(m) {
        return { url: m.url.toString(), filename: m.filename || "", title: m.title || "", artist: m.artist || "",
                 albumArtist: m.albumArtist || "", album: m.album || "", art: m.art ? m.art.toString() : "",
                 duration: m.duration || 0, hasPicture: !!m.hasPicture };
    }

    // Every playlist, by name: [{ id, name, count, videos, duration, art }].
    // `videos` is how many of its items have a picture; `art` is the first
    // cover or picture among them.
    function playlists() {
        var list = [];
        db().readTransaction(function(tx) {
            var byId = {};
            var rows = tx.executeSql("SELECT id, name FROM playlists ORDER BY name COLLATE NOCASE, id").rows;
            for (var i = 0; i < rows.length; i++) {
                var entry = { id: rows.item(i).id, name: rows.item(i).name, count: 0, videos: 0, duration: 0, art: "" };
                byId[entry.id] = entry;
                list.push(entry);
            }
            var items = tx.executeSql("SELECT playlist_id, media FROM playlist_items ORDER BY playlist_id, place").rows;
            for (var k = 0; k < items.length; k++) {
                var owner = byId[items.item(k).playlist_id];
                if (!owner)
                    continue;
                var media = JSON.parse(items.item(k).media);
                owner.count++;
                owner.duration += media.duration || 0;
                if (media.hasPicture)
                    owner.videos++;
                if (!owner.art && media.art)
                    owner.art = media.art;
            }
        });
        return list;
    }

    // A playlist's items, in its order.
    function playlistItems(id) {
        var list = [];
        db().readTransaction(function(tx) {
            var rows = tx.executeSql("SELECT media FROM playlist_items WHERE playlist_id = ? ORDER BY place", [id]).rows;
            for (var i = 0; i < rows.length; i++)
                list.push(JSON.parse(rows.item(i).media));
        });
        return list;
    }

    function _appendToPlaylist(tx, id, list) {
        var rows = tx.executeSql("SELECT url, place FROM playlist_items WHERE playlist_id = ?", [id]).rows;
        var there = {};
        var place = 0;
        for (var i = 0; i < rows.length; i++) {
            there[rows.item(i).url] = true;
            place = Math.max(place, rows.item(i).place + 1);
        }
        var added = 0;
        for (var k = 0; k < list.length; k++) {
            var media = _playlistMedia(list[k]);
            // Once only: what is in the playlist already is passed over.
            if (!media.url || there[media.url])
                continue;
            there[media.url] = true;
            tx.executeSql("INSERT INTO playlist_items(playlist_id, place, url, media) VALUES(?, ?, ?, ?)",
                          [id, place++, media.url, JSON.stringify(media)]);
            added++;
        }
        return added;
    }

    // A new playlist holding `list`, which may be empty. Returns its id.
    function createPlaylist(name, list) {
        var id = 0;
        db().transaction(function(tx) {
            id = parseInt(tx.executeSql("INSERT INTO playlists(name) VALUES(?)", [name]).insertId);
            _appendToPlaylist(tx, id, list || []);
        });
        playlistRevision++;
        return id;
    }

    // Adds `list` at the end; returns how many were not in it yet.
    function addToPlaylist(id, list) {
        var added = 0;
        db().transaction(function(tx) { added = _appendToPlaylist(tx, id, list); });
        playlistRevision++;
        return added;
    }

    // The playlist's items anew, in this order: for removing and moving.
    function setPlaylistItems(id, list) {
        db().transaction(function(tx) {
            tx.executeSql("DELETE FROM playlist_items WHERE playlist_id = ?", [id]);
            _appendToPlaylist(tx, id, list);
        });
        playlistRevision++;
    }

    function renamePlaylist(id, name) {
        db().transaction(function(tx) {
            tx.executeSql("UPDATE playlists SET name = ? WHERE id = ?", [name, id]);
        });
        playlistRevision++;
    }

    function deletePlaylist(id) {
        db().transaction(function(tx) {
            tx.executeSql("DELETE FROM playlist_items WHERE playlist_id = ?", [id]);
            tx.executeSql("DELETE FROM playlists WHERE id = ?", [id]);
        });
        playlistRevision++;
    }
}
