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
 * gestures work on the cover. A double tap on a side seeks 10 s, a
 * horizontal swipe seeks further; a vertical swipe sets the volume on the
 * right and the screen's brightness on the left. Previous and next are
 * buttons here, and a sideways swipe on the mini-player.
 */
Item {
    id: page

    property var playback: null
    property var store: null                // PlayerStore: bookmarks
    property var sleep: null                // SleepTimer
    property var systemVolume: null         // platform/SystemVolume.qml, or null off the device
    property var systemBrightness: null     // platform/SystemBrightness.qml, likewise

    signal collapseRequested()
    signal stopRequested()
    signal videoRequested()

    readonly property bool hasQueue: playback ? playback.queue.length > 1 : false

    // Double taps on the same side add up while they follow each other closely.
    property int tapSeekTotal: 0
    property string tapSeekSide: ""

    readonly property bool sheetOpen: menu.open || queueSheet.open || queueItemMenu.open || bookmarkSheet.open
                                      || jumpPicker.open || sleepPicker.open

    function closeSheets() {
        menu.close();
        queueSheet.close();
        queueItemMenu.close();
        bookmarkSheet.close();
        jumpPicker.close();
        sleepPicker.close();
    }

    function back() {
        if (sheetOpen)
            closeSheets();
        else
            collapseRequested();
    }

    // By name, for the development remote.
    function openSheet(name) {
        var sheets = { menu: menu, queue: queueSheet, bookmarks: bookmarkSheet, jump: jumpPicker, sleep: sleepPicker };
        if (sheets[name])
            sheets[name].show();
    }

    // ---- bookmarks and A-B repeat, as in the video player ---------------------------

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

    // What is switched on, shown under the header; a tap goes to its setting.
    readonly property var chips: {
        var list = [];
        if (sleep && sleep.active)
            list.push({ key: "sleep", label: "Sleep " + Format.clock(sleep.remaining) });
        if (playback && playback.abStart >= 0)
            list.push({ key: "ab", label: playback.abEnd >= 0 ? "A-B repeat" : "A-B: set the end" });
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

    // ---- volume and brightness, as in the video player -------------------------------

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

    // What was set here (-1: nothing yet), and what the phone had before. As
    // in the video player the brightness belongs to this page: the phone
    // gets its own back when the page is left or the app is, and this page's
    // returns with the app. The page itself is made anew each time it is
    // opened, so it starts from the phone's brightness then.
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

    Component.onDestruction: {
        if (playerBrightness >= 0 && systemBrightness && inUse)
            systemBrightness.set(brightnessBefore);
    }

    function changeBrightness(delta) {
        if (!systemBrightness || !systemBrightness.available) {
            showInfo("The brightness cannot be set from here", 1000);
            return;
        }
        if (playerBrightness < 0) {
            brightnessBefore = systemBrightness.level;
            playerBrightness = brightnessBefore;
        }
        playerBrightness = Math.max(0.03, Math.min(1, playerBrightness + delta));
        systemBrightness.set(playerBrightness);
        showLevel("brightness", playerBrightness);
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
        onTriggered: { info.visible = false; level.kind = ""; }
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

    Loader {
        anchors.fill: parent
        source: "BlurredCover.qml"
        onLoaded: item.art = Qt.binding(function() { return page.playback ? page.playback.art : ""; })
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "Now playing"
        onBack: page.back()

        trailing: Row {
            IconButton {
                visible: page.hasQueue
                glyph: "playlist"
                color: Theme.text
                onClicked: queueSheet.show()
            }
            IconButton {
                glyph: "more"
                color: Theme.text
                onClicked: menu.show()
            }
        }
    }

    Row {
        z: 1
        anchors { left: parent.left; leftMargin: Theme.u(2); top: header.bottom; topMargin: Theme.u(1) }
        spacing: Theme.u(1)

        Repeater {
            model: page.chips
            delegate: Rectangle {
                width: chipLabel.implicitWidth + Theme.u(2.4)
                height: Theme.u(3.6)
                radius: height / 2
                color: Theme.surface
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
                    onClicked: {
                        if (modelData.key === "sleep")
                            sleepPicker.show();
                        else
                            page.markAB();
                    }
                }
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
            pinchEnabled: false

            onVolumeMoved: page.changeVolume(delta)
            onBrightnessMoved: page.changeBrightness(delta)

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
            visible: !info.visible && level.kind === "" && (page.playback ? page.playback.error !== "" || page.playback.starting : false)
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
                markers: page.timelineMarkers
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

    // The queue. A tap goes to that item; holding one that plays or is
    // still to come opens its menu.
    OptionSheet {
        id: queueSheet
        anchors.fill: parent
        title: page.playback ? "Queue – " + (page.playback.queueIndex + 1) + " of " + page.playback.queue.length
                               + " – hold an item for more"
                             : "Queue"
        options: {
            var list = [];
            var queue = page.playback ? page.playback.queue : [];
            for (var i = 0; i < queue.length; i++)
                list.push({ key: "" + i, label: queue[i].title, glyph: queue[i].hasPicture ? "video" : "audio",
                            selected: i === page.playback.queueIndex,
                            value: (i === page.playback.stopAfter ? "stops after  •  " : "")
                                   + Format.clock(queue[i].duration) });
            return list;
        }
        onChosen: page.playback.jumpTo(parseInt(key))
        onHeld: {
            var index = parseInt(key);
            if (index < page.playback.queueIndex)
                return;
            page.queueMenuIndex = index;
            queueItemMenu.show();
        }
    }

    property int queueMenuIndex: -1

    // One item of the queue: VLC's "Remove from queue" and "Stop after this
    // track". What plays cannot be removed.
    OptionSheet {
        id: queueItemMenu
        anchors.fill: parent
        title: page.playback && page.queueMenuIndex >= 0 && page.queueMenuIndex < page.playback.queue.length
               ? page.playback.queue[page.queueMenuIndex].title : ""
        options: {
            var p = page.playback;
            var list = [];
            if (!p)
                return list;
            if (page.queueMenuIndex > p.queueIndex)
                list.push({ key: "remove", label: "Remove from queue", glyph: "clear" });
            list.push({ key: "stopAfter", label: "Stop after this track", glyph: "pause",
                        selected: p.stopAfter === page.queueMenuIndex,
                        value: p.stopAfter === page.queueMenuIndex ? "on" : "" });
            return list;
        }
        onChosen: {
            if (key === "remove")
                page.playback.removeAt(page.queueMenuIndex);
            else if (key === "stopAfter")
                page.playback.setStopAfter(page.queueMenuIndex);
        }
    }

    // The player menu: the video player's entries that mean something
    // without a picture, in the same order.
    OptionSheet {
        id: menu
        anchors.fill: parent
        options: {
            var p = page.playback;
            var list = [
                { key: "sleep", label: "Sleep timer", glyph: "clock",
                  selected: page.sleep ? page.sleep.active : false,
                  value: page.sleep && page.sleep.active ? "on" : "" },
                { key: "jump", label: "Jump to time", glyph: "jump" }
            ];
            if (p && p.hasPicture)
                list.push({ key: "video", label: "Play as video", glyph: "video" });
            list.push({ key: "bookmarks", label: "Bookmarks", glyph: "bookmark",
                        value: page.bookmarks.length > 0 ? "" + page.bookmarks.length : "" });
            list.push({ key: "ab", label: "A-B repeat", glyph: "repeat", selected: p && p.abStart >= 0,
                        value: !p || p.abStart < 0 ? "" : p.abEnd < 0 ? "set the end" : "on" });
            return list;
        }
        onChosen: {
            if (key === "sleep")
                sleepPicker.show();
            else if (key === "jump")
                jumpPicker.show();
            else if (key === "video")
                page.videoRequested();
            else if (key === "bookmarks")
                bookmarkSheet.show();
            else if (key === "ab")
                page.markAB();
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
