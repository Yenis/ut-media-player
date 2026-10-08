import QtQuick 2.12
import QtGraphicalEffects 1.0
import Gem 1.0

/*
 * A cover, blurred and darkened, to lie behind the audio player as VLC's
 * does. Shows nothing until the picture is there. Loaded through a Loader:
 * without the effects module the player keeps its plain background.
 */
Item {
    id: backdrop

    property string art: ""

    Image {
        id: picture
        anchors.fill: parent
        visible: false
        source: backdrop.art
        // Small on purpose: it is blurred anyway, and blurring is paid per pixel.
        sourceSize: Qt.size(128, 128)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    FastBlur {
        anchors.fill: parent
        visible: picture.status === Image.Ready
        source: picture
        radius: 64
    }

    Rectangle {
        anchors.fill: parent
        visible: picture.status === Image.Ready
        color: Theme.bg
        opacity: 0.72
    }
}
