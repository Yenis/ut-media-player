import QtQuick 2.12
import Qt.labs.folderlistmodel 2.2
import Qt.labs.platform 1.0

/* Spike: which folders can the confined app list directly? */
Item {
    readonly property string home: strip(StandardPaths.writableLocation(StandardPaths.HomeLocation))
    readonly property string cache: strip(StandardPaths.writableLocation(StandardPaths.GenericCacheLocation))

    function strip(url) {
        var s = url.toString();
        return s.indexOf("file://") === 0 ? s.substring(7) : s;
    }

    FolderListModel {
        id: folder
        showDirs: true
        showDotAndDotDot: false
        showOnlyReadable: false
    }

    // Asynchronous: call list(), wait, then read names().
    function list(path) {
        folder.folder = "file://" + path;
    }

    function names() {
        var out = [];
        for (var i = 0; i < folder.count; i++)
            out.push(folder.get(i, "fileName") + (folder.get(i, "fileIsDir") ? "/" : ""));
        return out;
    }
}
