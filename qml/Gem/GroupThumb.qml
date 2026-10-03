import QtQuick 2.12
import Gem 1.0

/*
 * The picture for a folder or a group of videos: a folder for the one, up to
 * four of its members' thumbnails for the other, with a tick when all of
 * them were seen.
 */
Rectangle {
    id: thumb

    property bool folder: false
    property var arts: []               // thumbnail addresses of the members
    property bool seen: false
    property int sourcePixels: 256

    readonly property var pictures: folder ? [] : arts.slice(0, 4)

    radius: Theme.u(0.5)
    color: Theme.surfaceAlt
    clip: true

    Glyph {
        visible: thumb.folder
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.5
        name: "folder"
        color: Theme.textDim
    }

    Grid {
        anchors.fill: parent
        columns: 2
        spacing: 1

        Repeater {
            model: thumb.pictures

            Image {
                width: (thumb.width - 1) / 2
                height: thumb.pictures.length > 2 ? (thumb.height - 1) / 2 : thumb.height
                source: modelData
                sourceSize: Qt.size(thumb.sourcePixels, thumb.sourcePixels)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
    }

    Rectangle {
        visible: thumb.seen
        anchors { left: parent.left; top: parent.top; margins: Theme.u(0.5) }
        width: Theme.u(2)
        height: Theme.u(2)
        radius: Theme.u(0.4)
        color: Qt.rgba(0, 0, 0, 0.6)

        Glyph {
            anchors.centerIn: parent
            width: Theme.u(1.3)
            name: "check"
            color: "white"
        }
    }
}
