import QtQuick 2.12
import QtQuick.Window 2.12
import QtMultimedia 5.12
import Gem 1.0
import "../js/Format.js" as Format
import "../js/Gestures.js" as Gestures

/*
 * The video player: picture, gestures, controls.
 *
 * Behaviour follows VLC for Android (docs/VLC-FEATURES.md, "Video player").
 * The page does not own playback; it shows and steers the app's one Playback
 * object, so leaving the page for "play as audio" does not interrupt anything.
 *
 * Orientation: the page turns its own content to follow the phone, as VLC's
 * "automatic" mode does, whatever the system's rotation lock says. The window
 * itself is left to the system.
 */
Item {
    id: page

    property var playback: null

    signal closeRequested()
    signal audioRequested()

    // ---- orientation -------------------------------------------------------------

    property bool orientationLocked: false
    property int contentAngle: 0            // 0, 90 or 270: how far the content is turned in the window

    readonly property bool windowLandscape: width > height

    function sensorAngle() {
        var o = Screen.orientation;
        var sensorLandscape = o === Qt.LandscapeOrientation || o === Qt.InvertedLandscapeOrientation;
        if (sensorLandscape === windowLandscape)
            return 0;
        if (!windowLandscape)
            return o === Qt.LandscapeOrientation ? 270 : 90;
        return o === Qt.InvertedPortraitOrientation ? 270 : 90;
    }

    function followSensor() {
        if (!orientationLocked)
            contentAngle = sensorAngle();
    }

    Screen.orientationUpdateMask: Qt.PortraitOrientation | Qt.LandscapeOrientation
                                  | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation
    Screen.onOrientationChanged: followSensor()
    onWindowLandscapeChanged: followSensor()
    Component.onCompleted: {
        followSensor();
        showControls();
    }

    // ---- picture size ---------------------------------------------------------------

    // VLC's twelve modes. A tap on the resize button steps through the main
    // ones; a long press lists them all.
    readonly property var aspectModes: [
        { key: "best", label: "Best fit" },
        { key: "fit", label: "Fit screen" },
        { key: "fill", label: "Fill" },
        { key: "center", label: "Center" },
        { key: "16:9", label: "16:9", ratio: 16 / 9 },
        { key: "4:3", label: "4:3", ratio: 4 / 3 },
        { key: "16:10", label: "16:10", ratio: 16 / 10 },
        { key: "2:1", label: "2:1", ratio: 2 },
        { key: "2.21:1", label: "2.21:1", ratio: 2.21 },
        { key: "2.35:1", label: "2.35:1", ratio: 2.35 },
        { key: "2.39:1", label: "2.39:1", ratio: 2.39 },
        { key: "5:4", label: "5:4", ratio: 5 / 4 }
    ]
    // Which modes the button steps through is defined in libVLC, which is not
    // in the reference clone; this order is ours.
    readonly property var mainAspects: [0, 1, 2, 4, 5, 3]
    property int aspectIndex: 0
    property int aspectBeforePinch: -1

    function setAspect(index) {
        aspectIndex = index;
        showInfo(aspectModes[index].label, 1000);
    }

    function nextAspect() {
        var at = mainAspects.indexOf(aspectIndex);
        setAspect(mainAspects[(at + 1) % mainAspects.length]);
    }

    // ---- what the gestures change ---------------------------------------------------

    property real brightness: 1.0           // 1 is the screen as it is; less dims the picture
    property bool locked: false
    property bool controlsShown: true

    // Double taps on the same side add up while they follow each other closely.
    property int tapSeekTotal: 0
    property string tapSeekSide: ""

    // A new file: unlocked, controls showing. Picture size and brightness stay
    // as the viewer left them.
    function reset() {
        locked = false;
        unlock.visible = false;
        menu.close();
        aspectSheet.close();
        tapSeekTotal = 0;
        showControls();
    }

    function showControls() {
        controlsShown = true;
        hideControls.restart();
    }

    function showInfo(text, ms) {
        level.kind = "";
        info.text = text;
        info.visible = true;
        infoHide.interval = ms;
        infoHide.restart();
    }

    function showLevel(kind, value) {
        info.visible = false;
        level.kind = kind;
        level.value = value;
        infoHide.interval = 800;
        infoHide.restart();
    }

    function tapSeek(side) {
        if (!playback.seekable)  {
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

    function openMenu() { menu.show(); }
    function openAspectList() { aspectSheet.show(); }

    function back() {
        if (menu.open) {
            menu.close();
        } else if (aspectSheet.open) {
            aspectSheet.close();
        } else if (!locked) {
            closeRequested();
        }
    }

    // The controls go away after four seconds, but stay while the video is
    // paused or something on them is in use.
    Timer {
        id: hideControls
        interval: 4000
        onTriggered: {
            if (page.playback && page.playback.playing && !controls.dragging && !menu.open && !aspectSheet.open)
                page.controlsShown = false;
            else
                restart();
        }
    }

    Timer {
        id: infoHide
        onTriggered: { info.visible = false; level.kind = ""; }
    }

    Timer {
        id: tapSeekReset
        interval: 750
        onTriggered: { page.tapSeekTotal = 0; page.tapSeekSide = ""; }
    }

    Timer {
        id: unlockHide
        interval: 3000
        onTriggered: unlock.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Everything below is laid out for the orientation the content is turned to.
    Item {
        id: stage
        anchors.centerIn: parent
        rotation: page.contentAngle
        width: page.contentAngle === 0 ? page.width : page.height
        height: page.contentAngle === 0 ? page.height : page.width

        VideoOutput {
            id: video
            source: page.playback ? page.playback.player : null

            readonly property var mode: page.aspectModes[page.aspectIndex]
            readonly property real boxRatio: stage.width / Math.max(1, stage.height)
            readonly property bool sized: mode.key === "center" && sourceRect.width > 0

            fillMode: mode.key === "best" ? VideoOutput.PreserveAspectFit
                    : mode.key === "fit" ? VideoOutput.PreserveAspectCrop
                    : (mode.key === "center" && !sized) ? VideoOutput.PreserveAspectFit
                    : VideoOutput.Stretch
            width: mode.ratio ? (boxRatio > mode.ratio ? stage.height * mode.ratio : stage.width)
                 : sized ? sourceRect.width : stage.width
            height: mode.ratio ? (boxRatio > mode.ratio ? stage.height : stage.width / mode.ratio)
                  : sized ? sourceRect.height : stage.height
            anchors.centerIn: parent
        }

        // "Brightness": the app cannot set the backlight, so it darkens the picture.
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: (1 - page.brightness) * 0.85
        }

        GestureLayer {
            id: gestures
            anchors.fill: parent
            locked: page.locked
            seekable: page.playback ? page.playback.seekable : false

            onTapped: {
                if (page.locked) {
                    unlock.visible = true;
                    unlockHide.restart();
                } else if (page.controlsShown) {
                    page.controlsShown = false;
                } else {
                    page.showControls();
                }
            }

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

            onVolumeMoved: {
                page.playback.volume = Math.max(0, Math.min(1, page.playback.volume + delta));
                page.showLevel("volume", page.playback.volume);
                page.controlsShown = false;
            }

            onBrightnessMoved: {
                page.brightness = Math.max(0.05, Math.min(1, page.brightness + delta));
                page.showLevel("brightness", page.brightness);
                page.controlsShown = false;
            }

            // Pinch out fills the screen; pinch in goes back to what it was.
            onPinched: {
                if (grow && page.aspectIndex !== 1) {
                    page.aspectBeforePinch = page.aspectIndex;
                    page.setAspect(1);
                } else if (!grow && page.aspectBeforePinch >= 0) {
                    page.setAspect(page.aspectBeforePinch);
                    page.aspectBeforePinch = -1;
                } else if (!grow && page.aspectIndex === 1) {
                    page.setAspect(0);
                }
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

        // Seek and resize messages.
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

        // Volume and brightness.
        Rectangle {
            id: level
            property string kind: ""
            property real value: 0
            visible: kind !== ""
            anchors.centerIn: parent
            width: Theme.u(22)
            height: Theme.u(7)
            radius: Theme.u(1)
            color: Qt.rgba(0, 0, 0, 0.6)

            Glyph {
                id: levelIcon
                anchors { left: parent.left; leftMargin: Theme.u(1.5); verticalCenter: parent.verticalCenter }
                width: Theme.u(2.8)
                name: level.kind === "brightness" ? "brightness" : "volume"
            }
            Rectangle {
                anchors { left: levelIcon.right; leftMargin: Theme.u(1.5); right: levelText.left; rightMargin: Theme.u(1.5)
                          verticalCenter: parent.verticalCenter }
                height: Math.max(2, Theme.u(0.4))
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.25)
                Rectangle {
                    width: parent.width * level.value
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                }
            }
            Text {
                id: levelText
                anchors { right: parent.right; rightMargin: Theme.u(1.5); verticalCenter: parent.verticalCenter }
                width: Theme.u(4.5)
                horizontalAlignment: Text.AlignRight
                text: Math.round(level.value * 100) + "%"
                color: Theme.text
                font.pixelSize: Theme.fontS
            }
        }

        Text {
            visible: page.playback && page.playback.error !== ""
            anchors.centerIn: parent
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: page.playback ? page.playback.error : ""
            color: Theme.text
            font.pixelSize: Theme.fontM
        }

        PlayerControls {
            id: controls
            anchors.fill: parent
            playback: page.playback
            orientationLocked: page.orientationLocked
            opacity: page.controlsShown && !page.locked ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            onBack: page.back()
            onInteracted: page.showControls()
            onMenuRequested: page.openMenu()
            onAspectTapped: page.nextAspect()
            onAspectHeld: page.openAspectList()
            onOrientationTapped: {
                page.orientationLocked = !page.orientationLocked;
                page.showInfo(page.orientationLocked ? "Orientation locked" : "Orientation follows the phone", 1000);
                page.followSensor();
            }
        }

        // Locked: a tap shows this for a moment; sliding it across unlocks.
        Rectangle {
            id: unlock
            visible: false
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.u(4) }
            width: Theme.u(28)
            height: Theme.u(6)
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.6)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.3)
            onVisibleChanged: knob.x = knob.restX

            Text {
                anchors.centerIn: parent
                text: "Slide to unlock"
                color: Theme.textDim
                font.pixelSize: Theme.fontS
            }

            Rectangle {
                id: knob
                readonly property real restX: Theme.u(0.5)
                readonly property real endX: unlock.width - width - Theme.u(0.5)
                x: restX
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.u(5)
                height: width
                radius: width / 2
                color: Theme.accent

                Glyph {
                    anchors.centerIn: parent
                    width: Theme.u(2.4)
                    name: "lock"
                    color: Theme.bg
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Theme.u(1)
                    drag.target: knob
                    drag.axis: Drag.XAxis
                    drag.minimumX: knob.restX
                    drag.maximumX: knob.endX
                    onPressed: unlockHide.stop()
                    onReleased: {
                        if (knob.x > knob.endX - Theme.u(1)) {
                            page.locked = false;
                            unlock.visible = false;
                            page.showControls();
                        } else {
                            knob.x = knob.restX;
                            unlockHide.restart();
                        }
                    }
                }
            }
        }

        OptionSheet {
            id: menu
            anchors.fill: parent
            options: [
                { key: "lock", label: "Lock", glyph: "lock" },
                { key: "audio", label: "Play as audio", glyph: "audio" }
            ]
            onChosen: {
                if (key === "lock") {
                    page.locked = true;
                    page.controlsShown = false;
                    page.showInfo("Locked", 1000);
                } else if (key === "audio") {
                    page.audioRequested();
                }
            }
        }

        OptionSheet {
            id: aspectSheet
            anchors.fill: parent
            title: "Picture size"
            options: {
                var list = [];
                for (var i = 0; i < page.aspectModes.length; i++)
                    list.push({ key: "" + i, label: page.aspectModes[i].label, selected: i === page.aspectIndex });
                return list;
            }
            onChosen: page.setAspect(parseInt(key))
        }
    }
}
