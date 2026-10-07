import QtQuick 2.12
import QtMultimedia 5.12
import Qt.labs.settings 1.0
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
 *
 * Repeat and shuffle are done here, by what is put into the queue and the
 * list, not by the list's own modes: its "loop" skips the first item at each
 * turn, and its "random" plays items twice before others once. Only "repeat
 * one" is the list's own. See `_syncTail`.
 *
 * What plays as audio is kept in the store, queue and place, and is there
 * again when the app is next started: shown, but not loaded until it is
 * played. See `restore`.
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
    readonly property bool hasNext: queueIndex >= 0 && queue.length > 1
                                    && (queueIndex < queue.length - 1 || repeat === "all")

    // "Stop after this track": the queue's item after which playback ends,
    // or -1. Moving past it by hand lifts it.
    property int stopAfter: -1
    readonly property bool hasPrevious: queueIndex > 0

    // Repeat: "none", "all" (the queue starts again at its end) or "one".
    // Shuffle: what follows the current item is in random order. Both stay
    // as they are set, from one queue to the next and one launch to the next.
    property string repeat: "none"
    property bool shuffle: false
    readonly property var repeatModes: ["none", "all", "one"]

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
    // Played out, or never started. The state follows the status by a moment.
    readonly property bool _stopped: mediaPlayer.playbackState === MediaPlayer.StoppedState
                                     || mediaPlayer.status === MediaPlayer.EndOfMedia
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
    readonly property int position: _resumeAt >= 0 && _stopped ? _resumeAt
                                  : _seekTarget >= 0 ? _seekTarget
                                                     : Math.max(0, Math.min(mediaPlayer.position, duration > 0 ? duration : mediaPlayer.position))

    // The queue ran out.
    signal ended()
    // Another item of the queue was loaded.
    signal mediaChanged()

    property int _seekTarget: -1
    property int _lastPosition: 0
    property int _pendingStart: 0       // where to seek once playback has started
    property bool _awaitingStart: false
    property real _beatAt: 0            // clock time of the last sign of life while a list played; 0 for none
    property int _beatPosition: 0       // where playback was then
    property int _owed: -1              // while catching up after a freeze: playing time not yet accounted for
    property int _resumeAt: -1          // where a queue brought back by `restore` is to carry on; -1 otherwise
    readonly property bool _unloaded: _resumeAt >= 0
    property var _ordered: []           // the queue as it was given, for when shuffle is switched off
    property int _lapStart: 0           // the hub's index of the queue's first item, in the lap that plays
    property int _hubCount: 0           // how many items the hub's list has been given
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
        var at = Math.max(0, Math.min(index, list.length - 1));
        _ordered = list.slice();
        if (shuffle && list.length > 1) {
            // The item chosen plays first; the others follow in random order.
            queue = [list[at]].concat(_shuffled(list.slice(0, at).concat(list.slice(at + 1))));
            queueIndex = 0;
        } else {
            queue = list.slice();
            queueIndex = at;
        }
        stopAfter = -1;
        _resumeAt = -1;
        audioMode = !!asAudio;
        _start(fromStart, -1);
        _keepQueue();
    }

    // ---- kept from one launch to the next ---------------------------------------------

    // Only what plays as audio is kept: a video ends with its page.
    function _keepQueue() {
        if (!store)
            return;
        if (!audioMode || queueIndex < 0) {
            // Not "": the database takes an empty text for no value at all.
            store.keep("queue", "[]");
            return;
        }
        var items = [];
        for (var i = 0; i < queue.length; i++) {
            var m = queue[i];
            items.push({ url: m.url.toString(), title: m.title || "", artist: m.artist || "",
                         albumArtist: m.albumArtist || "", album: m.album || "", art: m.art ? m.art.toString() : "",
                         duration: m.duration || 0, hasPicture: !!m.hasPicture });
        }
        store.keep("queue", JSON.stringify(items));
        store.keep("queueIndex", queueIndex);
    }

    function _keepPlace() {
        if (store && audioMode && queueIndex >= 0)
            store.keep("queueIndex", queueIndex);
    }

    // Brings back the queue that played as audio when the app was last used:
    // its items, and the one that played, at the place it was left. Nothing
    // is loaded: `play` does that. Called once, by the shell.
    function restore() {
        if (!store || queueIndex >= 0)
            return;
        var items;
        try {
            items = JSON.parse(store.kept("queue") || "[]");
        } catch (e) {
            items = [];
        }
        if (!items || items.length === 0)
            return;
        queue = items;
        _ordered = items.slice();
        queueIndex = Math.max(0, Math.min(parseInt(store.kept("queueIndex")) || 0, items.length - 1));
        audioMode = true;
        _adopt(queue[queueIndex], true);
        _awaitingStart = false;
        startLimit.stop();
        _resumeAt = Math.max(0, store.resumePoint(url));
    }

    function setRepeat(mode) {
        var before = repeat;
        repeat = repeatModes.indexOf(mode) >= 0 ? mode : "none";
        settings.setValue("repeat", repeat);
        settings.sync();
        if (_listMode && queueIndex >= 0 && !_unloaded && (before === "all") !== (repeat === "all"))
            _syncTail();
    }

    function cycleRepeat() {
        setRepeat(repeatModes[(repeatModes.indexOf(repeat) + 1) % repeatModes.length]);
    }

    // Shuffling leaves what has played, and the current item, where they are
    // and mixes what follows. Switching it off puts what is still to come
    // back into its first order.
    function setShuffle(on) {
        if (shuffle === on)
            return;
        shuffle = on;
        settings.setValue("shuffle", on);
        settings.sync();
        if (queueIndex < 0)
            return;
        stopAfter = -1;
        var played = queue.slice(0, queueIndex + 1);
        var rest;
        if (on) {
            rest = _shuffled(queue.slice(queueIndex + 1));
        } else {
            rest = _ordered.filter(function(item) { return played.indexOf(item) < 0; });
        }
        queue = played.concat(rest);
        _keepQueue();
        if (_listMode && !_unloaded)
            _syncTail();
    }

    function _shuffled(list) {
        var mixed = list.slice();
        for (var i = mixed.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1));
            var held = mixed[i];
            mixed[i] = mixed[j];
            mixed[j] = held;
        }
        return mixed;
    }

    // "Play as audio" and back. Where the way of playing has to change with
    // it, the item is loaded again and carries on from where it was: a break
    // of about a second.
    function setAudioMode(on) {
        if (audioMode === on)
            return;
        audioMode = on;
        if (queueIndex >= 0 && !_unloaded && _wantsList() !== _listMode)
            _restart();
        _keepQueue();
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
            // The list has to be emptied before an address is played
            // again: with tracks left in it, the next video shows upside
            // down and with the length of the last track [device].
            if (mediaPlayer.playlist)
                hubList.clear();
            // An address that has played out plays again only when it is set
            // again, and setting the same one is no setting at all: giving
            // the player its (empty) list in between makes it one.
            if (mediaPlayer.source.toString() === url && _stopped)
                mediaPlayer.playlist = hubList;
            if (mediaPlayer.source.toString() !== url)
                mediaPlayer.source = url;
            mediaPlayer.play();
            return;
        }
        // Set before the list is touched: emptying and filling it reports
        // index changes at once, which must not be read as the hub moving on.
        _pendingIndex = queueIndex;
        if (playing)
            mediaPlayer.pause();
        if (mediaPlayer.playlist !== hubList)
            mediaPlayer.playlist = hubList;
        hubList.clear();
        _lapStart = 0;
        var urls = stopAfter >= 0 ? _urls(queue.slice(0, stopAfter + 1)) : _urls(queue).concat(_laps());
        _hubCount = urls.length;
        hubList.addItems(urls);
        _settle();
    }

    function _urls(list) {
        var urls = [];
        for (var i = 0; i < list.length; i++)
            urls.push(list[i].url.toString());
        return urls;
    }

    // "Repeat all" for the hub's list: the queue laid out again behind
    // itself, often enough to last hours while the app is frozen and cannot
    // add more. A queue of one is repeated by the list's own "repeat one".
    function _laps() {
        var urls = [];
        if (repeat !== "all" || queue.length < 2)
            return urls;
        var once = _urls(queue);
        for (var lap = Math.max(1, Math.ceil(200 / queue.length)); lap > 0; lap--)
            urls = urls.concat(once);
        return urls;
    }

    // Makes the hub's list match the queue from the current item on: what
    // follows it is taken out and put in afresh. Only what follows: taking
    // out or inserting before the playing item leaves the list's index
    // pointing at the wrong one [device]. About 3 ms per item taken out.
    function _syncTail() {
        var at = _lapStart + queueIndex;
        if (_hubCount > at + 1)
            hubList.removeItems(at + 1, _hubCount - 1);
        // "Stop after this track" is the list ending there.
        var urls = stopAfter >= queueIndex ? _urls(queue.slice(queueIndex + 1, stopAfter + 1))
                                           : _urls(queue.slice(queueIndex + 1)).concat(_laps());
        if (urls.length > 0)
            hubList.addItems(urls);
        _hubCount = at + 1 + urls.length;
    }

    // The hub takes the list in its own time; playback starts once the list
    // is there.
    function _settle() {
        if (_pendingIndex < 0 || hubList.itemCount < _hubCount)
            return;
        var index = _pendingIndex;
        _pendingIndex = -1;
        _goTo(index);
    }

    // Asks the hub for an item. Its answer comes later, and other index
    // changes may come first (the list being emptied, its first item being
    // loaded): until the answer, they are not the hub moving on.
    function _goTo(index) {
        _askedIndex = _lapStart + index;
        askedLimit.restart();
        hubList.currentIndex = _lapStart + index;
        mediaPlayer.play();
    }

    // Puts media into the queue at `at` while it plays.
    function _insert(at, list) {
        if (queueIndex < 0 || list.length === 0)
            return;
        queue = queue.slice(0, at).concat(list, queue.slice(at));
        _ordered = _ordered.concat(list);
        if (stopAfter >= at)
            stopAfter += list.length;
        _keepQueue();
        if (_unloaded)
            return;
        if (!_listMode) {
            if (_wantsList())
                _restart();
        } else if (repeat === "all" || stopAfter >= 0) {
            _syncTail();
        } else if (at >= queue.length - list.length) {
            // The backend adds a list at the end, but inserts only one item
            // at a time, and only before an item that is there [device]. So
            // several go in last first, each at the same place.
            hubList.addItems(_urls(list));
            _hubCount += list.length;
        } else {
            for (var k = list.length - 1; k >= 0; k--)
                hubList.insertItem(_lapStart + at, list[k].url.toString());
            _hubCount += list.length;
        }
    }

    function insertNext(list) { _insert(queueIndex + 1, list); }
    function append(list) { _insert(queue.length, list); }

    // Takes an item that is still to come out of the queue. What has played,
    // and what plays, stays: the hub's list cannot be changed before the
    // playing item.
    function removeAt(index) {
        if (index <= queueIndex || index >= queue.length)
            return;
        var item = queue[index];
        queue = queue.slice(0, index).concat(queue.slice(index + 1));
        _ordered = _ordered.filter(function(other) { return other !== item; });
        if (stopAfter === index)
            stopAfter = -1;
        else if (stopAfter > index)
            stopAfter--;
        _keepQueue();
        if (_listMode && !_unloaded)
            _syncTail();
    }

    // Sets "stop after this track" on an item, or lifts it from the item
    // that has it.
    function setStopAfter(index) {
        if (index < queueIndex || index >= queue.length)
            return;
        stopAfter = stopAfter === index ? -1 : index;
        if (_listMode && !_unloaded)
            _syncTail();
    }

    // Before a move by hand to an item behind the stop: the stop is lifted,
    // and the hub given the rest of the queue again.
    function _liftStop(index) {
        if (stopAfter < 0 || index <= stopAfter)
            return;
        stopAfter = -1;
        if (_listMode && !_unloaded)
            _syncTail();
    }

    function next() {
        if (!hasNext)
            return;
        if (queueIndex < queue.length - 1) {
            jumpTo(queueIndex + 1);
            return;
        }
        // Repeat all: round to the start, which for the hub is the next lap.
        _liftStop(queue.length);
        saveNow();
        queueIndex = 0;
        _keepPlace();
        if (_unloaded) {
            _resumeAt = -1;
            _start(false, -1);
        } else if (_listMode) {
            _lapStart += queue.length;
            _adopt(queue[0], false);
            _goTo(0);
            _topUp();
        } else {
            _start(false, -1);
        }
        mediaChanged();
    }

    // Keeps a lap in hand while "repeat all" runs and the app is awake.
    function _topUp() {
        if (repeat !== "all" || stopAfter >= 0 || queue.length < 2
                || _hubCount - (_lapStart + queue.length) >= queue.length)
            return;
        var urls = _laps();
        hubList.addItems(urls);
        _hubCount += urls.length;
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
        _liftStop(index);
        saveNow();
        queueIndex = index;
        _keepPlace();
        if (_unloaded) {
            _resumeAt = -1;
            _start(false, -1);
        } else if (_listMode) {
            _adopt(queue[index], false);
            _goTo(index);
        } else {
            _start(false, -1);
        }
        mediaChanged();
    }

    function clearQueue() {
        queue = [];
        _ordered = [];
        queueIndex = -1;
        stopAfter = -1;
        _resumeAt = -1;
        _keepQueue();
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
        // A video carries on where it was left. Music starts at its start, as
        // in VLC: a song tapped again is not wanted from its middle.
        _pendingStart = store && !fromStart && media.hasPicture ? store.resumePoint(url) : 0;
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
        if (!loaded)
            return;
        // What has played out, or was only brought back from the last
        // launch, has to be loaded to play.
        if (_stopped && queueIndex >= 0) {
            var at = _resumeAt;
            _resumeAt = -1;
            _start(at < 0, at);
        } else {
            mediaPlayer.play();
        }
    }

    // Never pauses a player that has stopped at the end of its media: the
    // hub then loads the file again to pause it, and with its track list
    // emptied (see `_start`) that makes media-hub itself abort [device].
    function pause() {
        if (!loaded || _stopped)
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

    Settings {
        id: settings
        category: "playback"
    }

    Component.onCompleted: {
        var mode = settings.value("repeat", "none");
        repeat = repeatModes.indexOf(mode) >= 0 ? mode : "none";
        // Settings hands a stored true back as the text "true".
        var mixed = settings.value("shuffle", false);
        shuffle = mixed === true || mixed === "true";
    }

    Playlist {
        id: hubList

        // The one mode of the list that is used: it plays an item again
        // without a gap, and without the app.
        playbackMode: playback.repeat === "one" || (playback.repeat === "all" && playback.queue.length === 1)
                      ? Playlist.CurrentItemInLoop : Playlist.Sequential

        onItemInserted: playback._settle()

        onCurrentIndexChanged: {
            if (!playback._listMode)
                return;
            if (playback._askedIndex >= 0) {
                if (currentIndex === playback._askedIndex)
                    playback._askedIndex = -1;
                return;
            }
            if (playback._pendingIndex >= 0 || currentIndex < 0 || currentIndex >= playback._hubCount)
                return;
            // Which lap the hub is in, and which item of the queue that is.
            var count = playback.queue.length;
            while (currentIndex >= playback._lapStart + count)
                playback._lapStart += count;
            while (currentIndex < playback._lapStart)
                playback._lapStart -= count;
            var index = currentIndex - playback._lapStart;

            // The hub moved on by itself: the item before has played out.
            // After the app was frozen, every move made meanwhile arrives
            // here, one after the other, and with each of them Qt's player
            // sets the item and plays it, as if the list were its own to
            // run: the item that was playing all along starts again
            // [device]. So the place it had reached is worked out from the
            // clock, and sought once it plays again.
            var frozen = playback._beatAt > 0 && Date.now() - playback._beatAt > 3000;
            if (frozen && playback._owed < 0)
                playback._owed = playback._beatPosition + (Date.now() - playback._beatAt);
            if (playback._owed >= 0)
                playback._owed -= playback.duration;

            // "Repeat one" reports the same item again.
            if (index !== playback.queueIndex) {
                if (playback.store)
                    playback.store.finish(playback.url, playback.duration);
                playback.queueIndex = index;
                playback._keepPlace();
                playback._adopt(playback.queue[index], false);
                playback._topUp();
                playback.mediaChanged();
            }
            if (playback._owed >= 0)
                caughtUp.restart();
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
            if (playback.store)
                playback.store.finish(playback.url, playback.duration);
            if (playback._listMode) {
                // The hub's list has run out. With "repeat all" that takes
                // the app being frozen for longer than the laps lasted.
                if (playback.repeat === "all" && playback.queue.length > 1 && playback.stopAfter < 0) {
                    playback.queueIndex = 0;
                    playback._start(true, -1);
                    playback.mediaChanged();
                } else {
                    playback.ended();
                }
            } else if (playback.queueIndex === playback.stopAfter) {
                playback.ended();
            } else if (playback.repeat === "one") {
                again.restart();
            } else if (playback.hasNext) {
                advance.restart();
            } else {
                playback.ended();
            }
        }
    }

    // While a list plays: when the app was last awake, and where playback
    // was then. A long silence from this timer is the app having been frozen.
    Timer {
        interval: 1000
        repeat: true
        running: playback._listMode && playback.playing
        onRunningChanged: if (!running) playback._beatAt = 0
        onTriggered: {
            if (playback._owed >= 0)
                return;
            playback._beatAt = Date.now();
            playback._beatPosition = Math.max(0, mediaPlayer.position);
        }
    }

    // After the moves made while the app was frozen have all arrived: back
    // to where the item had got to. Not if the sum does not fit the item,
    // which is what a pause in the meantime would make of it.
    Timer {
        id: caughtUp
        interval: 300
        onTriggered: {
            var at = playback._owed;
            playback._owed = -1;
            playback._beatAt = 0;
            if (at > 2000 && at < playback.duration - 3000) {
                playback._pendingStart = at;
                playback._awaitingStart = true;
                startLimit.restart();
            }
        }
    }

    // "Repeat one" for a video on screen, likewise once the end is over.
    Timer {
        id: again
        interval: 50
        onTriggered: if (playback.queueIndex >= 0) playback._start(true, -1)
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
