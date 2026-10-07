import QtQuick 2.12
import MediaScanner 0.1
import Lomiri.Thumbnailer 0.1

/*
 * The system's media library, read through MediaScanner. All access to the
 * user's media goes through this one file (docs/PLAN.md, D12): a confined
 * build would replace it with a library of Content Hub imports.
 *
 * Importing Lomiri.Thumbnailer registers image://thumbnailer/, which the
 * `art` addresses below point at. Loaded by URL, since neither module exists
 * off the device.
 */
Item {
    signal changed()

    MediaStore {
        id: store
        onUpdated: changed()
    }

    function _plain(file) {
        var audio = (file.contentType || "").indexOf("audio/") === 0;
        return {
            url: file.uri,
            filename: file.filename,
            // The scanner's eTag begins with the file's modification time, in seconds.
            modified: parseInt(file.eTag) || 0,
            title: file.title,
            artist: file.author || "",
            album: file.album || "",
            duration: file.duration * 1000,     // the scanner counts seconds
            // Coded size, rounded up to a multiple of 16: 1920x1088 for 1080p.
            width: file.width,
            height: file.height,
            // For music the scanner's own `art` may be an image://albumart/
            // address, which the system can look up online (docs/PLAN.md,
            // D13): only a cover found in the file itself is shown.
            art: !audio ? file.art : file.hasThumbnail ? "image://thumbnailer/" + file.uri : "",
            hasPicture: !audio
        };
    }

    // Every video the scanner knows, in the scanner's order.
    function videos() {
        var found = store.query("", MediaStore.VideoMedia);
        var list = [];
        for (var i = 0; i < found.length; i++)
            list.push(_plain(found[i]));
        return list;
    }

    // What the scanner knows about one file, or null.
    function lookup(path) {
        var file = store.lookup(path);
        return file ? _plain(file) : null;
    }
}
