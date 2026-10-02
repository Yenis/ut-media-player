import QtQuick 2.12
import QtQuick.Window 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The app: the one Playback object, the store of resume points, and the pages.
 * Created by Main.qml only after the app identity is set.
 *
 * Phase 1: a list of videos, the video player, and a minimal "playing as
 * audio" page.
 */
FocusScope {
    id: shell
    focus: true

    property var appWindow: null

    // "home", "video", "audio" or "diagnostics"
    property string page: "home"

    readonly property alias playback: core
    readonly property alias videoPage: videoView
    readonly property var library: libraryLoader.status === Loader.Ready ? libraryLoader.item : null

    ResumeStore { id: resume }

    Playback {
        id: core
        store: resume
        // Nothing follows yet; a queue comes with Phase 2.
        onEnded: if (shell.page === "video" || shell.page === "audio") shell.page = "home"
    }

    // These only exist on Ubuntu Touch; anywhere else the Loader fails quietly.
    Loader { id: libraryLoader; source: "../platform/MediaLibrary.qml" }
    Loader {
        source: "../platform/ContentImport.qml"
        onLoaded: item.incoming.connect(shell.openUrl)
    }
    Loader {
        source: "../dev/Remote.qml"
        onLoaded: item.shell = shell
    }

    function openMedia(media) {
        core.open(media);
        if (media.hasPicture)
            videoView.reset();
        page = media.hasPicture ? "video" : "audio";
    }

    // A file from outside the list: another app, or a path.
    function openUrl(url) {
        var path = decodeURIComponent(url.toString().replace("file://", ""));
        var known = library ? library.lookup(path) : null;
        openMedia(known || { url: url.toString(), title: Format.baseName(url), duration: 0, hasPicture: true });
    }

    function openPath(path) {
        openUrl("file://" + path.split("/").map(encodeURIComponent).join("/"));
    }

    // "Play as audio" and back: the picture goes, the playback stays.
    function toAudio() {
        core.audioMode = true;
        page = "audio";
    }

    function toVideo() {
        core.audioMode = false;
        page = "video";
        core.play();
    }

    // Leaving a player: a video stops with its page.
    function closePlayer() {
        core.pause();
        core.audioMode = false;
        page = "home";
    }

    function back() {
        if (page === "video" && videoPage)
            videoPage.back();
        else if (page === "audio")
            closePlayer();
        else if (page === "diagnostics")
            page = "home";
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
        if ((event.key === Qt.Key_Back || event.key === Qt.Key_Escape) && page !== "home") {
            back();
            event.accepted = true;
        }
    }

    HomePage {
        anchors.fill: parent
        visible: shell.page === "home"
        library: shell.library
        store: resume
        onMediaChosen: shell.openMedia(media)
        onDiagnosticsRequested: shell.page = "diagnostics"
    }

    // Always there, shown or not: the backend only starts a video if its
    // picture has somewhere to go before playback begins, so the video surface
    // must exist before a file is opened. "Play as audio" hides it.
    VideoPlayerPage {
        id: videoView
        anchors.fill: parent
        visible: shell.page === "video"
        playback: core
        onCloseRequested: shell.closePlayer()
        onAudioRequested: shell.toAudio()
    }

    Loader {
        anchors.fill: parent
        active: shell.page === "audio"
        sourceComponent: Component {
            AudioModePage {
                playback: core
                onCloseRequested: shell.closePlayer()
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
