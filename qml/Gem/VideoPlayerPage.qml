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
    property var store: null                // PlayerStore: bookmarks
    property var sleep: null                // SleepTimer
    property var systemVolume: null         // platform/SystemVolume.qml, or null off the device
    property var systemBrightness: null     // platform/SystemBrightness.qml, likewise
    property string picturesFolder: ""      // where screenshots go; empty if unknown

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

    property real brightness: 1.0           // the fallback: 1 is the picture as it is, less darkens it
    property bool locked: false
    property bool controlsShown: true

    // Double taps on the same side add up while they follow each other closely.
    property int tapSeekTotal: 0
    property string tapSeekSide: ""

    readonly property bool sheetOpen: menu.open || aspectSheet.open || subtitleSheet.open || bookmarkSheet.open
                                      || infoSheet.open || jumpPicker.open || sleepPicker.open

    function closeSheets() {
        menu.close();
        aspectSheet.close();
        subtitleSheet.close();
        bookmarkSheet.close();
        infoSheet.close();
        jumpPicker.close();
        sleepPicker.close();
    }

    // A new file: unlocked, controls showing. Picture size and brightness stay
    // as the viewer left them.
    function reset() {
        locked = false;
        unlock.visible = false;
        closeSheets();
        tapSeekTotal = 0;
        showControls();
    }

    function showControls() {
        controlsShown = true;
        hideControls.restart();
        if (sleep)
            sleep.interaction();
    }

    // ---- bookmarks, A-B repeat, screenshot ------------------------------------------

    readonly property var bookmarks: store && playback && playback.url !== "" && store.bookmarkRevision >= 0
                                     ? store.bookmarks(playback.url) : []

    readonly property var timelineMarkers: {
        var list = [];
        for (var i = 0; i < bookmarks.length; i++)
            list.push({ position: bookmarks[i].position, color: Theme.diamond });
        if (playback && playback.abStart >= 0)
            list.push({ position: playback.abStart, color: Theme.emerald });
        if (playback && playback.abEnd >= 0)
            list.push({ position: playback.abEnd, color: Theme.ruby });
        return list;
    }

    function addBookmark() {
        store.addBookmark(playback.url, playback.position, "Bookmark at " + Format.clock(playback.position));
        showInfo("Bookmark added", 1000);
    }

    function markAB() {
        var before = playback.abStart;
        playback.markAB();
        if (playback.abEnd >= 0)
            showInfo("Repeating " + Format.clock(playback.abStart) + " \u2013 " + Format.clock(playback.abEnd), 1500);
        else if (playback.abStart >= 0 && before < 0)
            showInfo("A-B repeat: start set. Choose it again at the end.", 2000);
        else if (playback.abStart >= 0)
            showInfo("The end must be after the start", 1500);
        else
            showInfo("A-B repeat off", 1000);
    }

    // The picture alone, without controls or dimming, as a PNG in Pictures.
    function takeScreenshot() {
        var name = "GemPlayer " + playback.title.replace(/[\/:*?"<>|]/g, " ").trim()
                   + " " + Format.clock(playback.position).replace(/:/g, "-") + ".png";
        var target = picturesFolder + "/" + name;
        var started = video.grabToImage(function(grab) {
            page.showInfo(grab.saveToFile(target) ? "Screenshot saved to Pictures" : "The screenshot could not be saved", 1500);
        });
        if (!started)
            showInfo("The screenshot could not be taken", 1500);
    }

    // ---- keyboard --------------------------------------------------------------------

    // VLC's keys, as far as their features exist here. Returns whether the key
    // was used.
    function handleKey(event) {
        if (locked)
            return false;
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_MediaTogglePlayPause:
        case Qt.Key_MediaPlay:
        case Qt.Key_MediaPause:
            playback.toggle(); break;
        case Qt.Key_Right: tapSeek("forward"); break;
        case Qt.Key_Left: tapSeek("back"); break;
        case Qt.Key_Up: changeVolume(0.05); break;
        case Qt.Key_Down: changeVolume(-0.05); break;
        case Qt.Key_A:
        case Qt.Key_Z:
            nextAspect(); break;
        case Qt.Key_G: changeSubtitleDelay(-50); break;
        case Qt.Key_H: changeSubtitleDelay(50); break;
        case Qt.Key_S:
        case Qt.Key_MediaStop:
            closeRequested(); break;
        case Qt.Key_T: showControls(); break;
        default:
            return false;
        }
        return true;
    }

    // ---- brightness ------------------------------------------------------------------

    // The left-hand swipe sets the real backlight where the system lets us,
    // and darkens the picture where it does not.
    readonly property bool realBrightness: systemBrightness !== null && systemBrightness.available

    // What the viewer set in the player (-1: nothing yet), and what the phone
    // had before. The player's brightness belongs to the player: the phone
    // gets its own back whenever the player is left, and the player's returns
    // with it.
    property real playerBrightness: -1
    property real brightnessBefore: -1
    readonly property bool inUse: visible && Qt.application.state === Qt.ApplicationActive

    onInUseChanged: {
        if (playerBrightness < 0 || !systemBrightness)
            return;
        if (inUse) {
            brightnessBefore = systemBrightness.level;
            systemBrightness.set(playerBrightness);
        } else {
            systemBrightness.set(brightnessBefore);
        }
    }

    function changeBrightness(delta) {
        if (realBrightness) {
            if (playerBrightness < 0) {
                brightnessBefore = systemBrightness.level;
                playerBrightness = brightnessBefore;
            }
            playerBrightness = Math.max(0.03, Math.min(1, playerBrightness + delta));
            systemBrightness.set(playerBrightness);
            showLevel("brightness", playerBrightness);
        } else {
            brightness = Math.max(0.05, Math.min(1, brightness + delta));
            showLevel("brightness", brightness);
        }
    }

    // ---- volume and subtitles ---------------------------------------------------------

    // The level being set. The system answers a moment later, so a gesture
    // counts from its own last value, not from what the system reports.
    property real volumeLevel: -1

    function changeVolume(delta) {
        if (!systemVolume || !systemVolume.available) {
            showInfo("The volume cannot be set from here", 1000);
            return;
        }
        if (volumeLevel < 0 || level.kind !== "volume")
            volumeLevel = systemVolume.level;
        volumeLevel = Math.max(0, Math.min(1, volumeLevel + delta));
        systemVolume.set(volumeLevel);
        showLevel("volume", volumeLevel);
    }

    function changeSubtitleDelay(ms) {
        if (!subtitles.available)
            return;
        subtitles.delay += ms;
        showInfo("Subtitle delay " + (subtitles.delay > 0 ? "+" : "") + subtitles.delay + " ms", 1500);
    }

    SubtitleTrack {
        id: subtitles
        mediaUrl: page.playback ? page.playback.url : ""
        position: page.playback ? page.playback.position : 0
    }

    function showInfo(text, ms) {
        level.kind = "";
        info.text = text;
        info.visible = true;
        infoHide.interval = ms;
        infoHide.restart();
    }

    function showLevel(kind, value, ms) {
        info.visible = false;
        level.kind = kind;
        level.value = value;
        infoHide.interval = ms || 800;
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

    // By name, for the development remote.
    function openSheet(name) {
        var sheets = { menu: menu, aspects: aspectSheet, subtitles: subtitleSheet, bookmarks: bookmarkSheet,
                       info: infoSheet, jump: jumpPicker, sleep: sleepPicker };
        if (sheets[name])
            sheets[name].show();
    }

    function back() {
        if (sheetOpen)
            closeSheets();
        else if (!locked)
            closeRequested();
    }

    // The controls go away after four seconds, but stay while the video is
    // paused or something on them is in use.
    Timer {
        id: hideControls
        interval: 4000
        onTriggered: {
            if (page.playback && page.playback.playing && !controls.dragging && !page.sheetOpen)
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

        // Brightness without access to the backlight: darken the picture.
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
                page.changeVolume(delta);
                page.controlsShown = false;
            }

            onBrightnessMoved: {
                page.changeBrightness(delta);
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

        // External subtitles, drawn here: white with a dark outline, at the
        // bottom of the picture, or above the controls while those show.
        Text {
            visible: text !== ""
            z: 1
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom
                      bottomMargin: page.controlsShown && !page.locked ? Theme.u(13)
                                                                         : Math.max(Theme.u(2), parent.height * 0.05) }
            width: parent.width * 0.9
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            text: subtitles.text
            color: "white"
            style: Text.Outline
            styleColor: "black"
            font.pixelSize: Math.max(Theme.fontM, Math.min(parent.width, parent.height) * 0.052)
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
            visible: page.playback ? page.playback.error !== "" || page.playback.starting : false
            anchors.centerIn: parent
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: !page.playback ? "" : page.playback.error !== "" ? page.playback.error : "Loading\u2026"
            color: page.playback && page.playback.error !== "" ? Theme.text : Theme.textDim
            font.pixelSize: Theme.fontM
        }

        PlayerControls {
            id: controls
            anchors.fill: parent
            playback: page.playback
            orientationLocked: page.orientationLocked
            subtitlesAvailable: subtitles.available
            subtitlesOn: subtitles.enabled
            markers: page.timelineMarkers
            chips: {
                var list = [];
                if (page.sleep && page.sleep.active)
                    list.push({ key: "sleep", label: "Sleep " + Format.clock(page.sleep.remaining) });
                if (page.playback && page.playback.abStart >= 0)
                    list.push({ key: "ab", label: page.playback.abEnd >= 0 ? "A-B repeat" : "A-B: set the end" });
                if (subtitles.delay !== 0)
                    list.push({ key: "delay", label: "Subtitles " + (subtitles.delay > 0 ? "+" : "") + subtitles.delay + " ms" });
                return list;
            }
            opacity: page.controlsShown && !page.locked ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            onBack: page.back()
            onInteracted: page.showControls()
            onMenuRequested: page.openMenu()
            onAspectTapped: page.nextAspect()
            onAspectHeld: page.openAspectList()
            onSubtitlesTapped: subtitleSheet.show()
            onChipTapped: {
                if (key === "sleep")
                    sleepPicker.show();
                else if (key === "ab")
                    page.markAB();
                else if (key === "delay")
                    subtitleSheet.show();
            }
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

        // The player menu, in VLC's order. An entry appears only when it can
        // do something.
        OptionSheet {
            id: menu
            anchors.fill: parent
            options: {
                var p = page.playback;
                var list = [
                    { key: "lock", label: "Lock", glyph: "lock" },
                    { key: "sleep", label: "Sleep timer", glyph: "clock",
                      selected: page.sleep ? page.sleep.active : false,
                      value: page.sleep && page.sleep.active ? "on" : "" },
                    { key: "jump", label: "Jump to time", glyph: "jump" },
                    { key: "audio", label: "Play as audio", glyph: "audio" },
                    { key: "info", label: "Video information", glyph: "info" },
                    { key: "bookmarks", label: "Bookmarks", glyph: "bookmark",
                      value: page.bookmarks.length > 0 ? "" + page.bookmarks.length : "" },
                    { key: "ab", label: "A-B repeat", glyph: "repeat", selected: p && p.abStart >= 0,
                      value: !p || p.abStart < 0 ? "" : p.abEnd < 0 ? "set the end" : "on" }
                ];
                if (page.picturesFolder !== "")
                    list.push({ key: "screenshot", label: "Screenshot", glyph: "camera" });
                return list;
            }
            onChosen: {
                if (key === "lock") {
                    page.locked = true;
                    page.controlsShown = false;
                    page.showInfo("Locked", 1000);
                } else if (key === "sleep") {
                    sleepPicker.show();
                } else if (key === "jump") {
                    jumpPicker.show();
                } else if (key === "audio") {
                    page.audioRequested();
                } else if (key === "info") {
                    infoSheet.show();
                } else if (key === "bookmarks") {
                    bookmarkSheet.show();
                } else if (key === "ab") {
                    page.markAB();
                } else if (key === "screenshot") {
                    page.takeScreenshot();
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

        OptionSheet {
            id: subtitleSheet
            anchors.fill: parent
            title: "Subtitles"
            options: [
                { key: "toggle", label: subtitles.enabled ? "Showing" : "Hidden", glyph: "subtitles",
                  selected: subtitles.enabled, stay: true },
                { key: "earlier", label: "Show earlier", value: "\u2212 50 ms", stay: true },
                { key: "later", label: "Show later", value: "+ 50 ms", stay: true },
                { key: "reset", label: "Delay", value: (subtitles.delay > 0 ? "+" : "") + subtitles.delay + " ms", stay: true }
            ]
            onChosen: {
                if (key === "toggle")
                    subtitles.enabled = !subtitles.enabled;
                else if (key === "earlier")
                    subtitles.delay -= 50;
                else if (key === "later")
                    subtitles.delay += 50;
                else if (key === "reset")
                    subtitles.delay = 0;
            }
        }

        // Tap a bookmark to go there; hold it to remove it.
        OptionSheet {
            id: bookmarkSheet
            anchors.fill: parent
            title: page.bookmarks.length > 0 ? "Bookmarks \u2013 hold one to remove it" : "Bookmarks"
            options: {
                var list = [{ key: "add", label: "Add bookmark", glyph: "add", stay: true }];
                for (var i = 0; i < page.bookmarks.length; i++)
                    list.push({ key: "" + page.bookmarks[i].position, label: page.bookmarks[i].title, glyph: "bookmark" });
                return list;
            }
            onChosen: {
                if (key === "add")
                    page.addBookmark();
                else
                    page.playback.seekTo(parseInt(key));
            }
            onHeld: {
                if (key === "add")
                    return;
                page.store.removeBookmark(page.playback.url, parseInt(key));
                page.showInfo("Bookmark removed", 1000);
            }
        }

        // What can be known about the file. The backend reports no codecs or
        // bit rates, so there are none here.
        OptionSheet {
            id: infoSheet
            anchors.fill: parent
            title: "Video information"
            options: {
                var p = page.playback;
                if (!p || !open)
                    return [];
                var path = decodeURIComponent(p.url.replace("file://", ""));
                var slash = path.lastIndexOf("/");
                var dot = path.lastIndexOf(".");
                var local = p.url.indexOf("file://") === 0;
                var list = [{ label: "Name", value: p.title }];
                if (local) {
                    list.push({ label: "File", value: path.substring(slash + 1) });
                    list.push({ label: "Folder", value: path.substring(0, slash) });
                    if (dot > slash)
                        list.push({ label: "Format", value: path.substring(dot + 1).toUpperCase() });
                } else {
                    list.push({ label: "Address", value: p.url });
                }
                list.push({ label: "Length", value: Format.clock(p.duration) });
                if (video.sourceRect.width > 0)
                    list.push({ label: "Picture", value: video.sourceRect.width + " \u00d7 " + video.sourceRect.height });
                if (subtitles.available)
                    list.push({ label: "Subtitles", value: decodeURIComponent(subtitles.source.substring(subtitles.source.lastIndexOf("/") + 1)) });
                return list;
            }
        }

        TimePicker {
            id: jumpPicker
            anchors.fill: parent
            title: "Jump to time"
            onAccepted: page.playback.seekTo(ms)
        }

        TimePicker {
            id: sleepPicker
            anchors.fill: parent
            title: "Sleep in"
            withSeconds: false
            sleepOptions: true
            canRemove: page.sleep ? page.sleep.active : false
            onOpenChanged: {
                if (open && page.sleep) {
                    waitForEnd = page.sleep.waitForEnd;
                    resetOnInteraction = page.sleep.resetOnInteraction;
                }
            }
            onAccepted: {
                page.sleep.start(ms, waitForEnd, resetOnInteraction);
                if (ms > 0)
                    page.showInfo("Sleep in " + Format.clock(ms), 1500);
            }
            onRemoved: {
                page.sleep.cancel();
                page.showInfo("Sleep timer off", 1000);
            }
        }
    }
}
