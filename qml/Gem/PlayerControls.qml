import QtQuick 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The controls over a playing video: title bar on top, timeline and buttons
 * at the bottom. Only the buttons take touches; everything else falls through
 * to the gesture layer underneath.
 *
 * The layout follows VLC for Android's player_hud.xml: time, seek bar and
 * length in one row; under it the orientation button on the left, play in the
 * middle, resize and "more" on the right. With more than one item in the
 * queue, previous and next sit beside play and the queue button joins the
 * title bar.
 */
Item {
    id: hud

    property var playback: null
    property bool orientationLocked: false
    property bool subtitlesAvailable: false
    property bool subtitlesOn: true
    property var markers: []            // for the timeline
    property var chips: []              // [{ key, label }]: what is switched on, VLC's "quick actions"

    readonly property bool dragging: seekBar.dragging
    readonly property bool hasQueue: playback ? playback.queue.length > 1 : false

    signal back()
    signal menuRequested()
    signal queueRequested()
    signal aspectTapped()
    signal aspectHeld()
    signal orientationTapped()
    signal subtitlesTapped()
    signal chipTapped(string key)
    signal interacted()

    // ---- top ----
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.u(10)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.75) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    IconButton {
        id: backButton
        anchors { left: parent.left; leftMargin: Theme.u(0.5); top: parent.top; topMargin: Theme.u(0.8) }
        glyph: "back"
        color: Theme.text
        onClicked: hud.back()
    }

    Text {
        anchors { left: backButton.right; leftMargin: Theme.u(0.5)
                  right: queueButton.visible ? queueButton.left : parent.right
                  rightMargin: queueButton.visible ? Theme.u(0.5) : Theme.u(2)
                  verticalCenter: backButton.verticalCenter }
        text: hud.playback ? hud.playback.title : ""
        color: Theme.text
        font.pixelSize: Theme.fontM
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    IconButton {
        id: queueButton
        visible: hud.hasQueue
        anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: backButton.verticalCenter }
        glyph: "playlist"
        color: Theme.text
        onClicked: { hud.queueRequested(); hud.interacted(); }
    }

    Row {
        anchors { left: parent.left; leftMargin: Theme.u(2); top: backButton.bottom; topMargin: Theme.u(0.5) }
        spacing: Theme.u(1)

        Repeater {
            model: hud.chips
            delegate: Rectangle {
                width: chipLabel.implicitWidth + Theme.u(2.4)
                height: Theme.u(3.6)
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.55)
                border.width: 1
                border.color: Theme.accent

                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    color: Theme.accent
                    font.pixelSize: Theme.fontXS
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Theme.u(0.8)
                    onClicked: { hud.chipTapped(modelData.key); hud.interacted(); }
                }
            }
        }
    }

    // ---- bottom ----
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Theme.u(16)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
        }
    }

    Item {
        id: buttons
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                  leftMargin: Theme.u(1); rightMargin: Theme.u(1); bottomMargin: Theme.u(1) }
        height: Theme.u(7)

        IconButton {
            id: rotateButton
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            glyph: "rotate"
            color: hud.orientationLocked ? Theme.accent : Theme.text
            onClicked: { hud.orientationTapped(); hud.interacted(); }
        }

        IconButton {
            visible: hud.subtitlesAvailable
            anchors { left: rotateButton.right; verticalCenter: parent.verticalCenter }
            glyph: "subtitles"
            color: hud.subtitlesOn ? Theme.text : Theme.textDim
            onClicked: { hud.subtitlesTapped(); hud.interacted(); }
        }

        IconButton {
            visible: hud.hasQueue
            anchors { right: playButton.left; verticalCenter: parent.verticalCenter }
            glyph: "previous"
            color: Theme.text
            onClicked: { hud.playback.previous(); hud.interacted(); }
        }

        IconButton {
            visible: hud.hasQueue
            anchors { left: playButton.right; verticalCenter: parent.verticalCenter }
            glyph: "next"
            color: Theme.text
            enabled: hud.playback ? hud.playback.hasNext : false
            onClicked: { hud.playback.next(); hud.interacted(); }
        }

        IconButton {
            id: playButton
            anchors.centerIn: parent
            implicitWidth: Theme.u(8)
            implicitHeight: Theme.u(7)
            glyphSize: Theme.u(3.6)
            glyph: hud.playback && hud.playback.playing ? "pause" : "play"
            color: Theme.text
            onClicked: { hud.playback.toggle(); hud.interacted(); }
        }

        IconButton {
            id: moreButton
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            glyph: "more"
            color: Theme.text
            onClicked: { hud.menuRequested(); hud.interacted(); }
        }

        IconButton {
            anchors { right: moreButton.left; verticalCenter: parent.verticalCenter }
            glyph: "aspect"
            color: Theme.text
            onClicked: { hud.aspectTapped(); hud.interacted(); }
            onPressAndHold: { hud.aspectHeld(); hud.interacted(); }
        }
    }

    Item {
        anchors { left: parent.left; right: parent.right; bottom: buttons.top
                  leftMargin: Theme.u(2); rightMargin: Theme.u(2) }
        height: Theme.u(4)

        Text {
            id: timeLabel
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: Format.clock(seekBar.shownPosition)
            color: Theme.text
            font.pixelSize: Theme.fontS
        }

        Text {
            id: lengthLabel
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: hud.playback ? Format.clock(hud.playback.duration) : ""
            color: Theme.text
            font.pixelSize: Theme.fontS
        }

        SeekBar {
            id: seekBar
            anchors { left: timeLabel.right; right: lengthLabel.left; verticalCenter: parent.verticalCenter
                      leftMargin: Theme.u(1); rightMargin: Theme.u(1) }
            position: hud.playback ? hud.playback.position : 0
            duration: hud.playback ? hud.playback.duration : 0
            enabled: hud.playback ? hud.playback.seekable : false
            markers: hud.markers
            onDraggingChanged: hud.interacted()
            onSeekRequested: { hud.playback.seekTo(position); hud.interacted(); }
        }
    }
}
