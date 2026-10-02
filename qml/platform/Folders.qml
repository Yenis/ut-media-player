import QtQuick 2.12
import Qt.labs.platform 1.0

/*
 * Where the user's folders are. Loaded by URL, so a device without
 * Qt.labs.platform starts anyway and simply has no screenshot folder.
 */
Item {
    readonly property string pictures: _path(StandardPaths.writableLocation(StandardPaths.PicturesLocation))

    function _path(url) {
        return decodeURIComponent(url.toString().replace("file://", ""));
    }
}
