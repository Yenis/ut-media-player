import QtQuick 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The Video tab: the videos on the phone. Still Phase 1's plain list; the
 * grid, grouping and sorting of Phase 2 go here.
 */
Item {
    id: page

    property var library: null          // platform/MediaLibrary.qml, or null off the device
    property var store: null            // PlayerStore
    property var videos: []

    signal mediaChosen(var media)

    function reload() {
        videos = library ? library.videos() : [];
    }

    onLibraryChanged: reload()

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

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
        clip: true
        model: page.videos

        delegate: Item {
            id: row
            width: list.width
            height: Theme.u(11)

            // Re-read when anything was played.
            readonly property var progress: page.store && page.store.revision >= 0 ? page.store.entry(modelData.url) : null

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: rowMouse.pressed ? 0.06 : 0
            }

            Rectangle {
                id: thumb
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(15)
                height: Theme.u(8.5)
                radius: Theme.u(0.5)
                color: Theme.surfaceAlt
                clip: true

                Image {
                    anchors.fill: parent
                    source: modelData.art
                    sourceSize: Qt.size(320, 320)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    visible: row.progress !== null && row.progress.position > 0 && row.progress.duration > 0
                    anchors { left: parent.left; bottom: parent.bottom }
                    height: Math.max(2, Theme.u(0.35))
                    width: row.progress && row.progress.duration > 0
                           ? parent.width * row.progress.position / row.progress.duration : 0
                    color: Theme.accent
                }
            }

            Column {
                anchors { left: thumb.right; leftMargin: Theme.u(1.5); right: parent.right; rightMargin: Theme.u(2)
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.6)

                Text {
                    width: parent.width
                    text: modelData.title
                    color: row.progress && row.progress.seen ? Theme.textDim : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }
                Text {
                    width: parent.width
                    text: Format.clock(modelData.duration)
                          + (modelData.width > 0 ? "  ·  " + modelData.width + "×" + modelData.height : "")
                          + (row.progress && row.progress.seen ? "  ·  seen" : "")
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
