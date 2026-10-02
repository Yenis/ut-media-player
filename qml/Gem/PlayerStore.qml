import QtQuick 2.12
import QtQuick.LocalStorage 2.0
import "../js/DbHandle.js" as DbHandle

/*
 * What the player remembers about each file: where it was left, whether it
 * was seen, and its bookmarks. Kept in the app's SQLite database
 * (~/.local/share/gemplayer.yenis/), opened on first use so nothing touches
 * storage before Main.qml has set the app identity.
 */
QtObject {
    id: store

    // Count changes, so views showing progress or bookmarks can refresh.
    property int revision: 0
    property int bookmarkRevision: 0

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

    // Played to the end: back to the start, and marked as seen.
    function finish(url, duration) {
        save(url, duration, duration);
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

    function removeBookmark(url, position) {
        db().transaction(function(tx) {
            tx.executeSql("DELETE FROM bookmarks WHERE url = ? AND position = ?", [url, position]);
        });
        bookmarkRevision++;
    }
}
