import QtQuick 2.12
import Gem 1.0
import "../js/Format.js" as Format
import "../js/Gestures.js" as Gestures

/*
 * The full audio player: cover, title, timeline and buttons, for music and
 * for a video played as audio. Layout after VLC for Android's
 * audio_player.xml (docs/VLC-FEATURES.md, "Audio player").
 *
 * The page does not own playback; it shows and steers the app's one Playback
 * object. Going back leaves it playing, with the mini-player in the page's
 * place; the mini-player has the button that stops it.
 *
 * Our own addition, which VLC does not have for audio: the video player's
 * seek gestures work on the cover. A double tap on a side seeks 10 s, a
 * horizontal swipe seeks further. Previous and next are buttons here, and a
 * sideways swipe on the mini-player.
 */
Item {
    id: page

    property var playback: null

    signal collapseRequested()
    signal stopRequested()
    signal videoRequested()

    readonly property bool hasQueue: playback ? playback.queue.length > 1 : false

    // Double taps on the same side add up while they follow each other closely.
    property int tapSeekTotal: 0
    property string tapSeekSide: ""

    function back() {
        if (queueSheet.open)
            queueSheet.close();
        else
            collapseRequested();
    }

    // By name, for the development remote.
    function openSheet(name) {
        if (name === "queue")
            queueSheet.show();
    }

    function showInfo(text, ms) {
        info.text = text;
        info.visible = true;
        infoHide.interval = ms;
        infoHide.restart();
    }

    function tapSeek(side) {
        if (!playback.seekable) {
            showInfo("Unseekable stream", 1000);
            return;
        }
        var step = side === "forward" ? 10000 : -10000;
        if (tapSeekSide !== side)
            tapSeekTotal = 0;
        tapSeekSide = side;
        tapSeekTotal += step;
        playback.seekBy(step);
        tapSeekReset.restart();
    }

    // The keys of the video player that mean something here. Returns whether
    // the key was used.
    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_MediaTogglePlayPause:
        case Qt.Key_MediaPlay:
        case Qt.Key_MediaPause:
            playback.toggle(); break;
        case Qt.Key_Right: tapSeek("forward"); break;
        case Qt.Key_Left: tapSeek("back"); break;
        case Qt.Key_S:
        case Qt.Key_MediaStop:
            stopRequested(); break;
        case Qt.Key_N:
        case Qt.Key_MediaNext:
            playback.next(); break;
        case Qt.Key_P:
        case Qt.Key_MediaPrevious:
            playback.previous(); break;
        default:
            return false;
        }
        return true;
    }

    Timer {
        id: infoHide
        onTriggered: info.visible = false
    }

    Timer {
        id: tapSeekReset
        interval: 750
        onTriggered: { page.tapSeekTotal = 0; page.tapSeekSide = ""; }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "Now playing"
        onBack: page.back()

        trailing: Row {
            IconButton {
                visible: page.playback ? page.playback.hasPicture : false
                glyph: "video"
                color: Theme.text
                onClicked: page.videoRequested()
            }
            IconButton {
                visible: page.hasQueue
                glyph: "playlist"
                color: Theme.text
                onClicked: queueSheet.show()
            }
        }
    }

    // The cover, and on it the seek gestures.
    Item {
        id: coverArea
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: details.top }

        Rectangle {
            id: cover
            anchors.centerIn: parent
            width: Math.max(0, Math.min(parent.width - Theme.u(8), parent.height - Theme.u(4)))
            height: width
            visible: width >= Theme.u(8)
            radius: Theme.u(1)
            color: Theme.surfaceAlt
            clip: true

            Glyph {
                anchors.centerIn: parent
                width: parent.width * 0.4
                name: "audio"
                color: Theme.accent
                visible: art.status !== Image.Ready
            }
            Image {
                id: art
                anchors.fill: parent
                source: page.playback ? page.playback.art : ""
                sourceSize: Qt.size(512, 512)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        GestureLayer {
            anchors.fill: parent
            seekable: page.playback ? page.playback.seekable : false
            volumeEnabled: false
            brightnessEnabled: false
            pinchEnabled: false

            onDoubleTapped: {
                if (zone === "centre")
                    page.playback.toggle();
                else
                    page.tapSeek(zone);
            }

            onSeekPreview: {
                var r = Gestures.seekJump(cm, verticalInches);
                var jump = Gestures.clampJump(r.jump, page.playback.position, page.playback.duration);
                page.showInfo(Format.signedClock(jump) + " (" + Format.clock(page.playback.position + jump) + ")"
                              + (r.divisor > 1 ? " x" + (1 / r.divisor).toPrecision(1) : ""), 600);
            }

            onSeekCommit: {
                var r = Gestures.seekJump(cm, verticalInches);
                var jump = Gestures.clampJump(r.jump, page.playback.position, page.playback.duration);
                page.playback.seekTo(page.playback.position + jump);
            }
        }

        // Double-tap seek: how far, on the side that was tapped.
        Text {
            visible: page.tapSeekTotal !== 0
            anchors.verticalCenter: parent.verticalCenter
            x: page.tapSeekSide === "forward" ? parent.width * 0.875 - width / 2 : parent.width * 0.125 - width / 2
            text: (page.tapSeekTotal > 0 ? "+" : "−") + Math.abs(page.tapSeekTotal / 1000) + " s"
            color: Theme.text
            style: Text.Outline
            styleColor: "black"
            font.pixelSize: Theme.fontL
            font.bold: true
        }

        // Swipe seek: how far, and where to.
        Rectangle {
            id: info
            property alias text: infoLabel.text
            visible: false
            anchors.centerIn: parent
            width: infoLabel.implicitWidth + Theme.u(4)
            height: infoLabel.implicitHeight + Theme.u(2)
            radius: Theme.u(1)
            color: Qt.rgba(0, 0, 0, 0.6)

            Text {
                id: infoLabel
                anchors.centerIn: parent
                color: Theme.text
                font.pixelSize: Theme.fontL
            }
        }

        Text {
            visible: !info.visible && (page.playback ? page.playback.error !== "" || page.playback.starting : false)
            anchors.centerIn: parent
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: !page.playback ? "" : page.playback.error !== "" ? page.playback.error : "Loading…"
            color: page.playback && page.playback.error !== "" ? Theme.text : Theme.textDim
            style: Text.Outline
            styleColor: "black"
            font.pixelSize: Theme.fontM
        }
    }

    Column {
        id: details
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                  leftMargin: Theme.u(2); rightMargin: Theme.u(2); bottomMargin: Theme.u(2) }
        spacing: Theme.u(1)

        // Title and artist, between shuffle and repeat. Repeat steps through
        // off, all and one, as VLC's button does.
        Item {
            width: parent.width
            height: names.height

            IconButton {
                id: shuffleButton
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                glyph: "shuffle"
                color: page.playback && page.playback.shuffle ? Theme.accent : Theme.textDim
                onClicked: {
                    page.playback.setShuffle(!page.playback.shuffle);
                    page.showInfo(page.playback.shuffle ? "Shuffle on" : "Shuffle off", 1000);
                }
            }

            IconButton {
                id: repeatButton
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                glyph: "repeat"
                color: page.playback && page.playback.repeat !== "none" ? Theme.accent : Theme.textDim
                onClicked: {
                    page.playback.cycleRepeat();
                    var mode = page.playback.repeat;
                    page.showInfo(mode === "all" ? "Repeat all" : mode === "one" ? "Repeat one" : "Repeat off", 1000);
                }

                Text {
                    visible: page.playback ? page.playback.repeat === "one" : false
                    anchors.centerIn: parent
                    text: "1"
                    color: Theme.accent
                    font.pixelSize: Theme.fontXS
                    font.bold: true
                }
            }

            Column {
                id: names
                anchors { left: shuffleButton.right; right: repeatButton.left; verticalCenter: parent.verticalCenter
                          leftMargin: Theme.u(0.5); rightMargin: Theme.u(0.5) }
                spacing: Theme.u(1)

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    text: page.playback ? page.playback.title : ""
                    color: Theme.text
                    font.pixelSize: Theme.fontL
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    // Keeps its line when empty, so the buttons do not move between tracks.
                    text: page.playback ? page.playback.artist : ""
                    color: Theme.textDim
                    font.pixelSize: Theme.fontM
                }
            }
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

        // Previous, rewind, play, forward, next. Rewind and forward go 10 s.
        Item {
            width: parent.width
            height: Theme.u(10)

            IconButton {
                id: playButton
                anchors.centerIn: parent
                implicitWidth: Theme.u(10)
                implicitHeight: Theme.u(10)
                glyphSize: Theme.u(5)
                glyph: page.playback && page.playback.playing ? "pause" : "play"
                color: Theme.text
                onClicked: page.playback.toggle()
            }
            IconButton {
                id: rewindButton
                anchors { right: playButton.left; rightMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
                implicitWidth: Theme.u(6)
                implicitHeight: Theme.u(6)
                glyph: "rewind"
                color: Theme.text
                enabled: page.playback ? page.playback.seekable : false
                onClicked: page.playback.seekBy(-10000)
            }
            IconButton {
                id: forwardButton
                anchors { left: playButton.right; leftMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
                implicitWidth: Theme.u(6)
                implicitHeight: Theme.u(6)
                glyph: "fastforward"
                color: Theme.text
                enabled: page.playback ? page.playback.seekable : false
                onClicked: page.playback.seekBy(10000)
            }
            IconButton {
                anchors { right: rewindButton.left; rightMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
                implicitWidth: Theme.u(6)
                implicitHeight: Theme.u(6)
                glyph: "previous"
                color: Theme.text
                onClicked: page.playback.previous()
            }
            IconButton {
                anchors { left: forwardButton.right; leftMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
                implicitWidth: Theme.u(6)
                implicitHeight: Theme.u(6)
                glyph: "next"
                color: Theme.text
                enabled: page.playback ? page.playback.hasNext : false
                onClicked: page.playback.next()
            }
        }
    }

    // The queue. A tap goes to that item.
    OptionSheet {
        id: queueSheet
        anchors.fill: parent
        title: page.playback ? "Queue – " + (page.playback.queueIndex + 1) + " of " + page.playback.queue.length
                             : "Queue"
        options: {
            var list = [];
            var queue = page.playback ? page.playback.queue : [];
            for (var i = 0; i < queue.length; i++)
                list.push({ key: "" + i, label: queue[i].title, glyph: queue[i].hasPicture ? "video" : "audio",
                            selected: i === page.playback.queueIndex,
                            value: Format.clock(queue[i].duration) });
            return list;
        }
        onChosen: page.playback.jumpTo(parseInt(key))
    }
}
