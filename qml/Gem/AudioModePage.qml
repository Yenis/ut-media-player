import QtQuick 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * What is shown while something plays as audio: title, timeline, play and
 * pause, and the way back to the picture. Phase 1's stand-in for the full
 * audio player of Phase 3.
 */
Item {
    id: page

    property var playback: null

    signal closeRequested()
    signal videoRequested()

    function back() { closeRequested(); }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "Playing as audio"
        onBack: page.closeRequested()
    }

    Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                  leftMargin: Theme.u(3); rightMargin: Theme.u(3) }
        spacing: Theme.u(3)

        Glyph {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.u(12)
            name: "audio"
            color: Theme.accent
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            text: page.playback ? page.playback.title : ""
            color: Theme.text
            font.pixelSize: Theme.fontL
        }

        Item {
            width: parent.width
            height: Theme.u(4)

            Text {
                id: timeLabel
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: Format.clock(seekBar.shownPosition)
                color: Theme.textDim
                font.pixelSize: Theme.fontS
            }
            Text {
                id: lengthLabel
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: page.playback ? Format.clock(page.playback.duration) : ""
                color: Theme.textDim
                font.pixelSize: Theme.fontS
            }
            SeekBar {
                id: seekBar
                anchors { left: timeLabel.right; right: lengthLabel.left; verticalCenter: parent.verticalCenter
                          leftMargin: Theme.u(1); rightMargin: Theme.u(1) }
                position: page.playback ? page.playback.position : 0
                duration: page.playback ? page.playback.duration : 0
                enabled: page.playback ? page.playback.seekable : false
                onSeekRequested: page.playback.seekTo(position)
            }
        }

        IconButton {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: Theme.u(10)
            implicitHeight: Theme.u(10)
            glyphSize: Theme.u(5)
            glyph: page.playback && page.playback.playing ? "pause" : "play"
            color: Theme.text
            onClicked: page.playback.toggle()
        }

        TextButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: page.playback ? page.playback.hasPicture : false
            text: "Play as video"
            onClicked: page.videoRequested()
        }
    }
}
