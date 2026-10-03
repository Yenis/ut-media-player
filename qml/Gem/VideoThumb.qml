import QtQuick 2.12
import Gem 1.0

/*
 * A video's thumbnail with what VLC draws on it: the resolution class and a
 * "seen" tick in the top left corner, and how far it was played along the
 * bottom edge. Layout after VLC's video_grid_card.xml and video_list_card.xml.
 */
Rectangle {
    id: thumb

    property url art
    property string resolution: ""      // "1080p", or empty for none
    property bool seen: false
    property real progress: 0           // 0 to 1; 0 draws no bar
    property int sourcePixels: 512

    radius: Theme.u(0.5)
    color: Theme.surfaceAlt
    clip: true

    Image {
        anchors.fill: parent
        source: thumb.art
        sourceSize: Qt.size(thumb.sourcePixels, thumb.sourcePixels)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Row {
        anchors { left: parent.left; top: parent.top; margins: Theme.u(0.5) }
        spacing: Theme.u(0.5)

        Rectangle {
            visible: thumb.resolution.length > 0
            width: resolutionLabel.implicitWidth + Theme.u(1)
            height: Theme.u(2)
            radius: Theme.u(0.4)
            color: Qt.rgba(0, 0, 0, 0.6)

            Text {
                id: resolutionLabel
                anchors.centerIn: parent
                text: thumb.resolution
                color: "white"
                font.pixelSize: Theme.fontXS
            }
        }
        Rectangle {
            visible: thumb.seen
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

    Rectangle {
        visible: thumb.progress > 0
        anchors { left: parent.left; bottom: parent.bottom }
        height: Math.max(2, Theme.u(0.4))
        width: parent.width * Math.min(1, thumb.progress)
        color: Theme.accent
    }
}
