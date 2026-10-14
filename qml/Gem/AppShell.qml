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
    readonly property alias browser: browseTab
    readonly property alias playlistsPage: playlistsTab
    readonly property alias playlistPicker: picker
    readonly property alias streamsPage: streamsView
    readonly property alias streamGate: gate

    readonly property alias historyPage: historyView
    readonly property alias searchPage: searchView

    // What covers the More tab: "" for nothing, "search", "streams",
    // "history", "settings" or "about".
    property string moreView: ""
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
    Prefs { id: settingsStore }

    readonly property alias prefs: settingsStore
    readonly property alias settingsPage: settingsView

    // What played as audio last time is there again, paused, in the
    // mini-player, unless the settings say otherwise.
    Component.onCompleted: {
        settingsStore.load();
        if (settingsStore.restoreQueue)
            core.restore();
    }

    Playback {
        id: core
        store: playerStore
        resumeVideos: settingsStore.resumeVideos
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
    Loader { id: backgroundLoader; source: "../platform/BackgroundRunning.qml" }
    readonly property var backgroundRunning: backgroundLoader.status === Loader.Ready ? backgroundLoader.item : null
    Loader {
        source: "../platform/ContentImport.qml"
        onLoaded: item.incoming.connect(shell.openIncoming)
    }
    // "Share", loaded the first time it is asked for: it brings in the
    // system's toolkit, which nothing else needs.
    Loader {
        id: shareLoader
        z: 3
        anchors.fill: parent
        active: false
        source: "../platform/ContentShare.qml"
        property var pending: null
        onLoaded: {
            item.closed.connect(function() { shareLoader.pending = null; });
            if (pending)
                item.ask(pending.urls, pending.videos);
        }
    }
    readonly property bool sharing: shareLoader.status === Loader.Ready && shareLoader.item.open
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
        // A stream, while streams are off: the question first (D14).
        if (core.blocks(list)) {
            gate.ask(_firstStream(list), function() { shell.playList(list, index, options); });
            return;
        }
        var asAudio = !!options.asAudio || !first.hasPicture;
        if (!core.openQueue(list, index, !!options.fromStart, asAudio))
            return;
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
        if (core.blocks(list)) {
            gate.ask(_firstStream(list), function() { shell.addToQueue(list, next); });
            return;
        }
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

    function openSearch() {
        page = "home";
        tab = "more";
        moreView = "search";
        searchView.open();
    }

    // "Add to playlist", from any page: the picker asks which one.
    function addToPlaylist(list) {
        picker.ask(list);
    }

    // A word about what was just done, wherever the user is looking.
    function say(message) {
        if (page === "audio" && audioPage)
            audioPage.showInfo(message, 2500);
        else
            notice.show(message);
    }

    function _firstStream(list) {
        for (var i = 0; i < list.length; i++)
            if (core.isStream(list[i].url))
                return list[i].url.toString();
        return "";
    }

    // A stream as the players take it. Whether it has a picture is only
    // known once it plays; until then its address is the guess.
    function streamMedia(address, title) {
        var url = Format.streamAddress(address);
        return { url: url, title: title || Format.streamTitle(url), artist: "", art: "", duration: 0,
                 hasPicture: !Format.isAudioAddress(url) };
    }

    // Plays a stream by its address, and notes it in the history once it
    // is allowed to play.
    function openStream(address, title) {
        var media = streamMedia(address, title);
        var play = function() {
            playerStore.noteStream(media.url, media.title);
            shell.playList([media], 0, {});
        };
        if (core.blocks([media]))
            gate.ask(media.url, play);
        else
            play();
    }

    // The switch. Switched off, a stream that plays or waits in the queue
    // goes with it: paused, and its queue closed. The system's player keeps
    // the paused stream loaded until something else is played; making it
    // let go by handing it an empty address starts the stream again, the
    // backend calling play by itself when its video sink is reset [device].
    function setStreamsAllowed(on) {
        core.setStreamsAllowed(on);
        if (!on && core.queue.some(function(media) { return core.isStream(media.url); })) {
            closePlayer();
        }
    }

    // A stream is opened as a video, its address saying nothing of what it
    // is. One that turns out to have no picture goes to the audio player.
    Timer {
        id: pictureCheck
        interval: 2000
        onTriggered: {
            if (shell.page === "video" && core.playing && core.isStream(core.url) && !core.player.hasVideo)
                shell.toAudio();
        }
    }
    Connections {
        target: core
        onStartingChanged: {
            if (!core.starting && shell.page === "video" && core.isStream(core.url))
                pictureCheck.restart();
        }
    }

    // A file from outside the lists, as the players take it: what the
    // library knows of it, or else its name and the kind its ending says.
    function fileMedia(url) {
        var path = decodeURIComponent(url.toString().replace("file://", ""));
        var known = library ? library.lookup(path) : null;
        return known || { url: url.toString(), title: Format.baseName(url), duration: 0,
                          hasPicture: !Format.isAudioName(url) };
    }

    // A file or a stream from outside the lists: another app, or a path.
    function openUrl(url) {
        openIncoming([url.toString()]);
    }

    // What another app handed over. Files play as a queue in the order
    // given, with their pictures if they are all videos and as audio
    // otherwise, as a playlist does. A link plays as a stream, through the
    // question if streams are off; with files beside it, the files play.
    function openIncoming(urls) {
        var files = [];
        var stream = "";
        for (var i = 0; i < urls.length; i++) {
            if (core.isStream(urls[i]))
                stream = stream || urls[i];
            else
                files.push(fileMedia(urls[i]));
        }
        if (files.length > 0) {
            var videosOnly = files.every(function(media) { return media.hasPicture; });
            playList(files, 0, videosOnly ? {} : { asAudio: true });
        } else if (stream) {
            openStream(stream, "");
        }
    }

    // "Share" on library items: the system's list of apps that take them.
    function shareMedia(list) {
        var urls = list.filter(function(media) { return !core.isStream(media.url); })
                       .map(function(media) { return media.url.toString(); });
        if (urls.length === 0)
            return;
        var request = { urls: urls, videos: list[0].hasPicture };
        if (shareLoader.status === Loader.Ready) {
            shareLoader.item.ask(request.urls, request.videos);
        } else {
            shareLoader.pending = request;
            shareLoader.active = true;
        }
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
        if (sharing)
            shareLoader.item.close();
        else if (gate.open)
            gate.close();
        else if (picker.open)
            picker.close();
        else if (page === "video" && videoPage)
            videoPage.back();
        else if (page === "audio" && audioPage)
            audioPage.back();
        else if (page === "diagnostics")
            page = "home";
        else if (page === "home" && tab === "video")
            return videoTab.back();
        else if (page === "home" && tab === "audio")
            return audioTab.back();
        else if (page === "home" && tab === "browse")
            return browseTab.back();
        else if (page === "home" && tab === "playlists")
            return playlistsTab.back();
        else if (page === "home" && tab === "more" && moreView !== "")
            moreView = "";
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
    //
    // The app hears that it was left in one of two ways. Frozen by the
    // system, as an app normally is, it is told "suspended" just before.
    // Kept running in the background (platform/BackgroundRunning.qml), it
    // is never suspended and only ever "inactive" [device], which it also
    // is for a moment under the system's panels; so there it counts as
    // left once it has been inactive for as long as a freeze takes to come.
    function _left() {
        if (page !== "video" || core.audioMode)
            return;
        // As the settings have it: on as audio, if it was playing, or paused.
        if (settingsStore.videoPlaysOnAsAudio && core.playing)
            toAudio();
        else
            core.pause();
    }

    Timer {
        id: leftCheck
        interval: 3000
        onTriggered: if (Qt.application.state !== Qt.ApplicationActive) shell._left()
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive) {
                leftCheck.stop();
                return;
            }
            core.saveNow();
            if (Qt.application.state === Qt.ApplicationSuspended)
                shell._left();
            else if (shell.backgroundRunning && shell.backgroundRunning.exempt)
                leftCheck.restart();
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
                onPlaylistRequested: shell.addToPlaylist(list)
                onShareRequested: shell.shareMedia(list)
            }
            AudioLibraryPage {
                id: audioTab
                anchors.fill: parent
                visible: shell.tab === "audio"
                library: shell.library
                store: playerStore
                overlay: home
                playingUrl: shell.audioActive ? core.url : ""
                onPlayRequested: shell.playList(list, index, options)
                onQueueRequested: shell.addToQueue(list, next)
                onPlaylistRequested: shell.addToPlaylist(list)
                onShareRequested: shell.shareMedia(list)
            }
            BrowsePage {
                id: browseTab
                anchors.fill: parent
                visible: shell.tab === "browse"
                library: shell.library
                store: playerStore
                overlay: home
                homePath: foldersLoader.status === Loader.Ready ? foldersLoader.item.home : ""
                playingUrl: shell.audioActive ? core.url : ""
                onPlayRequested: shell.playList(list, index, options)
                onPlaylistRequested: shell.addToPlaylist(list)
            }
            PlaylistsPage {
                id: playlistsTab
                anchors.fill: parent
                visible: shell.tab === "playlists"
                store: playerStore
                picturesReady: shell.library !== null
                overlay: home
                playingUrl: shell.audioActive ? core.url : ""
                onPlayRequested: shell.playList(list, index, options)
                onQueueRequested: shell.addToQueue(list, next)
            }
            MorePage {
                anchors.fill: parent
                visible: shell.tab === "more" && shell.moreView === ""
                streamsAllowed: core.streamsAllowed
                keepingHistory: core.keepHistory
                onStreamsRequested: shell.moreView = "streams"
                onSearchRequested: shell.openSearch()
                onSettingsRequested: shell.moreView = "settings"
                onHistoryRequested: shell.moreView = "history"
                onAboutRequested: shell.moreView = "about"
                onDiagnosticsRequested: shell.page = "diagnostics"
            }
            SearchPage {
                id: searchView
                anchors.fill: parent
                visible: shell.tab === "more" && shell.moreView === "search"
                library: shell.library
                store: playerStore
                overlay: home
                playingUrl: shell.audioActive ? core.url : ""
                onCloseRequested: shell.moreView = ""
                onPlayRequested: shell.playList(list, index, options)
                onQueueRequested: shell.addToQueue(list, next)
                onPlaylistRequested: shell.addToPlaylist(list)
                // A result that is a list is opened where it lives. The
                // search stays as it is behind the More tab, to come back to.
                onGroupRequested: {
                    shell.tab = "audio";
                    audioTab.openGroup(listKey, key);
                }
                onPlaylistOpenRequested: {
                    shell.tab = "playlists";
                    playlistsTab.openId = playlistId;
                }
            }
            HistoryPage {
                id: historyView
                anchors.fill: parent
                visible: shell.tab === "more" && shell.moreView === "history"
                store: playerStore
                overlay: home
                keeping: core.keepHistory
                playingUrl: core.loaded ? core.url : ""
                onCloseRequested: shell.moreView = ""
                onKeepRequested: core.setKeepHistory(on)
                onPlayRequested: shell.playList(list, index, options)
                onQueueRequested: shell.addToQueue(list, next)
                onPlaylistRequested: shell.addToPlaylist(list)
            }
            SettingsPage {
                id: settingsView
                anchors.fill: parent
                visible: shell.tab === "more" && shell.moreView === "settings"
                prefs: settingsStore
                store: playerStore
                overlay: home
                keepingHistory: core.keepHistory
                streamsAllowed: core.streamsAllowed
                background: shell.backgroundRunning
                onCloseRequested: shell.moreView = ""
                onKeepHistoryRequested: core.setKeepHistory(on)
                onStreamsRequested: shell.moreView = "streams"
            }
            AboutPage {
                anchors.fill: parent
                visible: shell.tab === "more" && shell.moreView === "about"
                onCloseRequested: shell.moreView = ""
            }
            StreamsPage {
                id: streamsView
                anchors.fill: parent
                visible: shell.tab === "more" && shell.moreView === "streams"
                store: playerStore
                overlay: home
                allowed: core.streamsAllowed
                playingUrl: core.loaded ? core.url : ""
                onCloseRequested: shell.moreView = ""
                onAllowRequested: shell.setStreamsAllowed(on)
                onOpenRequested: shell.openStream(address, title)
                onPlaylistRequested: shell.addToPlaylist([shell.streamMedia(address, title)])
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
        prefs: settingsStore
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
                prefs: settingsStore
                sleep: sleeper
                systemVolume: volumeLoader.status === Loader.Ready ? volumeLoader.item : null
                systemBrightness: brightnessLoader.status === Loader.Ready ? brightnessLoader.item : null
                onCollapseRequested: shell.page = "home"
                onStopRequested: shell.closePlayer()
                onVideoRequested: shell.toVideo()
                onPlaylistRequested: shell.addToPlaylist(list)
            }
        }
    }

    // "Add to playlist" is asked for from the lists and from the audio
    // player alike, so its sheet and dialog lie over both.
    PlaylistPicker {
        id: picker
        anchors.fill: parent
        anchors.bottomMargin: shell.keyboardHeight
        store: playerStore
        onDone: shell.say(message)
    }

    // The question before a stream, over whatever asked for one.
    StreamGate {
        id: gate
        anchors.fill: parent
        onAllowed: core.setStreamsAllowed(true)
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
