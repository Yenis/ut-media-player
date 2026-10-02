import QtQuick 2.12
import QtQuick.Window 2.12
import QtMultimedia 5.12
import Gem 1.0
import "../js/AppInfo.js" as AppInfo

/*
 * Phase 0 spike (docs/PLAN.md): a diagnostics page that answers the S1-S16
 * questions on a device. Throwaway - Phase 1 replaces it with the player.
 *
 * Every finding is written to the app log as a line starting with "SPIKE", so
 * the results can be read from the device journal as well as on screen.
 * The automatic run needs the files from the test set in
 * ~/Videos/gemplayer-test and ~/Music/gemplayer-test.
 */
FocusScope {
    id: spike
    focus: true

    property var appWindow: null
    property int tab: 0

    readonly property string home: files.status === Loader.Ready ? files.item.home : "/home/phablet"
    readonly property string videoDir: home + "/Videos/gemplayer-test"
    readonly property string audioDir: home + "/Music/gemplayer-test"

    // The player the manual controls act on: the one with a picture, or the
    // one without (see "Play as audio").
    property bool audioMode: false
    readonly property var active: audioMode ? audioPlayer : player

    property int positionUpdates: 0
    property string lastError: ""

    // ---- log ---------------------------------------------------------------

    function log(tag, message) {
        var line = tag + " " + message;
        console.log("SPIKE " + line);
        logModel.append({ line: line });
        if (logModel.count > 500)
            logModel.remove(0);
        logView.positionViewAtEnd();
    }

    function result(id, message) {
        log("RESULT " + id, message);
    }

    ListModel { id: logModel }

    // ---- names -------------------------------------------------------------

    function statusName(s) {
        var names = {};
        names[MediaPlayer.NoMedia] = "NoMedia";
        names[MediaPlayer.Loading] = "Loading";
        names[MediaPlayer.Loaded] = "Loaded";
        names[MediaPlayer.Buffering] = "Buffering";
        names[MediaPlayer.Stalled] = "Stalled";
        names[MediaPlayer.Buffered] = "Buffered";
        names[MediaPlayer.EndOfMedia] = "EndOfMedia";
        names[MediaPlayer.InvalidMedia] = "InvalidMedia";
        names[MediaPlayer.UnknownStatus] = "UnknownStatus";
        return names[s] !== undefined ? names[s] : "status" + s;
    }

    function stateName(s) {
        return s === MediaPlayer.PlayingState ? "playing"
             : s === MediaPlayer.PausedState ? "paused" : "stopped";
    }

    function appStateName(s) {
        return s === Qt.ApplicationActive ? "active"
             : s === Qt.ApplicationInactive ? "inactive"
             : s === Qt.ApplicationHidden ? "hidden" : "suspended";
    }

    function clock(ms) {
        var s = Math.floor(Math.max(0, ms) / 1000);
        var m = Math.floor(s / 60);
        s = s % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ---- probes that only exist on Ubuntu Touch ------------------------------

    Loader { id: store; source: "StoreProbe.qml" }
    Loader { id: files; source: "FilesProbe.qml" }
    Loader { id: library; source: "LibraryProbe.qml" }
    Loader { id: screenProbe; source: "ScreenProbe.qml" }
    Loader {
        id: content
        source: "ContentProbe.qml"
        onLoaded: item.incoming.connect(function(how, url) {
            spike.result("S12", "received via " + how + ": " + url);
        })
    }

    // ---- players -------------------------------------------------------------

    MediaPlayer {
        id: player
        notifyInterval: 100
        onError: {
            spike.lastError = error + " " + errorString;
            spike.log("PLAYER", "error " + error + " " + errorString);
        }
        onStatusChanged: spike.log("PLAYER", "status " + spike.statusName(status))
        onPlaybackStateChanged: spike.log("PLAYER", "state " + spike.stateName(playbackState))
        onPositionChanged: spike.positionUpdates++
    }

    // No VideoOutput is ever attached to this one: the "play as audio" side.
    MediaPlayer {
        id: audioPlayer
        notifyInterval: 100
        onError: {
            spike.lastError = error + " " + errorString;
            spike.log("AUDIO", "error " + error + " " + errorString);
        }
        onStatusChanged: spike.log("AUDIO", "status " + spike.statusName(status))
        onPlaybackStateChanged: spike.log("AUDIO", "state " + spike.stateName(playbackState))
    }

    // A queue, as the stock Music app builds it.
    MediaPlayer {
        id: queuePlayer
        playlist: Playlist { id: queue }
        onError: spike.log("QUEUE", "error " + error + " " + errorString)
        onPlaybackStateChanged: spike.log("QUEUE", "state " + spike.stateName(playbackState))
    }
    Connections {
        target: queue
        onCurrentIndexChanged: spike.log("QUEUE", "index " + queue.currentIndex + " " + queue.currentItemSource)
    }

    // What the journal shows while the app is in the background or the screen
    // is locked: if these lines stop, the app was suspended; if the position
    // kept moving across the gap, playback carried on without it.
    Timer {
        interval: 2000
        repeat: true
        running: player.playbackState === MediaPlayer.PlayingState
                 || audioPlayer.playbackState === MediaPlayer.PlayingState
                 || queuePlayer.playbackState === MediaPlayer.PlayingState
        onTriggered: spike.log("HB", "wall=" + Date.now()
                               + " video=" + spike.stateName(player.playbackState) + "@" + player.position
                               + " audio=" + spike.stateName(audioPlayer.playbackState) + "@" + audioPlayer.position
                               + " queue=" + spike.stateName(queuePlayer.playbackState) + "#" + queue.currentIndex + "@" + queuePlayer.position
                               + " app=" + spike.appStateName(Qt.application.state))
    }

    Connections {
        target: Qt.application
        onStateChanged: spike.log("APP", "state " + spike.appStateName(Qt.application.state)
                                  + " wall=" + Date.now()
                                  + " video=" + spike.stateName(player.playbackState) + "@" + player.position
                                  + " audio=" + spike.stateName(audioPlayer.playbackState) + "@" + audioPlayer.position
                                  + " queue=" + spike.stateName(queuePlayer.playbackState) + "@" + queuePlayer.position)
    }

    Screen.orientationUpdateMask: Qt.PortraitOrientation | Qt.LandscapeOrientation
                                  | Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation
    Screen.onOrientationChanged: log("SCREEN", "orientation " + Screen.orientation
                                     + " primary " + Screen.primaryOrientation
                                     + " window " + width + "x" + height)

    // ---- manual actions --------------------------------------------------------

    function open(path) {
        audioMode = false;
        audioPlayer.stop();
        lastError = "";
        player.stop();
        player.source = "file://" + path;
        player.play();
        log("MANUAL", "open " + path);
    }

    // S6: hand the playing file to the player that has no picture, at the same
    // position, and time how long the sound is gone. And the way back.
    function switchMode(toAudio) {
        var from = toAudio ? player : audioPlayer;
        var to = toAudio ? audioPlayer : player;
        if (from.source.toString() === "")
            return;
        var at = from.position;
        var t0 = Date.now();
        from.stop();
        to.source = from.source;
        to.play();
        to.seek(at);
        audioMode = toAudio;
        log("S6", (toAudio ? "to audio" : "to video") + " at " + at + " ms");
        waitFor(function() { return to.playbackState === MediaPlayer.PlayingState && to.position > at + 150; },
                15000, function(ok) {
            result("S6", (toAudio ? "video->audio" : "audio->video") + " gap "
                   + (ok ? (Date.now() - t0) + " ms" : "did not resume")
                   + ", hasVideo=" + to.hasVideo + ", position " + to.position);
        });
    }

    function playLibraryQueue() {
        if (library.status !== Loader.Ready)
            return;
        var songs = library.item.firstSongs(4);
        queuePlayer.stop();
        queue.clear();
        for (var i = 0; i < songs.length; i++)
            queue.addItem(Qt.resolvedUrl("file://" + songs[i].filename));
        queue.currentIndex = 0;
        queuePlayer.play();
        log("QUEUE", "playing " + queue.itemCount + " library songs");
    }

    // ---- automatic run ---------------------------------------------------------

    property bool running: false
    property int stepIndex: 0
    property string stepName: ""

    Timer {
        id: waitTimer
        property var callback: null
        onTriggered: {
            var f = callback;
            callback = null;
            if (f)
                f();
        }
    }

    // One pending wait at a time; the automatic run is strictly sequential.
    function wait(ms, callback) {
        waitTimer.callback = callback;
        waitTimer.interval = ms;
        waitTimer.restart();
    }

    function waitFor(condition, timeoutMs, callback) {
        var t0 = Date.now();
        function tick() {
            var ok = false;
            try { ok = condition(); } catch (e) { ok = false; }
            if (ok)
                callback(true, Date.now() - t0);
            else if (Date.now() - t0 > timeoutMs)
                callback(false, Date.now() - t0);
            else
                wait(100, tick);
        }
        tick();
    }

    function steps() {
        return [
            ["modules", stepModules], ["storage", stepStorage], ["files", stepFiles],
            ["own folder", stepOwnFolder],
            ["srt", stepSrt], ["library", stepLibrary], ["thumbnails", stepThumbnails],
            ["formats", stepFormats], ["seek", stepSeek], ["rate", stepRate],
            ["metadata", stepMetadata], ["roles", stepRoles], ["queue", stepQueue],
            ["streams", stepStreams], ["fullscreen", stepFullscreen]
        ];
    }

    function startAuto() {
        if (running)
            return;
        running = true;
        stepIndex = 0;
        // The run must not be cut short by the screen timeout.
        if (screenProbe.status === Loader.Ready)
            screenProbe.item.keepOn = true;
        log("AUTO", "start, version " + AppInfo.VERSION + ", grid unit " + Theme.gu
            + ", window " + width + "x" + height + ", screen " + Screen.width + "x" + Screen.height
            + " dpr " + Screen.devicePixelRatio);
        next();
    }

    function next() {
        var list = steps();
        if (stepIndex >= list.length) {
            running = false;
            stepName = "";
            player.stop();
            if (screenProbe.status === Loader.Ready)
                screenProbe.item.keepOn = false;
            log("AUTO", "done");
            return;
        }
        var entry = list[stepIndex++];
        stepName = entry[0];
        log("AUTO", "step " + stepName);
        try {
            entry[1]();
        } catch (e) {
            log("AUTO", "step " + stepName + " threw: " + e);
            next();
        }
    }

    // S15: which QML modules does the device offer to a QML-only click?
    function stepModules() {
        var modules = ["QtMultimedia 5.12", "QtQuick.LocalStorage 2.0", "Qt.labs.settings 1.0",
                       "Qt.labs.folderlistmodel 2.2", "Qt.labs.platform 1.0", "QtGraphicalEffects 1.0",
                       "QtQuick.Controls 2.2", "QtSystemInfo 5.0", "QtSensors 5.0", "QtFeedback 5.0",
                       "MediaScanner 0.1", "Lomiri.Thumbnailer 0.1", "Lomiri.Content 1.3",
                       "Lomiri.Components 1.3", "org.nemomobile.mpris 1.0"];
        var missing = [];
        for (var i = 0; i < modules.length; i++) {
            try {
                var o = Qt.createQmlObject("import QtQuick 2.12\nimport " + modules[i] + "\nQtObject {}", spike, "probe");
                o.destroy();
            } catch (e) {
                missing.push(modules[i]);
            }
        }
        result("S15", "modules missing: " + (missing.length ? missing.join(", ") : "none")
               + " (of " + modules.length + ")");
        var probes = [["store", store], ["files", files], ["library", library],
                      ["screen", screenProbe], ["content", content]];
        for (var j = 0; j < probes.length; j++) {
            if (probes[j][1].status !== Loader.Ready)
                result("S15", "probe " + probes[j][0] + " failed to load");
        }
        next();
    }

    function stepStorage() {
        if (store.status === Loader.Ready) {
            result("store", "settings launch counter " + store.item.bumpLaunches()
                   + ", database rows " + store.item.bumpDatabase());
        }
        next();
    }

    // S2: which folders can be listed directly.
    function stepFiles() {
        if (files.status !== Loader.Ready) {
            next();
            return;
        }
        var dirs = [videoDir, audioDir, home + "/Videos", home + "/Music", home + "/Documents",
                    home + "/Downloads", home, "/media/phablet", "/media"];
        var i = 0;
        function one() {
            if (i >= dirs.length) {
                next();
                return;
            }
            var dir = dirs[i++];
            files.item.list(dir);
            wait(700, function() {
                var names = files.item.names();
                result("S2", dir + ": " + names.length + " entries"
                       + (names.length ? " (" + names.slice(0, 4).join(", ") + (names.length > 4 ? ", ..." : "") + ")" : ""));
                one();
            });
        }
        one();
    }

    // S2: a file inside the app's own cache folder, which is where Content Hub
    // puts what other apps hand over.
    function stepOwnFolder() {
        var path = (files.status === Loader.Ready ? files.item.cache : home + "/.cache")
                   + "/gemplayer.yenis/spike/sidecar.mp4";
        playOne("file://" + path, 2, function(r) {
            result("S2", "own cache folder, " + path + ": " + r.text);
            next();
        });
    }

    // S10: read a subtitle file beside a video.
    function stepSrt() {
        var request = new XMLHttpRequest();
        var finished = false;
        function finish(message) {
            if (finished)
                return;
            finished = true;
            result("S10", message);
            next();
        }
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            var text = request.responseText || "";
            finish("read " + text.length + " characters, status " + request.status
                   + (text.length ? ", starts: " + text.substring(0, 60).replace(/\n/g, " / ") : ""));
        };
        try {
            request.open("GET", "file://" + videoDir + "/sidecar.srt");
            request.send();
        } catch (e) {
            finish("request threw: " + e);
            return;
        }
        wait(4000, function() { finish("no answer in 4 s"); });
    }

    // S3: the media library.
    function stepLibrary() {
        if (library.status !== Loader.Ready) {
            result("S3", "library probe not loaded");
            next();
            return;
        }
        waitFor(function() { return library.item.ready; }, 8000, function(ok, ms) {
            var c = library.item.counts();
            result("S3", "models " + (ok ? "ready in " + ms + " ms" : "NOT ready after " + ms + " ms")
                   + ": songs " + c.songs + ", albums " + c.albums + ", artists " + c.artists + ", genres " + c.genres);
            var all = library.item.videos("");
            result("S3", "video query \"\": " + all.length + " results");
            for (var i = 0; i < Math.min(all.length, 12); i++)
                log("S3", "video " + all[i].filename + " " + all[i].width + "x" + all[i].height
                    + " " + all[i].duration + " s, art " + all[i].art);
            result("S3", "video query \"sidecar\": " + library.item.videos("sidecar").length + " results");
            var songs = library.item.firstSongs(2);
            for (var j = 0; j < songs.length; j++)
                log("S3", "song " + songs[j].title + " / " + songs[j].author + " / " + songs[j].album
                    + " " + songs[j].duration + " s, art " + songs[j].art);
            next();
        });
    }

    // S4: thumbnails and album art.
    function stepThumbnails() {
        thumbVideo.source = "";
        thumbAlbum.source = "";
        thumbVideo.source = "image://thumbnailer/file://" + videoDir + "/h264-1080p30.mp4";
        var album = library.status === Loader.Ready ? library.item.firstAlbum() : null;
        if (album)
            thumbAlbum.source = album.art;
        waitFor(function() {
            return thumbVideo.status !== Image.Loading && thumbAlbum.status !== Image.Loading;
        }, 10000, function() {
            result("S4", "video thumbnail " + imageState(thumbVideo));
            result("S4", "album art " + (album ? imageState(thumbAlbum) + " for " + album.art : "no album in the library"));
            next();
        });
    }

    function imageState(image) {
        return image.status === Image.Ready ? "ready " + image.implicitWidth + "x" + image.implicitHeight
             : image.status === Image.Error ? "ERROR"
             : image.status === Image.Loading ? "still loading" : "empty";
    }

    // Plays one source for a few seconds and reports what the backend did.
    function playOne(url, seconds, callback) {
        player.stop();
        wait(400, function() {
            lastError = "";
            player.source = url;
            player.play();
            waitFor(function() {
                return lastError !== "" || (player.playbackState === MediaPlayer.PlayingState && player.position > 200);
            }, 15000, function(ok, startMs) {
                if (!ok || lastError !== "") {
                    callback({ ok: false, text: "FAILED after " + startMs + " ms, status "
                                                + statusName(player.status) + ", error " + (lastError || "none") });
                    return;
                }
                var p1 = player.position, w1 = Date.now();
                positionUpdates = 0;
                wait(seconds * 1000, function() {
                    var p2 = player.position, w2 = Date.now();
                    var size = player.metaData.resolution;
                    callback({ ok: true, text: "plays, started in " + startMs + " ms"
                        + ", speed " + ((p2 - p1) / (w2 - w1)).toFixed(2)
                        + ", " + (positionUpdates / ((w2 - w1) / 1000)).toFixed(1) + " position updates/s"
                        + ", duration " + player.duration + " ms"
                        + ", video " + player.hasVideo + ", audio " + player.hasAudio
                        + ", seekable " + player.seekable
                        + ", size " + (size ? size.width + "x" + size.height : "unknown")
                        + ", status " + statusName(player.status) });
                });
            });
        });
    }

    // S1, S14: every file of the test set.
    function stepFormats() {
        var list = [
            videoDir + "/h264-1080p30.mp4", videoDir + "/h264-opus-720p.mkv", videoDir + "/hevc-1080p.mp4",
            videoDir + "/vp9-720p.webm", videoDir + "/av1-720p.mp4", videoDir + "/portrait-1080x1920.mp4",
            audioDir + "/test-1.mp3", audioDir + "/test-2.flac", audioDir + "/test-3.opus",
            audioDir + "/test-4.ogg", audioDir + "/test-5.m4a"
        ];
        var i = 0;
        function one() {
            if (i >= list.length) {
                next();
                return;
            }
            var path = list[i++];
            playOne("file://" + path, 3, function(r) {
                result("S14", path.substring(path.lastIndexOf("/") + 1) + ": " + r.text);
                one();
            });
        }
        one();
    }

    // S6b: how long a seek takes until the picture and sound move again.
    function stepSeek() {
        playOne("file://" + videoDir + "/sidecar.mp4", 1, function(r) {
            if (!r.ok) {
                result("S6b", "could not play the seek test file: " + r.text);
                next();
                return;
            }
            var targets = [30000, 10000, 50000, 5000];
            var i = 0;
            function one() {
                if (i >= targets.length) {
                    seekPaused();
                    return;
                }
                var target = targets[i++];
                var t0 = Date.now();
                player.seek(target);
                waitFor(function() { return Math.abs(player.position - target) < 2500; }, 8000, function(landed, landedMs) {
                    var at = player.position;
                    waitFor(function() { return player.position > at + 250; }, 8000, function(moving) {
                        result("S6b", "seek to " + target + " ms: position there after "
                               + (landed ? landedMs + " ms" : "NEVER") + " (reported " + at + ")"
                               + ", playing on after " + (moving ? (Date.now() - t0) + " ms" : "NEVER"));
                        one();
                    });
                });
            }
            function seekPaused() {
                player.pause();
                wait(500, function() {
                    player.seek(40000);
                    wait(1500, function() {
                        result("S6b", "seek while paused to 40000: position " + player.position
                               + ", state " + stateName(player.playbackState));
                        next();
                    });
                });
            }
            one();
        });
    }

    // S7: does the playback rate do anything? Also volume read-back.
    function stepRate() {
        playOne("file://" + videoDir + "/sidecar.mp4", 1, function(r) {
            if (!r.ok) {
                result("S7", "could not play the rate test file: " + r.text);
                next();
                return;
            }
            player.playbackRate = 2.0;
            wait(500, function() {
                var p1 = player.position, w1 = Date.now();
                wait(3000, function() {
                    var measured = (player.position - p1) / (Date.now() - w1);
                    result("S7", "asked for 2.0, property reads " + player.playbackRate
                           + ", measured speed " + measured.toFixed(2));
                    player.playbackRate = 1.0;
                    player.volume = 0.3;
                    wait(300, function() {
                        result("volume", "asked for 0.3, property reads " + player.volume.toFixed(2));
                        player.volume = 1.0;
                        next();
                    });
                });
            });
        });
    }

    // S16: what the backend tells us about tracks, subtitles and chapters, and
    // whether a video frame can be captured.
    function stepMetadata() {
        playOne("file://" + videoDir + "/multi-track.mkv", 2, function(r) {
            result("S16", "multi-track.mkv: " + r.text);
            var keys = ["title", "subTitle", "author", "comment", "description", "category", "genre",
                        "year", "date", "language", "publisher", "size", "mediaType", "duration",
                        "audioBitRate", "audioCodec", "channelCount", "sampleRate", "albumTitle",
                        "albumArtist", "trackNumber", "trackCount", "resolution", "pixelAspectRatio",
                        "videoFrameRate", "videoBitRate", "videoCodec", "chapterNumber", "coverArtUrlLarge",
                        "posterUrl"];
            var found = [];
            for (var i = 0; i < keys.length; i++) {
                var value = player.metaData[keys[i]];
                if (value !== undefined && value !== null && value.toString() !== "")
                    found.push(keys[i] + "=" + value);
            }
            result("S16", "metaData: " + (found.length ? found.join("; ") : "nothing"));
            var target = (files.status === Loader.Ready ? files.item.cache : home + "/.cache")
                         + "/gemplayer.yenis/spike-grab.png";
            var grabbing = videoOut.grabToImage(function(grab) {
                var saved = false;
                try { saved = grab.saveToFile(target); } catch (e) { saved = false; }
                result("S16", "grabToImage: " + (saved ? "saved " + target : "could not save to " + target));
                next();
            });
            if (!grabbing) {
                result("S16", "grabToImage refused");
                next();
            }
        });
    }

    // Audio role: what can be set, and does it read back.
    function stepRoles() {
        player.stop();
        var supported = "n/a";
        try { supported = JSON.stringify(player.supportedAudioRoles()); } catch (e) { supported = "threw " + e; }
        var before = player.audioRole;
        player.audioRole = MediaPlayer.VideoRole;
        var asVideo = player.audioRole;
        player.audioRole = MediaPlayer.MusicRole;
        result("role", "supported " + supported + ", default " + before
               + ", after VideoRole(" + MediaPlayer.VideoRole + ") reads " + asVideo
               + ", after MusicRole(" + MediaPlayer.MusicRole + ") reads " + player.audioRole);
        next();
    }

    // The play queue: Playlist over media-hub.
    function stepQueue() {
        queuePlayer.stop();
        queue.clear();
        queue.addItem("file://" + audioDir + "/test-1.mp3");
        queue.addItem("file://" + audioDir + "/test-2.flac");
        queue.addItem("file://" + audioDir + "/test-3.opus");
        wait(800, function() {
            var count = queue.itemCount;
            queue.currentIndex = 0;
            queuePlayer.play();
            waitFor(function() { return queuePlayer.position > 300; }, 10000, function(ok) {
                var first = queue.currentIndex;
                queue.next();
                wait(2500, function() {
                    var second = queue.currentIndex;
                    var movedOn = queuePlayer.playbackState === MediaPlayer.PlayingState;
                    queue.playbackMode = Playlist.CurrentItemInLoop;
                    var loopMode = queue.playbackMode;
                    queue.playbackMode = Playlist.Random;
                    var randomMode = queue.playbackMode;
                    queue.playbackMode = Playlist.Sequential;
                    result("queue", "items " + count + ", first plays " + ok + " at index " + first
                           + ", after next() index " + second + " playing " + movedOn
                           + ", modes read back loop=" + (loopMode === Playlist.CurrentItemInLoop)
                           + " random=" + (randomMode === Playlist.Random));
                    queuePlayer.stop();
                    next();
                });
            });
        });
    }

    // S13: network streams.
    function stepStreams() {
        var list = [
            ["https mp4", "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"],
            // A missing file: what does the backend report for a 404?
            ["https 404", "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4"],
            ["HLS", "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"]
        ];
        var i = 0;
        function one() {
            if (i >= list.length) {
                next();
                return;
            }
            var entry = list[i++];
            playOne(entry[1], 4, function(r) {
                result("S13", entry[0] + ": " + r.text);
                one();
            });
        }
        one();
    }

    // S8: fullscreen over the panel.
    function stepFullscreen() {
        player.stop();
        if (!appWindow) {
            next();
            return;
        }
        var before = appWindow.visibility;
        var sizeBefore = appWindow.width + "x" + appWindow.height;
        appWindow.visibility = Window.FullScreen;
        wait(2000, function() {
            result("S8", "fullscreen: window " + sizeBefore + " (visibility " + before + ") -> "
                   + appWindow.width + "x" + appWindow.height + " (visibility " + appWindow.visibility + ")"
                   + ", screen " + Screen.width + "x" + Screen.height);
            appWindow.visibility = before;
            wait(1500, function() {
                log("S8", "restored: window " + appWindow.width + "x" + appWindow.height
                    + " (visibility " + appWindow.visibility + ")");
                next();
            });
        });
    }

    Component.onCompleted: {
        log("APP", "spike " + AppInfo.VERSION + " started");
        wait(2500, function() {
            if (store.status !== Loader.Ready || store.item.autoRun)
                startAuto();
        });
    }

    // ---- page --------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.u(6)

        Text {
            anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
            text: "GemPlayer spike " + AppInfo.VERSION
            color: Theme.text
            font.pixelSize: Theme.fontL
            font.bold: true
        }
        Text {
            anchors { right: parent.right; rightMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
            text: spike.running ? "running: " + spike.stepName : ""
            color: Theme.topaz
            font.pixelSize: Theme.fontS
        }
    }

    // Always on screen, whatever the tab: grabbing a frame needs it visible.
    Rectangle {
        id: stage
        anchors { left: parent.left; right: parent.right; top: header.bottom }
        height: Math.min(width * 9 / 16, parent.height * 0.32)
        color: "black"

        VideoOutput {
            id: videoOut
            anchors.fill: parent
            source: player
            visible: !spike.audioMode
        }
        Text {
            anchors.centerIn: parent
            visible: spike.audioMode
            text: "Playing as audio"
            color: Theme.textDim
            font.pixelSize: Theme.fontM
        }
        Text {
            anchors { left: parent.left; bottom: parent.bottom; margins: Theme.u(1) }
            text: spike.stateName(spike.active.playbackState) + "  "
                  + spike.clock(spike.active.position) + " / " + spike.clock(spike.active.duration)
                  + "  " + spike.statusName(spike.active.status)
            color: Theme.text
            style: Text.Outline
            styleColor: "black"
            font.pixelSize: Theme.fontS
        }
    }

    SegmentedChoice {
        id: tabs
        anchors { left: parent.left; right: parent.right; top: stage.bottom; margins: Theme.u(1) }
        options: ["Auto", "Player", "Library", "System"]
        currentIndex: spike.tab
        onChosen: spike.tab = index
    }

    Item {
        id: pages
        anchors { left: parent.left; right: parent.right; top: tabs.bottom; bottom: parent.bottom; topMargin: Theme.u(1) }

        // ---- Auto ----
        Item {
            anchors.fill: parent
            visible: spike.tab === 0

            Row {
                id: autoBar
                anchors { left: parent.left; leftMargin: Theme.u(2); top: parent.top }
                spacing: Theme.u(1.5)

                TextButton {
                    text: spike.running ? "Running..." : "Run automatic tests"
                    enabled: !spike.running
                    onClicked: spike.startAuto()
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "on launch"
                    color: Theme.textDim
                    font.pixelSize: Theme.fontS
                }
                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: store.status === Loader.Ready && store.item.autoRun
                    onToggled: if (store.status === Loader.Ready) store.item.setAutoRun(checked)
                }
            }

            ListView {
                id: logView
                anchors { left: parent.left; right: parent.right; top: autoBar.bottom; bottom: parent.bottom
                          margins: Theme.u(1); leftMargin: Theme.u(2) }
                clip: true
                model: logModel
                delegate: Text {
                    width: logView.width
                    text: line
                    color: line.indexOf("RESULT") === 0 ? Theme.text : Theme.textDim
                    font.pixelSize: Theme.fontXS
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // ---- Player ----
        Flickable {
            anchors.fill: parent
            visible: spike.tab === 1
            contentHeight: playerColumn.height + Theme.u(4)
            clip: true

            Column {
                id: playerColumn
                anchors { left: parent.left; right: parent.right; margins: Theme.u(2) }
                spacing: Theme.u(1.2)

                Flow {
                    width: parent.width
                    spacing: Theme.u(1)
                    TextButton {
                        text: spike.active.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play"
                        onClicked: spike.active.playbackState === MediaPlayer.PlayingState ? spike.active.pause() : spike.active.play()
                    }
                    TextButton { text: "-10 s"; onClicked: spike.active.seek(Math.max(0, spike.active.position - 10000)) }
                    TextButton { text: "+10 s"; onClicked: spike.active.seek(spike.active.position + 10000) }
                    TextButton { text: "Stop"; tone: Theme.ruby; onClicked: spike.active.stop() }
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u(1)
                    TextButton {
                        text: spike.audioMode ? "Play as video" : "Play as audio"
                        tone: Theme.sapphire
                        onClicked: spike.switchMode(!spike.audioMode)
                    }
                    TextButton {
                        text: screenProbe.status === Loader.Ready && screenProbe.item.keepOn ? "Screen: kept on" : "Screen: normal"
                        tone: Theme.sapphire
                        onClicked: if (screenProbe.status === Loader.Ready) {
                            screenProbe.item.keepOn = !screenProbe.item.keepOn;
                            spike.log("S8", "keep display on = " + screenProbe.item.keepOn);
                        }
                    }
                    TextButton {
                        text: "Fullscreen"
                        tone: Theme.sapphire
                        onClicked: if (spike.appWindow) {
                            spike.appWindow.visibility = spike.appWindow.visibility === Window.FullScreen
                                ? Window.AutomaticVisibility : Window.FullScreen;
                        }
                    }
                }

                SectionLabel { text: "Test set" }
                Repeater {
                    model: ["h264-1080p30.mp4", "long-35min.mp4", "multi-track.mkv", "sidecar.mp4",
                            "h264-opus-720p.mkv", "hevc-1080p.mp4", "vp9-720p.webm", "av1-720p.mp4",
                            "portrait-1080x1920.mp4"]
                    delegate: TextButton {
                        width: playerColumn.width
                        text: modelData
                        tone: Theme.diamond
                        onClicked: spike.open(spike.videoDir + "/" + modelData)
                    }
                }
                Repeater {
                    model: ["test-1.mp3", "test-2.flac", "test-3.opus", "test-4.ogg", "test-5.m4a"]
                    delegate: TextButton {
                        width: playerColumn.width
                        text: modelData
                        tone: Theme.amethyst
                        onClicked: spike.open(spike.audioDir + "/" + modelData)
                    }
                }
            }
        }

        // ---- Library ----
        Flickable {
            anchors.fill: parent
            visible: spike.tab === 2
            contentHeight: libraryColumn.height + Theme.u(4)
            clip: true

            Column {
                id: libraryColumn
                anchors { left: parent.left; right: parent.right; margins: Theme.u(2) }
                spacing: Theme.u(1.2)

                TextButton {
                    text: "Play a queue of 4 library songs"
                    onClicked: spike.playLibraryQueue()
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u(1)
                    TextButton { text: "Previous"; onClicked: queue.previous() }
                    TextButton { text: "Next"; onClicked: queue.next() }
                    TextButton {
                        text: queuePlayer.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play"
                        onClicked: queuePlayer.playbackState === MediaPlayer.PlayingState ? queuePlayer.pause() : queuePlayer.play()
                    }
                    TextButton { text: "Stop"; tone: Theme.ruby; onClicked: queuePlayer.stop() }
                }
                Text {
                    width: parent.width
                    text: "Queue: " + spike.stateName(queuePlayer.playbackState) + ", track " + (queue.currentIndex + 1)
                          + " of " + queue.itemCount + ", " + spike.clock(queuePlayer.position)
                    color: Theme.textDim
                    font.pixelSize: Theme.fontS
                }

                SectionLabel { text: "Thumbnail and album art (S4)" }
                Row {
                    spacing: Theme.u(2)
                    Image {
                        id: thumbVideo
                        width: Theme.u(16); height: Theme.u(16)
                        sourceSize: Qt.size(256, 256)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                    }
                    Image {
                        id: thumbAlbum
                        width: Theme.u(16); height: Theme.u(16)
                        sourceSize: Qt.size(256, 256)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                    }
                }
            }
        }

        // ---- System ----
        Flickable {
            anchors.fill: parent
            visible: spike.tab === 3
            contentHeight: systemColumn.height + Theme.u(4)
            clip: true

            Column {
                id: systemColumn
                anchors { left: parent.left; right: parent.right; margins: Theme.u(2) }
                spacing: Theme.u(1.2)

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: Theme.textDim
                    font.pixelSize: Theme.fontS
                    text: "App " + spike.appStateName(Qt.application.state)
                          + "\nWindow " + spike.width + "x" + spike.height
                          + (spike.appWindow ? ", visibility " + spike.appWindow.visibility
                                               + ", content orientation " + spike.appWindow.contentOrientation : "")
                          + "\nScreen " + Screen.width + "x" + Screen.height
                          + ", orientation " + Screen.orientation + ", primary " + Screen.primaryOrientation
                }

                SectionLabel { text: "Orientation (S9)" }
                Flow {
                    width: parent.width
                    spacing: Theme.u(1)
                    Repeater {
                        model: [["Primary", Qt.PrimaryOrientation], ["Portrait", Qt.PortraitOrientation],
                                ["Landscape", Qt.LandscapeOrientation], ["Inverted landscape", Qt.InvertedLandscapeOrientation]]
                        delegate: TextButton {
                            text: modelData[0]
                            tone: Theme.sapphire
                            onClicked: if (spike.appWindow) {
                                spike.appWindow.contentOrientation = modelData[1];
                                spike.log("S9", "contentOrientation set to " + modelData[0] + ", reads "
                                          + spike.appWindow.contentOrientation);
                            }
                        }
                    }
                }
            }
        }
    }
}
