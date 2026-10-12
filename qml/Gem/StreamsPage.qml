import QtQuick 2.12
import Gem 1.0

/*
 * Streams, behind the More tab: the switch that allows them, a field for an
 * address, and the addresses opened before, after VLC's stream panel
 * (docs/VLC-FEATURES.md, "Streams").
 *
 * This is the app's one use of the network (docs/PLAN.md, D13), and it is
 * off until allowed (D14). The page opens nothing by itself: it asks, and
 * the shell passes the address to the player, or to the question first.
 */
Item {
    id: page

    property var store: null            // PlayerStore: the history
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property bool allowed: false        // streams are allowed
    property string playingUrl: ""      // what plays now, to mark it

    readonly property var streams: store && store.streamRevision >= 0 ? store.streams() : []
    property int menuIndex: -1

    signal closeRequested()
    // The switch was tapped.
    signal allowRequested(bool on)
    // Play this address. `title` is "" for one typed in.
    signal openRequested(string address, string title)
    signal playlistRequested(string address, string title)

    function dismissKeyboard() {
        Qt.inputMethod.commit();
        input.focus = false;
        Qt.inputMethod.hide();
    }

    // The address as typed, played.
    function submit() {
        Qt.inputMethod.commit();
        var address = input.text.trim();
        if (address.length === 0)
            return;
        dismissKeyboard();
        input.text = "";
        openRequested(address, "");
    }

    // One choice from the menu of the address at `index`. `name` is for "rename".
    function itemAction(index, key, name) {
        if (index < 0 || index >= streams.length)
            return;
        var stream = streams[index];
        if (key === "play") {
            openRequested(stream.url, stream.title);
        } else if (key === "rename") {
            if (name) {
                store.renameStream(stream.url, name);
            } else {
                menuIndex = index;
                renameDialog.show(stream.title);
            }
        } else if (key === "copy") {
            clipboard.text = stream.url;
            clipboard.selectAll();
            clipboard.copy();
        } else if (key === "addToPlaylist") {
            playlistRequested(stream.url, stream.title);
        } else if (key === "delete") {
            store.removeStream(stream.url);
        }
    }

    function openMenu(index) {
        if (index < 0 || index >= streams.length)
            return;
        dismissKeyboard();
        menuIndex = index;
        itemMenu.show();
    }

    function closeSheets() {
        itemMenu.close();
        renameDialog.close();
    }

    function shownTitles() {
        return streams.map(function(stream) { return stream.title + " <" + stream.url + ">"; });
    }

    onVisibleChanged: if (!visible) dismissKeyboard()

    // QML reaches the clipboard only through a text field.
    TextEdit {
        id: clipboard
        visible: false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    // Nothing behind the page takes a touch.
    MouseArea {
        anchors.fill: parent
        onClicked: page.dismissKeyboard()
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "Streams"
        onBack: page.closeRequested()
    }

    Column {
        id: top
        anchors { left: parent.left; right: parent.right; top: header.bottom }

        SettingRow {
            title: "Allow streams"
            detail: page.allowed
                    ? "On. An address you open is handed to the system's player, which connects to it. GemPlayer itself connects to nothing."
                    : "Off. GemPlayer is offline: nothing in the app reaches the network."
            trailing: Toggle {
                checked: page.allowed
                onToggled: page.allowRequested(checked)
            }
        }

        Item {
            width: parent.width
            height: Theme.u(8)

            Rectangle {
                anchors { left: parent.left; right: go.left; verticalCenter: parent.verticalCenter
                          leftMargin: Theme.u(2); rightMargin: Theme.u(0.5) }
                height: Theme.u(5)
                radius: Theme.u(0.9)
                color: Theme.surfaceAlt
                border.width: 1
                border.color: input.activeFocus ? Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.7) : Theme.line

                TextInput {
                    id: input
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                              leftMargin: Theme.u(1.4); rightMargin: Theme.u(1.4) }
                    // No focus: true - on a phone that would open the keyboard at once.
                    color: Theme.text
                    font.pixelSize: Theme.fontM
                    selectByMouse: true
                    selectionColor: Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.35)
                    clip: true
                    inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    onAccepted: page.submit()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Address of a stream"
                        color: Theme.textFaint
                        font.pixelSize: Theme.fontM
                        visible: input.text.length === 0 && !input.activeFocus
                    }
                }
            }

            IconButton {
                id: go
                anchors { right: parent.right; rightMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
                glyph: "play"
                color: input.text.trim().length > 0 ? Theme.accent : Theme.textFaint
                enabled: input.text.trim().length > 0
                onClicked: page.submit()
            }
        }

        SectionLabel { text: "History" }
    }

    Text {
        visible: page.streams.length === 0
        anchors { left: parent.left; right: parent.right; top: top.bottom
                  leftMargin: Theme.u(2); rightMargin: Theme.u(2); topMargin: Theme.u(1) }
        wrapMode: Text.WordWrap
        text: "The addresses you open are kept here, to open again."
        color: Theme.textDim
        font.pixelSize: Theme.fontS
        lineHeight: 1.3
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: top.bottom; bottom: parent.bottom }
        clip: true
        model: page.streams
        onMovementStarted: page.dismissKeyboard()

        delegate: Item {
            id: row
            width: list.width
            height: Theme.u(7.5)

            readonly property bool playing: modelData.url === page.playingUrl

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: rowMouse.pressed ? 0.06 : 0
            }

            Column {
                anchors { left: parent.left; leftMargin: Theme.u(2); right: rowMore.left
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.4)

                Text {
                    width: parent.width
                    text: modelData.title
                    color: row.playing ? Theme.accent : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: modelData.url
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideMiddle
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                onClicked: {
                    page.dismissKeyboard();
                    page.itemAction(index, "play", "");
                }
            }

            IconButton {
                id: rowMore
                anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
                glyph: "more"
                onClicked: page.openMenu(index)
            }
        }
    }

    // An address's menu, with VLC's entries.
    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuIndex >= 0 && page.menuIndex < page.streams.length ? page.streams[page.menuIndex].title : ""
        options: [
            { key: "play", label: "Play", glyph: "play" },
            { key: "rename", label: "Rename", glyph: "subtitles" },
            { key: "copy", label: "Copy address", glyph: "list" },
            { key: "addToPlaylist", label: "Add to playlist", glyph: "playlist" },
            { key: "delete", label: "Delete", glyph: "clear" }
        ]
        onChosen: page.itemAction(page.menuIndex, key, "")
    }

    NameDialog {
        id: renameDialog
        parent: page.overlay
        anchors.fill: parent
        title: "Rename stream"
        confirmLabel: "Rename"
        onAccepted: page.itemAction(page.menuIndex, "rename", name)
    }
}
