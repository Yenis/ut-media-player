import QtQuick 2.12
import QtMultimedia 5.12
import Gem 1.0

/*
 * All playback goes through this one object, and through its one MediaPlayer.
 * The system backend (media-hub) misbehaves with a second player in the same
 * app: see docs/TESTING.md.
 *
 * Playback runs in media-hub, not in this process, so it carries on while the
 * app is suspended. That is what makes background audio and "play as audio"
 * work, and it is why a video has to be paused on purpose when the app is
 * left (AppShell does that).
 *
 * Backend quirks this object hides (docs/TESTING.md, "Other observations"):
 *  - position is a large negative number while nothing is loaded;
 *  - a seek lands on the keyframe before its target, up to seconds early, and
 *    takes 0.4 to 1.5 s; a seek before playback has started is ignored;
 *  - after stop(), play() on the same source does not play, so this object
 *    never stops: it pauses;
 *  - hasAudio and metaData are unreliable, and `seekable` changes without a
 *    signal.
 */
Item {
    id: playback

    property var store: null            // PlayerStore

    // What is loaded.
    property string url: ""
    property string title: ""
    property int libraryDuration: 0     // ms, from the media library, until the backend knows
    property bool libraryHasPicture: false

    // "Play as audio": the same playback, without its picture.
    property bool audioMode: false

    property string error: ""

    // A-B repeat: -1 is unset. With both set, playback loops between them.
    property int abStart: -1
    property int abEnd: -1

    // From opening a file until it actually plays.
    readonly property bool starting: _awaitingStart && error === ""

    readonly property alias player: mediaPlayer
    readonly property bool loaded: url !== ""
    readonly property bool playing: mediaPlayer.playbackState === MediaPlayer.PlayingState
    readonly property bool hasPicture: libraryHasPicture || mediaPlayer.hasVideo
    // The backend never announces that a file became seekable, so a binding
    // on its flag stays false. A known length is the practical test; the flag
    // itself is read at the moment of seeking.
    readonly property bool seekable: duration > 0
    // Copied from the player by its change signal: reading the backend's
    // duration inside a binding makes it emit, which looks like a binding loop.
    property int playerDuration: 0
    readonly property int duration: playerDuration > 0 ? playerDuration : libraryDuration

    // While a seek is on its way the target is shown, not the old position.
    readonly property int position: _seekTarget >= 0 ? _seekTarget
                                                     : Math.max(0, Math.min(mediaPlayer.position, duration > 0 ? duration : mediaPlayer.position))

    signal ended()

    property int _seekTarget: -1
    property int _lastPosition: 0
    property int _pendingStart: 0       // where to seek once playback has started
    property bool _awaitingStart: false

    // media: { url, title, duration (ms), hasPicture }
    function open(media) {
        saveNow();
        url = media.url.toString();
        title = media.title || "";
        libraryDuration = media.duration || 0;
        libraryHasPicture = !!media.hasPicture;
        playerDuration = 0;
        audioMode = false;
        error = "";
        abStart = -1;
        abEnd = -1;
        _seekTarget = -1;
        _pendingStart = store ? store.resumePoint(url) : 0;
        _awaitingStart = true;
        if (mediaPlayer.source.toString() !== url)
            mediaPlayer.source = url;
        mediaPlayer.play();
        startLimit.restart();
    }

    // First call marks the start, second the end; a third clears both.
    function markAB() {
        if (abStart < 0) {
            abStart = position;
        } else if (abEnd < 0) {
            if (position > abStart + 1000)
                abEnd = position;
        } else {
            clearAB();
        }
    }

    function clearAB() {
        abStart = -1;
        abEnd = -1;
    }

    function play() {
        if (loaded)
            mediaPlayer.play();
    }

    function pause() {
        if (!loaded)
            return;
        mediaPlayer.pause();
        saveNow();
    }

    function toggle() {
        if (playing)
            pause();
        else
            play();
    }

    function seekTo(ms) {
        if (!loaded || !mediaPlayer.seekable || duration <= 0)
            return;
        var target = Math.max(0, Math.min(Math.round(ms), duration));
        _seekTarget = target;
        seekSettle.restart();
        mediaPlayer.seek(target);
    }

    function seekBy(ms) {
        seekTo(position + ms);
    }

    function saveNow() {
        if (store && loaded && duration > 0 && !_awaitingStart)
            store.save(url, position, duration);
    }

    MediaPlayer {
        id: mediaPlayer
        notifyInterval: 100

        onDurationChanged: playback.playerDuration = Math.max(0, duration)

        onError: {
            playback.error = errorString || "This file could not be played.";
            console.warn("playback error", error, errorString);
        }

        onPositionChanged: {
            var now = position;
            var step = now - playback._lastPosition;
            playback._lastPosition = now;

            if (playback._awaitingStart && playbackState === MediaPlayer.PlayingState && duration > 0 && now >= 0) {
                playback._awaitingStart = false;
                if (playback._pendingStart > 0)
                    playback.seekTo(playback._pendingStart);
                playback._pendingStart = 0;
                return;
            }

            // Normal playback advances by one notify interval; anything else
            // is the seek landing.
            if (playback._seekTarget >= 0 && (step < -50 || step > 400))
                playback._seekTarget = -1;

            // Only while the app runs: frozen in the background, nothing here
            // is called and the file plays on past B.
            if (playback.abEnd > 0 && playback._seekTarget < 0 && now >= playback.abEnd)
                playback.seekTo(playback.abStart);
        }

        onStatusChanged: {
            if (status === MediaPlayer.EndOfMedia) {
                if (playback.store)
                    playback.store.finish(playback.url, playback.duration);
                playback.ended();
            }
        }
    }

    // A seek that changes nothing visible (or never lands) must not leave the
    // display stuck on its target.
    Timer {
        id: seekSettle
        interval: 3000
        onTriggered: playback._seekTarget = -1
    }

    // The backend raises no error for an address that does not answer, or for
    // some files it cannot play: it just never starts.
    Timer {
        id: startLimit
        interval: 20000
        onTriggered: {
            if (!playback._awaitingStart || playback.error !== "")
                return;
            playback.error = playback.url.indexOf("file://") === 0
                ? "This file could not be played."
                : "The stream did not start. Check the address and the connection.";
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: playback.playing
        onTriggered: playback.saveNow()
    }
}
