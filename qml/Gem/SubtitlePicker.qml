import QtQuick 2.12
import Qt.labs.folderlistmodel 2.11
import Gem 1.0

/*
 * VLC's "Select subtitle file": the folders and the subtitle files of one
 * folder, starting at the video's, as a sheet in the video player. A folder
 * opens in place, "Up" goes to the one above, a file is `picked`.
 *
 * Only the formats the app reads are listed: SubRip (.srt) and WebVTT
 * (.vtt). VLC also reads .ass, .ssa, .sub and others.
 */
Item {
    id: picker

    property string current: ""         // the subtitle file in use, marked in the list

    readonly property bool open: sheet.open
    readonly property string title: _path

    signal picked(string url)

    function show(folderUrl) {
        folders.folder = folderUrl;
        sheet.show();
    }

    function close() { sheet.close(); }

    readonly property string _path: decodeURIComponent(folders.folder.toString().replace(/^file:\/\//, ""))

    function _parent() {
        var path = folders.folder.toString();
        var slash = path.lastIndexOf("/");
        return slash > "file://".length ? path.substring(0, slash) : "file:///";
    }

    // For the development remote: a row by its place in the list.
    function choose(index) {
        var rows = sheet.options;
        if (index >= 0 && index < rows.length && rows[index].key)
            _chosen(rows[index].key);
    }

    function _chosen(key) {
        if (key === "up") {
            folders.folder = _parent();
        } else if (key.charAt(0) === "d") {
            folders.folder = folders.get(parseInt(key.substring(1)), "fileURL");
        } else if (key.charAt(0) === "f") {
            sheet.close();
            picked(folders.get(parseInt(key.substring(1)), "fileURL").toString());
        }
    }

    FolderListModel {
        id: folders
        nameFilters: ["*.srt", "*.vtt"]
        caseSensitive: false
        showDirsFirst: true
        showDotAndDotDot: false
    }

    OptionSheet {
        id: sheet
        anchors.fill: parent
        title: picker._path
        options: {
            var rows = [];
            if (folders.status !== FolderListModel.Ready)
                return rows;
            if (picker._path !== "/")
                rows.push({ key: "up", label: "Up", glyph: "up", stay: true });
            var files = 0;
            for (var i = 0; i < folders.count; i++) {
                var url = folders.get(i, "fileURL").toString();
                if (folders.get(i, "fileIsDir")) {
                    rows.push({ key: "d" + i, label: folders.get(i, "fileName"), glyph: "folder", stay: true });
                } else {
                    files++;
                    rows.push({ key: "f" + i, label: folders.get(i, "fileName"), glyph: "subtitles",
                                selected: url === picker.current, stay: true });
                }
            }
            if (files === 0)
                rows.push({ label: "No .srt or .vtt files here" });
            return rows;
        }
        onChosen: picker._chosen(key)
    }
}
