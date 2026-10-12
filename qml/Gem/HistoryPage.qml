import QtQuick 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The playback history, behind the More tab: what was played, the latest
 * first, after VLC's HistoryFragment (docs/VLC-FEATURES.md, "History"). A
 * tap plays an item again; the history can be cleared, and switched off.
 *
 * The player notes an item when it has started (Playback.qml); this page
 * only lists what the store holds.
 */
Item {
    id: page

    property var store: null            // PlayerStore: the history
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property bool keeping: true         // the history is being kept
    property string playingUrl: ""      // what plays now, to mark it

    // Read only while the page is looked at: the history changes with
    // every item that starts.
    readonly property var entries: visible && store && store.historyRevision >= 0 ? store.history() : []
    property int menuIndex: -1

    signal closeRequested()
    // The switch was tapped.
    signal keepRequested(bool on)
    // Play `list` from its item `index`. options: { asAudio, background }.
    signal playRequested(var list, int index, var options)
    signal queueRequested(var list, bool next)
    signal playlistRequested(var list)

    // "Today, 14:02", "Yesterday, 9:30", or the date.
    function whenText(ms) {
        var then = new Date(ms);
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        var days = Math.floor((today.getTime() - new Date(then.getFullYear(), then.getMonth(), then.getDate()).getTime()) / 86400000);
        if (days <= 0)
            return "Today, " + Qt.formatTime(then, "h:mm");
        if (days === 1)
            return "Yesterday, " + Qt.formatTime(then, "h:mm");
        return Qt.formatDate(then, "d MMMM yyyy");
    }

    // One choice from the menu of the entry at `index`; a tap is "play".
    function itemAction(index, key) {
        if (index < 0 || index >= entries.length)
            return;
        var media = entries[index].media;
        if (key === "play")
            playRequested([media], 0, media.hasPicture ? {} : { asAudio: true, background: true });
        else if (key === "insertNext" || key === "append")
            queueRequested([media], key === "insertNext");
        else if (key === "addToPlaylist")
            playlistRequested([media]);
        else if (key === "remove")
            store.removeHistory(media.url);
    }

    function openMenu(index) {
        if (index < 0 || index >= entries.length)
            return;
        menuIndex = index;
        itemMenu.show();
    }

    function askClear() {
        if (entries.length > 0)
            clearSheet.show();
    }

    function closeSheets() {
        itemMenu.close();
        clearSheet.close();
    }

    function shownTitles() {
        return entries.map(function(entry) { return entry.media.title; });
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    // Nothing behind the page takes a touch.
    MouseArea { anchors.fill: parent }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "History"
        onBack: page.closeRequested()
        trailing: Row {
            // In words: a cross here would read as "close".
            TextButton {
                visible: page.entries.length > 0
                text: "Clear"
                tone: Theme.textDim
                onClicked: page.askClear()
            }
        }
    }

    SettingRow {
        id: keepRow
        anchors.top: header.bottom
        title: "Keep a playback history"
        detail: page.keeping ? "On. What you play is listed here, on the phone only."
                             : "Off. Nothing new is listed. What is here stays until you clear it."
        trailing: Toggle {
            checked: page.keeping
            onToggled: page.keepRequested(checked)
        }
    }

    Text {
        visible: page.entries.length === 0
        anchors { left: parent.left; right: parent.right; top: keepRow.bottom
                  leftMargin: Theme.u(2); rightMargin: Theme.u(2); topMargin: Theme.u(2.5) }
        wrapMode: Text.WordWrap
        text: page.keeping ? "Nothing has been played yet." : "The history is empty."
        color: Theme.textDim
        font.pixelSize: Theme.fontS
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: keepRow.bottom; bottom: parent.bottom }
        clip: true
        model: page.entries

        delegate: Item {
            id: row
            width: list.width
            height: Theme.u(8.25)

            readonly property var media: modelData.media
            readonly property bool playing: media.url === page.playingUrl

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
                    name: row.media.hasPicture ? "video" : "audio"
                    color: row.playing ? Theme.accent : Theme.textDim
                    visible: rowArt.status !== Image.Ready
                }
                Image {
                    id: rowArt
                    anchors.fill: parent
                    source: row.media.art || ""
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
                    text: row.media.title
                    color: row.playing ? Theme.accent : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: (row.media.artist ? row.media.artist + "  •  " : "") + page.whenText(modelData.playedAt)
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                onClicked: page.itemAction(index, "play")
            }

            IconButton {
                id: rowMore
                anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
                glyph: "more"
                onClicked: page.openMenu(index)
            }
        }
    }

    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuIndex >= 0 && page.menuIndex < page.entries.length ? page.entries[page.menuIndex].media.title : ""
        options: [
            { key: "play", label: "Play", glyph: "play" },
            { key: "insertNext", label: "Insert next", glyph: "next" },
            { key: "append", label: "Add to play queue", glyph: "add" },
            { key: "addToPlaylist", label: "Add to playlist", glyph: "playlist" },
            { key: "remove", label: "Remove from history", glyph: "clear" }
        ]
        onChosen: page.itemAction(page.menuIndex, key)
    }

    // Clearing asks first. Only the list goes: resume points, played marks
    // and the stream history are other things.
    OptionSheet {
        id: clearSheet
        parent: page.overlay
        anchors.fill: parent
        title: "Clear the playback history?"
        options: [
            { key: "clear", label: "Clear history", glyph: "clear" },
            { key: "keep", label: "Cancel", glyph: "back" }
        ]
        onChosen: if (key === "clear") page.store.clearHistory()
    }
}
