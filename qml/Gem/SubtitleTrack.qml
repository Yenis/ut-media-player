import QtQuick 2.12
import Qt.labs.folderlistmodel 2.11
import "../js/Srt.js" as Srt

/*
 * External subtitles: finds a .srt file beside the video, reads it, and says
 * which line belongs to the current position. The page draws `text`.
 *
 * Embedded subtitles are out of reach: the backend never shows or lists them
 * (docs/TESTING.md, run 4).
 *
 * The file is read as UTF-8. Other encodings come out garbled; choosing an
 * encoding is a later setting.
 */
Item {
    id: track

    property string mediaUrl: ""        // the video
    property int position: 0            // ms
    property int delay: 0               // ms; positive shows the lines later
    property bool enabled: true

    property string source: ""          // the subtitle file in use
    property var cues: []
    property int current: -1

    readonly property bool available: cues.length > 0
    readonly property string text: enabled && current >= 0 && current < cues.length ? cues[current].text : ""

    onMediaUrlChanged: find()
    onPositionChanged: update()
    onDelayChanged: update()

    function update() {
        current = Srt.cueAt(cues, position - delay, current);
    }

    function clear() {
        source = "";
        cues = [];
        current = -1;
    }

    // "video.srt" for "video.mp4", or failing that any "video*.srt", such as
    // "video.en.srt".
    function find() {
        clear();
        delay = 0;
        _base = "";
        var url = mediaUrl;
        if (url.indexOf("file://") !== 0)
            return;
        var slash = url.lastIndexOf("/");
        var name = decodeURIComponent(url.substring(slash + 1));
        var dot = name.lastIndexOf(".");
        _base = (dot > 0 ? name.substring(0, dot) : name).toLowerCase();
        // A new folder is listed in the background and answers through
        // onStatusChanged; the same folder as before is ready already.
        siblings.folder = url.substring(0, slash);
        pick();
    }

    property string _base: ""

    function pick() {
        if (_base === "" || siblings.status !== FolderListModel.Ready)
            return;
        var exact = "", loose = "";
        for (var i = 0; i < siblings.count; i++) {
            var name = siblings.get(i, "fileName");
            var lower = name.toLowerCase();
            if (lower === _base + ".srt")
                exact = siblings.get(i, "fileURL").toString();
            else if (loose === "" && lower.indexOf(_base) === 0)
                loose = siblings.get(i, "fileURL").toString();
        }
        if (exact || loose)
            load(exact || loose);
    }

    function load(url) {
        var wanted = mediaUrl;
        var request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            // The viewer may have moved on to another file meanwhile.
            if (track.mediaUrl !== wanted)
                return;
            track.cues = Srt.parse(request.responseText || "");
            track.source = track.cues.length > 0 ? url : "";
            track.current = -1;
            track.update();
        };
        request.open("GET", url);
        request.send();
    }

    FolderListModel {
        id: siblings
        nameFilters: ["*.srt"]
        caseSensitive: false
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready) track.pick()
    }
}
