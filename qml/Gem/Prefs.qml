import QtQuick 2.12
import Qt.labs.settings 1.0

/*
 * The app's settings, as the Settings page shows them (docs/PLAN.md,
 * Phase 4). Every default is how the app behaved before it had settings, so
 * nothing changes until something is switched.
 *
 * One of these serves the whole app; the shell owns it and hands it to the
 * pages that go by it. A value is changed through `set`, which also stores
 * it: Qt.labs.settings can lose a plain property write on quit.
 */
Item {
    id: prefs

    // The players' gestures.
    property bool gestureVolume: true
    property bool gestureBrightness: true
    property bool gestureSwipeSeek: true
    property bool gestureDoubleTap: true
    property bool gesturePinch: true

    // How far a double tap, the rewind and forward buttons and the arrow
    // keys go, in seconds.
    property int skipSeconds: 10
    readonly property var skipChoices: [5, 10, 15, 30]

    // A video carries on where it was left, or starts from its beginning.
    property bool resumeVideos: true

    // What happens to a video on screen when the app is left: it is paused,
    // or plays on as audio. VLC's "Background/PiP mode", without the PiP.
    property bool videoPlaysOnAsAudio: false

    // The queue that played as audio is there again at the next start.
    property bool restoreQueue: true

    // Subtitles: size as a factor of the usual, colour, and a dark box behind.
    property real subtitleScale: 1.0
    readonly property var subtitleScales: [0.8, 1.0, 1.3, 1.6]
    readonly property var subtitleScaleNames: ["Small", "Normal", "Large", "Huge"]
    property string subtitleColour: "white"
    readonly property var subtitleColours: ["white", "yellow"]
    readonly property var subtitleColourNames: ["White", "Yellow"]
    property bool subtitleBackground: false

    readonly property var _flags: ["gestureVolume", "gestureBrightness", "gestureSwipeSeek", "gestureDoubleTap",
                                   "gesturePinch", "resumeVideos", "videoPlaysOnAsAudio", "restoreQueue",
                                   "subtitleBackground"]

    property bool _loaded: false

    Settings {
        id: settings
        category: "prefs"
    }

    // Read on first use: who is ready first, this object or whoever asks,
    // is not laid down.
    function load() {
        if (_loaded)
            return;
        _loaded = true;
        for (var i = 0; i < _flags.length; i++) {
            // Settings hands a stored true back as the text "true".
            var kept = settings.value(_flags[i], prefs[_flags[i]]);
            prefs[_flags[i]] = kept === true || kept === "true";
        }
        var skip = parseInt(settings.value("skipSeconds", skipSeconds));
        skipSeconds = skipChoices.indexOf(skip) >= 0 ? skip : 10;
        var scale = parseFloat(settings.value("subtitleScale", subtitleScale));
        subtitleScale = subtitleScales.indexOf(scale) >= 0 ? scale : 1.0;
        var colour = "" + settings.value("subtitleColour", subtitleColour);
        subtitleColour = subtitleColours.indexOf(colour) >= 0 ? colour : "white";
    }

    function set(name, value) {
        load();
        if (prefs[name] === undefined || name.charAt(0) === "_")
            return;
        prefs[name] = value;
        settings.setValue(name, value);
        settings.sync();
    }

    // For the development remote: a value given as text.
    function setFromText(name, text) {
        if (_flags.indexOf(name) >= 0)
            set(name, text === "1" || text === "true");
        else if (name === "skipSeconds")
            set(name, skipChoices.indexOf(parseInt(text)) >= 0 ? parseInt(text) : 10);
        else if (name === "subtitleScale")
            set(name, subtitleScales.indexOf(parseFloat(text)) >= 0 ? parseFloat(text) : 1.0);
        else if (name === "subtitleColour")
            set(name, subtitleColours.indexOf(text) >= 0 ? text : "white");
    }

    function summary() {
        var all = { skipSeconds: skipSeconds, subtitleScale: subtitleScale, subtitleColour: subtitleColour };
        for (var i = 0; i < _flags.length; i++)
            all[_flags[i]] = prefs[_flags[i]];
        return all;
    }

    Component.onCompleted: load()
}
