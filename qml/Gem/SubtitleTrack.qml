import QtQuick 2.12
import Qt.labs.folderlistmodel 2.11
import "../js/Srt.js" as Srt
import "../js/Encodings.js" as Encodings

/*
 * External subtitles: the file chosen for the video, or else a .srt or .vtt
 * file beside it; read in its encoding, and the line that belongs to the
 * current position. The page draws `text`.
 *
 * Embedded subtitles are out of reach: the backend never shows or lists them
 * (docs/TESTING.md, run 4).
 *
 * The choice of file and of encoding is kept per video in the store. An
 * encoding not chosen is the settings' default, and that by default is VLC's
 * "automatic": UTF-8 if the file is UTF-8, otherwise Windows-1252.
 */
Item {
    id: track

    property string mediaUrl: ""        // the video
    property int position: 0            // ms
    property int delay: 0               // ms; positive shows the lines later
    property bool enabled: true
    property var store: null            // PlayerStore: the choices per video
    property string defaultEncoding: "" // the settings'; "" for automatic

    property string source: ""          // the subtitle file in use
    property string chosenFile: ""      // picked for this video; "" for the one beside it
    property string encoding: ""        // picked for this video; "" for the default, "auto" for VLC's automatic
    property string usedEncoding: ""    // what the file was read as
    property var cues: []
    property int current: -1

    readonly property bool canPick: mediaUrl.indexOf("file://") === 0
    readonly property bool available: cues.length > 0
    readonly property string text: enabled && current >= 0 && current < cues.length ? cues[current].text : ""
    // The video's folder, where the picker starts.
    readonly property string folder: canPick ? mediaUrl.substring(0, mediaUrl.lastIndexOf("/")) : ""

    onMediaUrlChanged: find()
    onPositionChanged: update()
    onDelayChanged: update()
    onDefaultEncodingChanged: if (source !== "" && encoding === "") load(source)

    function update() {
        current = Srt.cueAt(cues, position - delay, current);
    }

    function clear() {
        source = "";
        usedEncoding = "";
        cues = [];
        current = -1;
    }

    function find() {
        clear();
        delay = 0;
        _base = "";
        chosenFile = "";
        encoding = "";
        // Not `canPick`: here it still holds for the video before.
        if (mediaUrl.indexOf("file://") !== 0)
            return;
        if (store) {
            var choice = store.subtitleChoice(mediaUrl);
            chosenFile = choice.file;
            encoding = choice.encoding;
        }
        if (chosenFile !== "")
            load(chosenFile);
        else
            findBeside();
    }

    // Another file for this video, kept for it. Its encoding starts again
    // from the default.
    function pick(url) {
        chosenFile = url;
        encoding = "";
        _keep();
        load(url);
    }

    // The encoding to read this video's subtitles in; "" for the default.
    function setEncoding(key) {
        encoding = key;
        _keep();
        if (source !== "")
            load(source);
    }

    function _keep() {
        if (store)
            store.setSubtitleChoice(mediaUrl, chosenFile, encoding);
    }

    // "video.srt" for "video.mp4", or failing that any "video*.srt", such as
    // "video.en.srt"; the same with .vtt.
    function findBeside() {
        var url = mediaUrl;
        var slash = url.lastIndexOf("/");
        var name = decodeURIComponent(url.substring(slash + 1));
        var dot = name.lastIndexOf(".");
        _base = (dot > 0 ? name.substring(0, dot) : name).toLowerCase();
        // A new folder is listed in the background and answers through
        // onStatusChanged; the same folder as before is ready already.
        siblings.folder = url.substring(0, slash);
        _pickBeside();
    }

    property string _base: ""

    function _pickBeside() {
        if (_base === "" || siblings.status !== FolderListModel.Ready)
            return;
        var exact = "", loose = "";
        for (var i = 0; i < siblings.count; i++) {
            var name = siblings.get(i, "fileName");
            var lower = name.toLowerCase();
            if (lower === _base + ".srt" || (exact === "" && lower === _base + ".vtt"))
                exact = siblings.get(i, "fileURL").toString();
            else if (loose === "" && lower.indexOf(_base) === 0)
                loose = siblings.get(i, "fileURL").toString();
        }
        if (exact || loose)
            load(exact || loose);
    }

    function load(url) {
        var wanted = mediaUrl;
        _get(url, true, function(bytes) {
            // The viewer may have moved on to another file meanwhile.
            if (track.mediaUrl !== wanted)
                return;
            if (bytes.length === 0) {
                // A chosen file that is gone: back to the one beside the video.
                if (url === track.chosenFile) {
                    track.chosenFile = "";
                    track._keep();
                    track.clear();
                    track.findBeside();
                }
                return;
            }
            var key = track.encoding !== "" ? track.encoding : track.defaultEncoding;
            if (key === "" || key === "auto")
                key = Encodings.detect(bytes);
            var table = Encodings.tableFile(key);
            var done = function(tableText) {
                if (track.mediaUrl !== wanted)
                    return;
                track.cues = Srt.parse(Encodings.decode(bytes, key, tableText));
                track.source = url;
                track.usedEncoding = key;
                track.current = -1;
                track.update();
            };
            if (table === "")
                done("");
            else if (_tables[table] !== undefined)
                done(_tables[table]);
            else
                _get(Qt.resolvedUrl("../js/encodings/" + table + ".txt"), false, function(text) {
                    _tables[table] = text;
                    done(text);
                });
        });
    }

    // Table files read so far, by name: each is read once.
    property var _tables: ({})

    function _get(url, binary, then) {
        var request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            if (binary)
                then(request.response ? new Uint8Array(request.response) : new Uint8Array(0));
            else
                then(request.responseText || "");
        };
        request.open("GET", url);
        if (binary)
            request.responseType = "arraybuffer";
        request.send();
    }

    FolderListModel {
        id: siblings
        nameFilters: ["*.srt", "*.vtt"]
        caseSensitive: false
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready) track._pickBeside()
    }
}
