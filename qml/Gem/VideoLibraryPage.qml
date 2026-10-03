import QtQuick 2.12
import Qt.labs.settings 1.0
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The Video tab: the videos on the phone, as a grid of cards or as a list.
 * Grouping, sorting and the item menu of Phase 2 go here.
 */
Item {
    id: page

    property var library: null          // platform/MediaLibrary.qml, or null off the device
    property var store: null            // PlayerStore
    property var videos: []

    // VLC's default is the grid ("video_display_in_cards").
    property bool grid: true

    // What was played, by address, read once per change and not once per card.
    readonly property var played: store && store.revision >= 0 ? store.entries() : ({})

    signal mediaChosen(var media)

    function reload() {
        videos = library ? library.videos() : [];
    }

    function setGrid(on) {
        grid = on;
        settings.setValue("grid", on);
        settings.sync();
    }

    function progressOf(entry) {
        return entry && entry.duration > 0 ? entry.position / entry.duration : 0;
    }

    onLibraryChanged: reload()

    Settings {
        id: settings
        category: "videoLibrary"
    }

    Component.onCompleted: grid = settings.value("grid", true) !== "false" && settings.value("grid", true) !== false

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
        title: "Video"
        canGoBack: false
        trailing: IconButton {
            // Shows what a tap switches to, as VLC's menu entry does.
            glyph: page.grid ? "list" : "grid"
            onClicked: page.setGrid(!page.grid)
        }
    }

    Text {
        visible: page.videos.length === 0
        anchors.centerIn: parent
        width: parent.width - Theme.u(8)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: page.library ? "No videos found.\nPut some in the Videos folder and they will appear here."
                           : "The media library is not available."
        color: Theme.textDim
        font.pixelSize: Theme.fontM
        lineHeight: 1.3
    }

    GridView {
        id: cards
        visible: page.grid
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom
                  leftMargin: Theme.u(0.5); rightMargin: Theme.u(0.5) }
        topMargin: Theme.u(0.5)
        clip: true
        model: page.grid ? page.videos : []

        // As many 160 dp columns as fit, and never fewer than two.
        readonly property int columns: Math.max(2, Math.floor(width / Theme.u(20)))
        readonly property real pad: Theme.u(1)

        cellWidth: Math.floor(width / columns)
        cellHeight: Math.round(pad + (cellWidth - 2 * pad) * 10 / 16 + Theme.u(0.5)
                               + Theme.fontM * 1.4 + Theme.fontXS * 1.5 + Theme.u(1))

        delegate: Item {
            id: card
            width: cards.cellWidth
            height: cards.cellHeight

            readonly property var entry: page.played[modelData.url] || null

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: cardMouse.pressed ? 0.06 : 0
            }

            VideoThumb {
                id: cardThumb
                anchors { left: parent.left; right: parent.right; top: parent.top
                          leftMargin: cards.pad; rightMargin: cards.pad; topMargin: cards.pad }
                height: width * 10 / 16
                art: modelData.art
                resolution: Format.resolutionClass(modelData.width, modelData.height)
                seen: card.entry !== null && card.entry.seen > 0
                progress: page.progressOf(card.entry)
            }
            Text {
                id: cardTitle
                anchors { left: cardThumb.left; right: cardThumb.right; top: cardThumb.bottom; topMargin: Theme.u(0.5) }
                text: modelData.title
                color: Theme.text
                font.pixelSize: Theme.fontM
                elide: Text.ElideRight
            }
            Text {
                anchors { left: cardThumb.left; right: cardThumb.right; top: cardTitle.bottom }
                text: Format.clock(modelData.duration)
                color: Theme.textFaint
                font.pixelSize: Theme.fontXS
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                onClicked: page.mediaChosen(modelData)
            }
        }
    }

    ListView {
        id: list
        visible: !page.grid
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
        clip: true
        model: page.grid ? [] : page.videos

        delegate: Item {
            id: row
            width: list.width
            height: Theme.u(8.25)

            readonly property var entry: page.played[modelData.url] || null
            readonly property string resolution: Format.resolutionClass(modelData.width, modelData.height)

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: rowMouse.pressed ? 0.06 : 0
            }

            VideoThumb {
                id: rowThumb
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(10)
                height: Theme.u(6.25)
                sourcePixels: 256
                art: modelData.art
                seen: row.entry !== null && row.entry.seen > 0
                progress: page.progressOf(row.entry)
            }

            Column {
                anchors { left: rowThumb.right; leftMargin: Theme.u(1.5); right: parent.right; rightMargin: Theme.u(2)
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.5)

                Text {
                    width: parent.width
                    text: modelData.title
                    color: Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: Format.clock(modelData.duration) + (row.resolution ? "  •  " + row.resolution : "")
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                onClicked: page.mediaChosen(modelData)
            }
        }
    }
}
