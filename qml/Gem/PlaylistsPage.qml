import QtQuick 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The Playlists tab: the playlists, and inside one its items in their order,
 * after VLC's PlaylistFragment and its playlist page (docs/VLC-FEATURES.md,
 * "Playlists"). A playlist can hold music and videos alike. A tap on an item
 * plays the playlist from there; an item is moved from its menu, where VLC
 * drags, as in the play queue.
 *
 * Things get into a playlist from the other pages, through "Add to
 * playlist"; the picker for that belongs to the shell.
 */
Item {
    id: page

    property var store: null            // PlayerStore: the playlists
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property string playingUrl: ""      // what plays as audio now, to mark it

    property int openId: 0              // the playlist that is open; 0 for none

    readonly property var playlists: store && store.playlistRevision >= 0 ? store.playlists() : []
    readonly property var current: {
        for (var i = 0; openId > 0 && i < playlists.length; i++)
            if (playlists[i].id === openId)
                return playlists[i];
        return null;
    }
    readonly property var items: store && current && store.playlistRevision >= 0 ? store.playlistItems(openId) : []
    readonly property var shown: current ? items : playlists

    property var menuPlaylist: null     // the playlist a menu or dialog is about
    property int menuIndex: -1          // the item of the open playlist its menu is about

    // Play `list` from its item `index`. options: { asAudio, background }.
    signal playRequested(var list, int index, var options)
    // Add `list` to what plays: after the current item if `next`, otherwise
    // at the end.
    signal queueRequested(var list, bool next)

    // One step back; false from the list of playlists.
    function back() {
        if (openId === 0)
            return false;
        openId = 0;
        return true;
    }

    function countLabel(playlist) {
        if (playlist.count === 0)
            return "Empty";
        var unit = playlist.videos === 0 ? (playlist.count === 1 ? " track" : " tracks")
                 : playlist.videos === playlist.count ? (playlist.count === 1 ? " video" : " videos")
                 : " items";
        return playlist.count + unit + "  •  " + Format.clock(playlist.duration);
    }

    // A playlist of videos only plays with its pictures; anything else plays
    // as audio behind the lists, a video among it too, as VLC plays one.
    function play(list, index) {
        if (list.length === 0)
            return;
        var videosOnly = list.every(function(media) { return media.hasPicture; });
        playRequested(list, index, videosOnly ? {} : { asAudio: true, background: true });
    }

    // A tap on the row at `index`.
    function activate(index) {
        if (index < 0 || index >= shown.length)
            return;
        if (!current)
            openId = playlists[index].id;
        else
            play(items, index);
    }

    // A name that is taken makes no second playlist of that name.
    function create(name) {
        for (var i = 0; i < playlists.length; i++)
            if (playlists[i].name.toLowerCase() === name.toLowerCase())
                return;
        store.createPlaylist(name, []);
    }

    // One choice from a playlist's menu. `name` is for "rename".
    function playlistAction(playlist, key, name) {
        if (!playlist)
            return;
        var list = store.playlistItems(playlist.id);
        if (key === "play") {
            play(list, 0);
        } else if (key === "insertNext" || key === "append") {
            if (list.length > 0)
                queueRequested(list, key === "insertNext");
        } else if (key === "rename") {
            if (name) {
                store.renamePlaylist(playlist.id, name);
            } else {
                menuPlaylist = playlist;
                renameDialog.show(playlist.name);
            }
        } else if (key === "delete") {
            menuPlaylist = playlist;
            deleteSheet.show();
        } else if (key === "remove") {
            if (openId === playlist.id)
                openId = 0;
            store.deletePlaylist(playlist.id);
        }
    }

    // One choice from the menu of an item of the open playlist.
    function itemAction(index, key) {
        if (!current || index < 0 || index >= items.length)
            return;
        var list = items.slice();
        if (key === "play") {
            play(list, index);
        } else if (key === "insertNext" || key === "append") {
            queueRequested([list[index]], key === "insertNext");
        } else if (key === "up" || key === "down") {
            var to = index + (key === "up" ? -1 : 1);
            if (to < 0 || to >= list.length)
                return;
            list.splice(to, 0, list.splice(index, 1)[0]);
            store.setPlaylistItems(openId, list);
            menuIndex = to;
        } else if (key === "remove") {
            list.splice(index, 1);
            store.setPlaylistItems(openId, list);
        }
    }

    // The menu of the row at `index`: a playlist's, or an item's.
    function openMenu(index) {
        if (index < 0 || index >= shown.length)
            return;
        if (current) {
            menuIndex = index;
            itemMenu.show();
        } else {
            menuPlaylist = playlists[index];
            playlistMenu.show();
        }
    }

    function openNewDialog() {
        newDialog.show("");
    }

    function closeSheets() {
        playlistMenu.close();
        itemMenu.close();
        deleteSheet.close();
        newDialog.close();
        renameDialog.close();
    }

    function shownTitles() {
        return shown.map(function(row) { return current ? row.title : row.name + " [" + row.count + "]"; });
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: page.current ? page.current.name : "Playlists"
        canGoBack: page.current !== null
        onBack: page.back()
        trailing: Row {
            IconButton {
                visible: page.current === null
                glyph: "add"
                color: Theme.text
                onClicked: page.openNewDialog()
            }
            IconButton {
                visible: page.current !== null && page.items.length > 0
                glyph: "play"
                color: Theme.text
                onClicked: page.play(page.items, 0)
            }
            IconButton {
                visible: page.current !== null
                glyph: "more"
                onClicked: {
                    page.menuPlaylist = page.current;
                    playlistMenu.show();
                }
            }
        }
    }

    Text {
        visible: page.shown.length === 0
        anchors.centerIn: parent
        width: parent.width - Theme.u(8)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: page.current ? "This playlist is empty. “Add to playlist” in the menu of a track, a video or a folder puts it here."
                           : "No playlists yet. The plus at the top makes one, and so does “Add to playlist” in the menu of a track, a video or a folder."
        color: Theme.textDim
        font.pixelSize: Theme.fontM
        lineHeight: 1.3
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
        clip: true
        model: page.shown

        delegate: Item {
            id: row
            width: list.width
            height: Theme.u(8.25)

            readonly property bool isItem: page.current !== null
            readonly property bool playing: isItem && modelData.url === page.playingUrl

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: rowMouse.pressed ? 0.06 : 0
            }

            Rectangle {
                id: rowThumb
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(6.25)
                height: width
                radius: Theme.u(0.5)
                color: Theme.surfaceAlt
                clip: true

                Glyph {
                    anchors.centerIn: parent
                    width: Theme.u(2.8)
                    name: !row.isItem ? "playlist" : modelData.hasPicture ? "video" : "audio"
                    color: row.playing ? Theme.accent : Theme.textDim
                    visible: rowArt.status !== Image.Ready
                }
                Image {
                    id: rowArt
                    anchors.fill: parent
                    source: modelData.art || ""
                    sourceSize: Qt.size(256, 256)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Column {
                anchors { left: rowThumb.right; leftMargin: Theme.u(1.5); right: rowMore.left
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.5)

                Text {
                    width: parent.width
                    text: row.isItem ? modelData.title : modelData.name
                    color: row.playing ? Theme.accent : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: !row.isItem ? page.countLabel(modelData)
                          : (index + 1) + "  •  " + (modelData.artist ? modelData.artist + "  •  " : "")
                            + (modelData.hasPicture ? "Video  •  " : "") + Format.clock(modelData.duration)
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                onClicked: page.activate(index)
            }

            IconButton {
                id: rowMore
                anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
                glyph: "more"
                onClicked: page.openMenu(index)
            }
        }
    }

    // A playlist's menu, from its row or from the header of the open one.
    OptionSheet {
        id: playlistMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuPlaylist ? page.menuPlaylist.name : ""
        options: {
            var rows = [];
            if (page.menuPlaylist && page.menuPlaylist.count > 0) {
                rows.push({ key: "play", label: "Play", glyph: "play" });
                rows.push({ key: "insertNext", label: "Insert next", glyph: "next" });
                rows.push({ key: "append", label: "Add to play queue", glyph: "add" });
            }
            rows.push({ key: "rename", label: "Rename", glyph: "subtitles" });
            rows.push({ key: "delete", label: "Delete", glyph: "clear" });
            return rows;
        }
        onChosen: page.playlistAction(page.menuPlaylist, key, "")
    }

    // An item's menu. The moves stay open, to go on moving.
    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuIndex >= 0 && page.menuIndex < page.items.length ? page.items[page.menuIndex].title : ""
        options: {
            var rows = [
                { key: "play", label: "Play", glyph: "play" },
                { key: "insertNext", label: "Insert next", glyph: "next" },
                { key: "append", label: "Add to play queue", glyph: "add" }
            ];
            if (page.menuIndex > 0)
                rows.push({ key: "up", label: "Move up", glyph: "up", stay: true });
            if (page.menuIndex < page.items.length - 1)
                rows.push({ key: "down", label: "Move down", glyph: "down", stay: true });
            rows.push({ key: "remove", label: "Remove from playlist", glyph: "clear" });
            return rows;
        }
        onChosen: page.itemAction(page.menuIndex, key)
    }

    // Deleting asks first: a playlist is work, and there is no way back.
    // Only the list goes; its music and videos stay on the phone.
    OptionSheet {
        id: deleteSheet
        parent: page.overlay
        anchors.fill: parent
        title: page.menuPlaylist ? "Delete “" + page.menuPlaylist.name + "”?" : ""
        options: [
            { key: "remove", label: "Delete playlist", glyph: "clear" },
            { key: "keep", label: "Cancel", glyph: "back" }
        ]
        onChosen: if (key === "remove") page.playlistAction(page.menuPlaylist, "remove", "")
    }

    NameDialog {
        id: newDialog
        parent: page.overlay
        anchors.fill: parent
        title: "New playlist"
        confirmLabel: "Create"
        onAccepted: page.create(name)
    }

    NameDialog {
        id: renameDialog
        parent: page.overlay
        anchors.fill: parent
        title: "Rename playlist"
        confirmLabel: "Rename"
        onAccepted: page.playlistAction(page.menuPlaylist, "rename", name)
    }
}
