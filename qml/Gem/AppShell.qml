import QtQuick 2.12
import QtQuick.Window 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The app: the one Playback object, the store of resume points, and the pages.
 * Created by Main.qml only after the app identity is set.
 *
 * Behind the tab bar are the five main pages, as in VLC; the players and the
 * diagnostics page cover them. What plays as audio carries on behind the main
 * pages, with the mini-player above the tabs. The sleep timer lives here
 * because it outlasts any one page.
 */
FocusScope {
    id: shell
    focus: true

    property var appWindow: null

    // "home", "video", "audio" or "diagnostics"
    property string page: "home"

    // The page shown at "home": "video", "audio", "browse", "playlists" or "more"
    property string tab: "video"
    readonly property var tabs: [
        { name: "video", title: "Video", glyph: "video" },
        { name: "audio", title: "Audio", glyph: "audio" },
        { name: "browse", title: "Browse", glyph: "folder" },
        { name: "playlists", title: "Playlists", glyph: "playlist" },
        { name: "more", title: "More", glyph: "dots" }
    ]

    readonly property alias playback: core
    readonly property alias videoPage: videoView
    readonly property var audioPage: audioLoader.item
    readonly property alias videoLibrary: videoTab
    readonly property alias audioLibrary: audioTab
    readonly property alias sleepTimer: sleeper
    readonly property var library: libraryLoader.status === Loader.Ready ? libraryLoader.item : null

    // Height of the on-screen keyboard, so content can sit above it. Lomiri's
    // MainView would do this for us; a plain Window has to do it itself.
    // Something plays as audio, or waits paused: the mini-player shows it.
    readonly property bool audioActive: core.audioMode && core.loaded

    readonly property real keyboardHeight: Qt.inputMethod.visible
        ? Qt.inputMethod.keyboardRectangle.height / Screen.devicePixelRatio
        : 0

    PlayerStore { id: playerStore }

    // What played as audio last time is there again, paused, in the mini-player.
    Component.onCompleted: core.restore()

    Playback {
        id: core
        store: playerStore
        onEnded: if (shell.page === "video" || core.audioMode) shell.closePlayer()
        onMediaChanged: if (shell.page === "video") videoView.reset()
    }

    SleepTimer {
        id: sleeper
        onExpired: core.pause()
    }

    // These only exist on Ubuntu Touch; anywhere else the Loader fails quietly.
    Loader { id: libraryLoader; source: "../platform/MediaLibrary.qml" }
    Loader { id: volumeLoader; source: "../platform/SystemVolume.qml" }
    Loader { id: brightnessLoader; source: "../platform/SystemBrightness.qml" }
    Loader { id: foldersLoader; source: "../platform/Folders.qml" }
    Loader {
        source: "../platform/ContentImport.qml"
        onLoaded: item.incoming.connect(shell.openUrl)
    }
    Loader {
        source: "../dev/Remote.qml"
        onLoaded: item.shell = shell
    }

    function openMedia(media) {
        playList([media], 0, {});
    }

    // Plays a list from its item `index`. options: { fromStart, asAudio,
    // background }; `background` leaves the lists in front, with the
    // mini-player, when the list plays as audio.
    function playList(list, index, options) {
        if (list.length === 0)
            return;
        var first = list[Math.max(0, Math.min(index, list.length - 1))];
        var asAudio = !!options.asAudio || !first.hasPicture;
        core.openQueue(list, index, !!options.fromStart, asAudio);
        if (asAudio) {
            if (!options.background)
                page = "audio";
        } else {
            videoView.reset();
            page = "video";
        }
    }

    // "Insert next" and "Add to play queue". They add to what plays as audio
    // behind the lists; with nothing playing there, the list is played.
    function addToQueue(list, next) {
        if (list.length === 0)
            return;
        if (!audioActive || core.queueIndex < 0) {
            playList(list, 0, { background: true });
            return;
        }
        if (next)
            core.insertNext(list);
        else
            core.append(list);
        var what = list.length === 1 ? "\u201c" + list[0].title + "\u201d"
                                     : list.length + (list[0].hasPicture ? " videos" : " tracks");
        notice.show(what + (next ? " will play next" : " added to the play queue"));
    }

    // A file from outside the list: another app, or a path.
    function openUrl(url) {
        var path = decodeURIComponent(url.toString().replace("file://", ""));
        var known = library ? library.lookup(path) : null;
        openMedia(known || { url: url.toString(), title: Format.baseName(url), duration: 0,
                             hasPicture: !Format.isAudioName(url) });
    }

    function openPath(path) {
        openUrl("file://" + path.split("/").map(encodeURIComponent).join("/"));
    }

    // "Play as audio" and back: the picture goes, the playback stays.
    function toAudio() {
        core.setAudioMode(true);
        page = "audio";
    }

    function toVideo() {
        core.setAudioMode(false);
        page = "video";
        core.play();
    }

    // Stops what plays. A video stops with its page; audio only when asked
    // to, or at the end of its queue.
    function closePlayer() {
        core.pause();
        core.clearQueue();
        core.setAudioMode(false);
        if (page === "video" || page === "audio")
            page = "home";
    }

    // One step back; false when there is nowhere to go back to.
    function back() {
        if (page === "video" && videoPage)
            videoPage.back();
        else if (page === "audio" && audioPage)
            audioPage.back();
        else if (page === "diagnostics")
            page = "home";
        else if (page === "home" && tab === "video")
            return videoTab.back();
        else if (page === "home" && tab === "audio")
            return audioTab.back();
        else
            return false;
        return true;
    }

    // The video player covers the system's top panel; nothing else does.
    onPageChanged: {
        if (appWindow)
            appWindow.visibility = page === "video" ? Window.FullScreen : Window.AutomaticVisibility;
    }

    // media-hub would play a video on behind the lock screen or another app.
    // VLC's default is to stop it unless it was switched to audio (D10).
    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive)
                return;
            if (Qt.application.state === Qt.ApplicationSuspended && shell.page === "video" && !core.audioMode)
                core.pause();
            else
                core.saveNow();
        }
    }

    Keys.onReleased: {
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape)
            event.accepted = back();
    }

    Keys.onPressed: {
        if (page === "video" && videoView.handleKey(event))
            event.accepted = true;
        else if (page === "audio" && audioPage && audioPage.handleKey(event))
            event.accepted = true;
    }

    Item {
        id: home
        anchors.fill: parent
        anchors.bottomMargin: shell.keyboardHeight
        visible: shell.page === "home"

        Item {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: miniPlayer.top }

            VideoLibraryPage {
                id: videoTab
                anchors.fill: parent
                visible: shell.tab === "video"
                library: shell.library
                store: playerStore
                overlay: home
                onPlayRequested: shell.playList(list, index, options)
                onQueueRequested: shell.addToQueue(list, next)
            }
            AudioLibraryPage {
                id: audioTab
                anchors.fill: parent
                visible: shell.tab === "audio"
                library: shell.library
                overlay: home
                playingUrl: shell.audioActive ? core.url : ""
                onPlayRequested: shell.playList(list, index, options)
                onQueueRequested: shell.addToQueue(list, next)
            }
            PlaceholderPage {
                anchors.fill: parent
                visible: shell.tab === "browse"
                title: "Browse"
                glyph: "folder"
                text: "The phone's folders and favourite places will be here."
            }
            PlaceholderPage {
                anchors.fill: parent
                visible: shell.tab === "playlists"
                title: "Playlists"
                glyph: "playlist"
                text: "Your playlists will be here."
            }
            MorePage {
                anchors.fill: parent
                visible: shell.tab === "more"
                onDiagnosticsRequested: shell.page = "diagnostics"
            }
        }

        // What was just done to the queue, for a moment, above the mini-player.
        Rectangle {
            id: notice
            property alias text: noticeLabel.text
            function show(message) {
                text = message;
                opacity = 1;
                noticeHide.restart();
            }
            opacity: 0
            visible: opacity > 0
            anchors { horizontalCenter: parent.horizontalCenter; bottom: miniPlayer.top; bottomMargin: Theme.u(1.5) }
            width: Math.min(parent.width - Theme.u(4), noticeLabel.implicitWidth + Theme.u(4))
            height: noticeLabel.implicitHeight + Theme.u(2)
            radius: Theme.u(1)
            color: Theme.surfaceAlt
            border.width: 1
            border.color: Theme.line
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                id: noticeLabel
                anchors.centerIn: parent
                width: Math.min(implicitWidth, notice.parent.width - Theme.u(8))
                elide: Text.ElideMiddle
                color: Theme.text
                font.pixelSize: Theme.fontS
            }
            Timer {
                id: noticeHide
                interval: 2500
                onTriggered: notice.opacity = 0
            }
        }

        MiniPlayer {
            id: miniPlayer
            anchors { left: parent.left; right: parent.right; bottom: tabBar.top }
            // Out of the way while something is being typed.
            visible: shell.audioActive && shell.keyboardHeight === 0
            height: visible ? implicitHeight : 0
            playback: core
            onExpandRequested: shell.page = "audio"
            onStopRequested: shell.closePlayer()
        }

        TabBar {
            id: tabBar
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            // Out of the way while something is being typed.
            height: shell.keyboardHeight > 0 ? 0 : implicitHeight
            clip: true
            tabs: shell.tabs
            current: shell.tab
            onChosen: shell.tab = name
        }
    }

    // Always there, shown or not: the backend only starts a video if its
    // picture has somewhere to go before playback begins, so the video surface
    // must exist before a file is opened. "Play as audio" hides it.
    VideoPlayerPage {
        id: videoView
        anchors.fill: parent
        visible: shell.page === "video"
        playback: core
        store: playerStore
        sleep: sleeper
        systemVolume: volumeLoader.status === Loader.Ready ? volumeLoader.item : null
        systemBrightness: brightnessLoader.status === Loader.Ready ? brightnessLoader.item : null
        picturesFolder: foldersLoader.status === Loader.Ready ? foldersLoader.item.pictures : ""
        onCloseRequested: shell.closePlayer()
        onAudioRequested: shell.toAudio()
    }

    Loader {
        id: audioLoader
        anchors.fill: parent
        active: shell.page === "audio"
        sourceComponent: Component {
            AudioPlayerPage {
                playback: core
                store: playerStore
                sleep: sleeper
                systemVolume: volumeLoader.status === Loader.Ready ? volumeLoader.item : null
                systemBrightness: brightnessLoader.status === Loader.Ready ? brightnessLoader.item : null
                onCollapseRequested: shell.page = "home"
                onStopRequested: shell.closePlayer()
                onVideoRequested: shell.toVideo()
            }
        }
    }

    // The Phase 0 spike, kept for checking the platform. It has players of its
    // own, so ours is paused while it is open.
    Loader {
        id: diagnostics
        anchors.fill: parent
        active: shell.page === "diagnostics"
        source: active ? "../spike/SpikeShell.qml" : ""
        onLoaded: {
            core.pause();
            item.appWindow = shell.appWindow;
        }

        TextButton {
            z: 1
            visible: diagnostics.status === Loader.Ready
            anchors { right: parent.right; top: parent.top; margins: Theme.u(1) }
            text: "Close"
            onClicked: shell.page = "home"
        }
    }
}
