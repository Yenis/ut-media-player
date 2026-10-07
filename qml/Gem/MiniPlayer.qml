import QtQuick 2.12
import Gem 1.0

/*
 * What plays as audio, as a bar above the tabs: cover, title, play and pause,
 * and how far it is along the top edge. After VLC for Android's mini player
 * (docs/VLC-FEATURES.md, "Audio player"): a tap opens the full player, a
 * swipe to the left goes to the next item and one to the right to the
 * previous, and holding the play button stops.
 */
Rectangle {
    id: bar

    property var playback: null

    signal expandRequested()
    signal stopRequested()

    implicitHeight: Theme.u(7)
    color: Theme.surfaceAlt

    // How far a swipe has to travel to count.
    readonly property real swipeDistance: Theme.u(8)

    MouseArea {
        id: swipe
        anchors.fill: parent

        property real startX: 0
        property real offset: 0
        property bool moved: false

        onPressed: {
            startX = mouse.x;
            offset = 0;
            moved = false;
        }
        onPositionChanged: {
            offset = mouse.x - startX;
            if (Math.abs(offset) > Theme.u(1.5))
                moved = true;
        }
        onReleased: {
            var travelled = offset;
            offset = 0;
            if (!moved)
                bar.expandRequested();
            else if (travelled <= -bar.swipeDistance)
                bar.playback.next();
            else if (travelled >= bar.swipeDistance)
                bar.playback.previous();
        }
        onCanceled: offset = 0
    }

    // Follows the finger while it swipes.
    Item {
        id: content
        width: parent.width
        height: parent.height
        x: swipe.moved ? swipe.offset : 0
        opacity: 1 - Math.min(0.6, Math.abs(x) / (bar.swipeDistance * 2))
        Behavior on x { enabled: !swipe.pressed; NumberAnimation { duration: 120 } }

        Rectangle {
            id: cover
            anchors { left: parent.left; leftMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
            width: Theme.u(5)
            height: width
            radius: Theme.u(0.5)
            color: Theme.surface
            clip: true

            Glyph {
                anchors.centerIn: parent
                width: Theme.u(2.6)
                name: "audio"
                color: Theme.accent
                visible: art.status !== Image.Ready
            }
            Image {
                id: art
                anchors.fill: parent
                source: bar.playback ? bar.playback.art : ""
                sourceSize: Qt.size(128, 128)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            anchors { left: cover.right; leftMargin: Theme.u(1.2); right: parent.right; rightMargin: Theme.u(7)
                      verticalCenter: parent.verticalCenter }

            Text {
                width: parent.width
                elide: Text.ElideRight
                maximumLineCount: 1
                text: bar.playback ? bar.playback.title : ""
                color: Theme.text
                font.pixelSize: Theme.fontM
            }
            Text {
                width: parent.width
                visible: text !== ""
                elide: Text.ElideRight
                maximumLineCount: 1
                text: !bar.playback ? "" : bar.playback.error !== "" ? bar.playback.error : bar.playback.artist
                color: Theme.textDim
                font.pixelSize: Theme.fontS
            }
        }
    }

    IconButton {
        anchors { right: parent.right; rightMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
        glyph: bar.playback && bar.playback.playing ? "pause" : "play"
        color: Theme.text
        onClicked: bar.playback.toggle()
        onPressAndHold: bar.stopRequested()
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Math.max(2, Theme.u(0.3))
        color: Theme.line

        Rectangle {
            height: parent.height
            width: bar.playback && bar.playback.duration > 0
                   ? parent.width * Math.min(1, bar.playback.position / bar.playback.duration) : 0
            color: Theme.accent
        }
    }
}
