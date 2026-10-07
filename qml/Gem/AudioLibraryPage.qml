import QtQuick 2.12
import Qt.labs.settings 1.0
import Gem 1.0
import "../js/Format.js" as Format
import "../js/AudioLibrary.js" as AudioLibrary

/*
 * The Audio tab: the music on the phone under VLC's four headings, artists,
 * albums, tracks and genres (docs/VLC-FEATURES.md, "Audio library"), and
 * under "Files", the plain list of audio files. An
 * artist, album or genre opens in place and lists its tracks; a tap on a
 * track plays the list it is in from that track on, behind the page, with
 * the mini-player showing it.
 *
 * What is listed and in which order is worked out in js/AudioLibrary.js.
 */
Item {
    id: page

    property var library: null          // platform/MediaLibrary.qml, or null off the device
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property string playingUrl: ""      // the track that plays as audio now, to mark it

    property var tracks: []
    property string tab: "artists"      // one of AudioLibrary.TABS
    property string openKey: ""         // the artist, album or genre that is open; "" for none

    readonly property var topLevel: AudioLibrary.topLevel(tracks, tab)
    readonly property var openItem: openKey ? AudioLibrary.findGroup(topLevel, openKey) : null
    // Rows: a group { kind, key, title, subtitle, tracks, art }, a track, or
    // a heading { section }.
    readonly property var shown: openKey ? (openItem ? AudioLibrary.rowsOf(openItem) : []) : topLevel

    property var menuItem: null

    // Play `list` from its item `index`. options: { asAudio, background }.
    signal playRequested(var list, int index, var options)
    // Add `list` to what plays: after the current item if `next`, otherwise
    // at the end.
    signal queueRequested(var list, bool next)

    function reload() {
        tracks = library ? library.tracks() : [];
        if (openKey && !openItem)
            openKey = "";
    }

    function setTab(key) {
        tab = AudioLibrary.TABS[AudioLibrary.tabIndex(key)].key;
        openKey = "";
        settings.setValue("tab", tab);
        settings.sync();
    }

    // Leaves the open artist, album or genre; false if there was none.
    function back() {
        if (!openKey)
            return false;
        openKey = "";
        return true;
    }

    // The tracks a row stands for, and those around a track.
    function tracksOf(item) {
        return item.tracks || [item];
    }

    function surrounding() {
        return openItem ? openItem.tracks : tab === "tracks" || tab === "files" ? topLevel : [];
    }

    function play(list, index) {
        playRequested(list, index, { asAudio: true, background: true });
    }

    // A tap on a row.
    function activate(item) {
        if (!item || item.section)
            return;
        if (item.tracks) {
            openKey = item.key;
            return;
        }
        var list = surrounding();
        for (var i = 0; i < list.length; i++) {
            if (list[i].url === item.url) {
                play(list, i);
                return;
            }
        }
        play([item], 0);
    }

    // One choice from a row's menu.
    function itemAction(item, key) {
        if (!item || item.section)
            return;
        if (key === "play")
            play(tracksOf(item), 0);
        else if (key === "append" || key === "insertNext")
            queueRequested(tracksOf(item), key === "insertNext");
    }

    function openItemMenu(index) {
        if (index >= 0 && index < shown.length && !shown[index].section) {
            menuItem = shown[index];
            itemMenu.show();
        }
    }

    function closeSheets() {
        itemMenu.close();
    }

    function shownTitles() {
        return shown.map(function(item) {
            return item.section ? "# " + item.section
                 : item.tracks ? item.title + " [" + item.tracks.length + "]"
                 : tab === "files" ? AudioLibrary.fileName(item) : item.title;
        });
    }

    onLibraryChanged: reload()

    Settings {
        id: settings
        category: "audioLibrary"
    }

    Component.onCompleted: tab = AudioLibrary.TABS[AudioLibrary.tabIndex(settings.value("tab", "artists"))].key

    Connections {
        target: page.library
        ignoreUnknownSignals: true
        onChanged: page.reload()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: page.openItem ? page.openItem.title : "Audio"
        canGoBack: page.openKey.length > 0
        onBack: page.back()
        trailing: Row {
            IconButton {
                visible: page.openItem !== null
                glyph: "play"
                color: Theme.text
                onClicked: page.itemAction(page.openItem, "play")
            }
        }
    }

    Item {
        id: tabRow
        anchors { left: parent.left; right: parent.right; top: header.bottom }
        height: page.openKey ? 0 : Theme.u(7)
        visible: !page.openKey

        SegmentedChoice {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                      leftMargin: Theme.u(2); rightMargin: Theme.u(2) }
            options: AudioLibrary.TABS.map(function(t) { return t.label; })
            currentIndex: AudioLibrary.tabIndex(page.tab)
            onChosen: page.setTab(AudioLibrary.TABS[index].key)
        }
    }

    Text {
        visible: page.shown.length === 0
        anchors.centerIn: parent
        width: parent.width - Theme.u(8)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: !page.library ? "The media library is not available."
              : "No music found.\nPut some in the Music folder and it will appear here."
        color: Theme.textDim
        font.pixelSize: Theme.fontM
        lineHeight: 1.3
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: tabRow.bottom; bottom: parent.bottom }
        clip: true
        model: page.shown

        delegate: Item {
            id: row
            width: list.width
            height: isSection ? Theme.u(5.5) : Theme.u(8.25)

            readonly property bool isSection: !!modelData.section
            readonly property bool isGroup: !!modelData.tracks
            readonly property bool asFile: page.tab === "files" && !isSection && !isGroup
            readonly property bool playing: !isSection && !isGroup && modelData.url === page.playingUrl

            SectionLabel {
                visible: row.isSection
                text: row.isSection ? modelData.section : ""
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: !row.isSection && rowMouse.pressed ? 0.06 : 0
            }

            Rectangle {
                id: rowThumb
                visible: !row.isSection
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(6.25)
                height: width
                // Round for an artist, as VLC draws them.
                radius: row.isGroup && modelData.kind === "artist" ? width / 2 : Theme.u(0.5)
                color: Theme.surfaceAlt
                clip: true

                Glyph {
                    anchors.centerIn: parent
                    width: Theme.u(2.8)
                    name: "audio"
                    color: row.playing ? Theme.accent : Theme.textDim
                    visible: rowArt.status !== Image.Ready
                }
                Image {
                    id: rowArt
                    anchors.fill: parent
                    // An artist has no picture of their own; a cover would only stand for one album.
                    source: row.isSection || (row.isGroup && modelData.kind !== "album") ? "" : (modelData.art || "")
                    sourceSize: Qt.size(256, 256)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Column {
                visible: !row.isSection
                anchors { left: rowThumb.right; leftMargin: Theme.u(1.5); right: rowMore.left
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.5)

                Text {
                    width: parent.width
                    text: row.isSection ? "" : row.asFile ? AudioLibrary.fileName(modelData) : modelData.title
                    color: row.playing ? Theme.accent : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: row.isSection ? "" : row.isGroup ? modelData.subtitle
                          : row.asFile ? AudioLibrary.folderName(modelData) + "  \u2022  " + Format.clock(modelData.duration)
                          : AudioLibrary.artistOf(modelData) + "  •  " + Format.clock(modelData.duration)
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                enabled: !row.isSection
                onClicked: page.activate(modelData)
            }

            IconButton {
                id: rowMore
                visible: !row.isSection
                anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
                glyph: "more"
                onClicked: {
                    page.menuItem = modelData;
                    itemMenu.show();
                }
            }
        }
    }

    // A row's menu, in VLC's order.
    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuItem ? page.menuItem.title : ""
        options: [
            { key: "play", label: page.menuItem && page.menuItem.tracks ? "Play all" : "Play", glyph: "play" },
            { key: "insertNext", label: "Insert next", glyph: "next" },
            { key: "append", label: "Add to play queue", glyph: "add" }
        ]
        onChosen: page.itemAction(page.menuItem, key)
    }
}
