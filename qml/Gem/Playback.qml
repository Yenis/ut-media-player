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
 *
 * The queue is kept here. What it plays goes to the backend in one of two
 * ways (docs/TESTING.md, "Queue in the background"):
 *  - a video on screen, as one address at a time. This process loads the
 *    next one, which it can, being in front;
 *  - audio, as a list (`Playlist`) that media-hub moves through by itself,
 *    also while the app is frozen behind the lock screen or another app.
 * A video cannot be played from a list: its picture stays black or stale.
 * So "play as audio" and back may have to load the item again, which makes a
 * break of about a second; see `setAudioMode`.
 */
Item {
    id: playback

    property var store: null            // PlayerStore

    // What is loaded.
    property string url: ""
    property string title: ""
    property string artist: ""
    property string art: ""             // address of a cover or thumbnail; empty for none
    property int libraryDuration: 0     // ms, from the media library, until the backend knows
    property bool libraryHasPicture: false

    // "Play as audio": the same playback, without its picture.
    property bool audioMode: false

    property string error: ""

    // What plays after what. `queue` holds media as `open` takes them.
    property var queue: []
    property int queueIndex: -1
    readonly property bool hasNext: queueIndex >= 0 && queueIndex < queue.length - 1
    readonly property bool hasPrevious: queueIndex > 0

    // VLC's rule for "previous": this long into a file it goes back to the
    // file's start, earlier than that to the file before (PlaylistManager.kt).
    readonly property int previousLimit: 5000

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

    // The queue ran out.
    signal ended()
    // Another item of the queue was loaded.
    signal mediaChanged()

    property int _seekTarget: -1
    property int _lastPosition: 0
    property int _pendingStart: 0       // where to seek once playback has started
    property bool _awaitingStart: false
    property bool _listMode: false      // the hub's list is playing, not a single address
    property int _pendingIndex: -1      // the item to start with, until the hub has the list
    property int _askedIndex: -1        // the item asked of the hub, until it says so itself
    property bool _fromStart: false     // go to 0 once started: the file may still be loaded, part-way

    // media: { url, title, artist, art, duration (ms), hasPicture }
    function open(media) {
        openQueue([media], 0, false, false);
    }

    // Plays `list` from its item `index`. `fromStart` ignores where that item
    // was left; `asAudio` plays without the picture.
    function openQueue(list, index, fromStart, asAudio) {
        saveNow();
        queue = list.slice();
        queueIndex = Math.max(0, Math.min(index, queue.length - 1));
        audioMode = !!asAudio;
        _start(fromStart, -1);
    }

    // "Play as audio" and back. Where the way of playing has to change with
    // it, the item is loaded again and carries on from where it was: a break
    // of about a second.
    function setAudioMode(on) {
        if (audioMode === on)
            return;
        audioMode = on;
        if (queueIndex >= 0 && _wantsList() !== _listMode)
            _restart();
    }

    // Audio goes to the hub as a list, so that it moves on without the app.
    // One video played as audio stays as it is: nothing follows it, and the
    // way back to its picture is then free of a break.
    function _wantsList() {
        return audioMode && (queue.length > 1 || !queue[queueIndex].hasPicture);
    }

    function _restart() {
        var at = _awaitingStart ? _pendingStart : position;
        saveNow();
        _start(false, at);
    }

    // Loads the queue's current item, in the way that suits. `at` is where to
    // carry on from; below zero, the item's own resume point decides.
    function _start(fromStart, at) {
        _adopt(queue[queueIndex], fromStart);
        if (at >= 0)
            _pendingStart = at;
        _pendingIndex = -1;
        _askedIndex = -1;
        _listMode = _wantsList();
        if (!_listMode) {
            if (mediaPlayer.source.toString() !== url)
                mediaPlayer.source = url;
            mediaPlayer.play();
            return;
        }
        mediaPlayer.pause();
        if (mediaPlayer.playlist !== hubList)
            mediaPlayer.playlist = hubList;
        hubList.clear();
        var urls = [];
        for (var i = 0; i < queue.length; i++)
            urls.push(queue[i].url.toString());
        hubList.addItems(urls);
        _pendingIndex = queueIndex;
        _settle();
    }

    // The hub takes the list in its own time; playback starts once the list
    // is there.
    function _settle() {
        if (_pendingIndex < 0 || hubList.itemCount < queue.length)
            return;
        var index = _pendingIndex;
        _pendingIndex = -1;
        _goTo(index);
    }

    // Asks the hub for an item. Its answer comes later, and other index
    // changes may come first (the list being emptied, its first item being
    // loaded): until the answer, they are not the hub moving on.
    function _goTo(index) {
        _askedIndex = index;
        askedLimit.restart();
        hubList.currentIndex = index;
        mediaPlayer.play();
    }

    // Puts media into the queue at `at` while it plays.
    function _insert(at, list) {
        if (queueIndex < 0 || list.length === 0)
            return;
        queue = queue.slice(0, at).concat(list, queue.slice(at));
        if (_listMode) {
            // The backend adds a list at the end, but inserts only one item
            // at a time, and only before an item that is there
            // [device]. So several go in last first, each at the same place.
            if (at >= queue.length - list.length) {
                var urls = [];
                for (var i = 0; i < list.length; i++)
                    urls.push(list[i].url.toString());
                hubList.addItems(urls);
            } else {
                for (var k = list.length - 1; k >= 0; k--)
                    hubList.insertItem(at, list[k].url.toString());
            }
        } else if (_wantsList()) {
            _restart();
        }
    }

    function insertNext(list) { _insert(queueIndex + 1, list); }
    function append(list) { _insert(queue.length, list); }

    function next() {
        if (hasNext)
            jumpTo(queueIndex + 1);
    }

    function previous() {
        if (hasPrevious && position < previousLimit)
            jumpTo(queueIndex - 1);
        else
            seekTo(0);
    }

    // Another item of the queue. The mode stays: a queue played as audio goes
    // on as audio.
    function jumpTo(index) {
        if (index < 0 || index >= queue.length || index === queueIndex)
            return;
        saveNow();
        queueIndex = index;
        if (_listMode) {
            _adopt(queue[index], false);
            _goTo(index);
        } else {
            _start(false, -1);
        }
        mediaChanged();
    }

    function clearQueue() {
        queue = [];
        queueIndex = -1;
    }

    // What the pages show, and where the item is to start once it plays.
    function _adopt(media, fromStart) {
        url = media.url.toString();
        title = media.title || "";
        artist = media.artist || "";
        art = media.art ? media.art.toString() : "";
        libraryDuration = media.duration || 0;
        libraryHasPicture = !!media.hasPicture;
        playerDuration = 0;
        error = "";
        abStart = -1;
        abEnd = -1;
        _seekTarget = -1;
        _pendingStart = store && !fromStart ? store.resumePoint(url) : 0;
        _fromStart = !!fromStart;
        _awaitingStart = true;
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

    Playlist {
        id: hubList

        onItemInserted: playback._settle()

        onCurrentIndexChanged: {
            if (!playback._listMode)
                return;
            if (playback._askedIndex >= 0) {
                if (currentIndex === playback._askedIndex)
                    playback._askedIndex = -1;
                return;
            }
            if (playback._pendingIndex >= 0 || currentIndex < 0 || currentIndex >= playback.queue.length
                    || currentIndex === playback.queueIndex)
                return;
            // The hub moved on by itself: the item before has played out.
            // After the app was frozen, every move made meanwhile arrives
            // here, one after the other.
            if (playback.store && currentIndex === playback.queueIndex + 1)
                playback.store.finish(playback.url, playback.duration);
            playback.queueIndex = currentIndex;
            playback._adopt(playback.queue[currentIndex], false);
            playback.mediaChanged();
        }
    }

    MediaPlayer {
        id: mediaPlayer
        notifyInterval: 100
        onDurationChanged: playback.playerDuration = Math.max(0, duration)

        onError: {
            // Handing the player its list empties its address for a moment,
            // and the backend complains that it cannot open nothing.
            if (/Failed to open uri\s+because/.test(errorString))
                return;
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
                else if (playback._fromStart && now > 1000)
                    playback.seekTo(0);
                playback._pendingStart = 0;
                playback._fromStart = false;
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
            if (status !== MediaPlayer.EndOfMedia || playback.queueIndex < 0)
                return;
            // In a list the hub goes to the next item, and says so.
            if (playback._listMode && playback.hasNext)
                return;
            if (playback.store)
                playback.store.finish(playback.url, playback.duration);
            if (playback.hasNext)
                advance.restart();
            else
                playback.ended();
        }
    }

    // The next item is loaded once the backend has finished ending this one.
    Timer {
        id: advance
        interval: 50
        onTriggered: playback.next()
    }

    // An item that was already the hub's current one brings no answer.
    Timer {
        id: askedLimit
        interval: 3000
        onTriggered: playback._askedIndex = -1
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
