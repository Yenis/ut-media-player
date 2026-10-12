import QtQuick 2.12
import Gem 1.0

/*
 * "Add to playlist", wherever it is asked for: a sheet with "New playlist"
 * and the playlists there are, and the dialog that names a new one. After
 * VLC's SavePlaylistDialog (docs/VLC-FEATURES.md, "Playlists"), which is one
 * dialog for adding to a playlist and for saving the queue as one.
 *
 * One of these serves the whole app; the shell owns it.
 */
Item {
    id: picker

    property var store: null            // PlayerStore
    property var items: []              // what is being added
    readonly property bool open: sheet.open || nameDialog.open

    // It is done: what to tell the user.
    signal done(string message)

    readonly property var playlists: store && store.playlistRevision >= 0 && sheet.open ? store.playlists() : []

    function ask(list) {
        if (!store || !list || list.length === 0)
            return;
        items = list;
        sheet.show();
    }

    function close() {
        sheet.close();
        nameDialog.close();
    }

    function _what(count) {
        return count === 1 && items.length === 1 ? "“" + items[0].title + "”"
                                                 : count + (count === 1 ? " item" : " items");
    }

    function _report(added, name) {
        var passed = items.length - added;
        if (added === 0)
            done("Already in “" + name + "”");
        else
            done(_what(added) + " added to “" + name + "”"
                 + (passed > 0 ? ", " + passed + " already there" : ""));
        items = [];
    }

    function addTo(playlist) {
        sheet.close();
        if (playlist)
            _report(store.addToPlaylist(playlist.id, items), playlist.name);
    }

    // A name that is taken means that playlist, as in VLC.
    function addToNew(name) {
        sheet.close();
        var all = store.playlists();
        for (var i = 0; i < all.length; i++) {
            if (all[i].name.toLowerCase() === name.toLowerCase()) {
                addTo(all[i]);
                return;
            }
        }
        // Counted by the store: what is in `items` twice goes in once.
        var added = store.addToPlaylist(store.createPlaylist(name, []), items);
        done(_what(added) + " added to the new playlist “" + name + "”");
        items = [];
    }

    OptionSheet {
        id: sheet
        anchors.fill: parent
        title: "Add to playlist"
        options: {
            var rows = [{ key: "new", label: "New playlist", glyph: "add" }];
            for (var i = 0; i < picker.playlists.length; i++)
                rows.push({ key: "" + i, label: picker.playlists[i].name, glyph: "playlist",
                            value: "" + picker.playlists[i].count });
            return rows;
        }
        onChosen: {
            if (key === "new")
                nameDialog.show("");
            else
                picker.addTo(picker.playlists[parseInt(key)]);
        }
    }

    NameDialog {
        id: nameDialog
        anchors.fill: parent
        title: "New playlist"
        confirmLabel: "Create"
        onAccepted: picker.addToNew(name)
    }
}
