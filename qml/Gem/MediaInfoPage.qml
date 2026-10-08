import QtQuick 2.12
import Qt.labs.folderlistmodel 2.11
import Gem 1.0
import "../js/Format.js" as Format

/*
 * What is known about one video or one piece of music, after VLC's
 * InfoActivity: its picture and name, where it is, how long and how large it
 * is, and a button to play it. For music, what its tags say as well.
 * VLC lists the file's tracks and codecs below that; the system's library
 * and playback service report neither, so there is no such list here.
 */
Item {
    id: page

    property var media: null            // as MediaLibrary gives it, or null when closed
    property var entry: null            // { position, duration, seen } from PlayerStore, or null
    property bool favourite: false

    signal closeRequested()
    signal playRequested()

    visible: media !== null

    // Music has a cover and tags; a video a picture, a size and a place
    // it was watched up to.
    readonly property bool music: media ? media.hasPicture === false : false

    readonly property string path: media ? (media.filename || decodeURIComponent(media.url.replace("file://", ""))) : ""
    readonly property string folderPath: path.substring(0, path.lastIndexOf("/"))
    readonly property string fileName: path.substring(path.lastIndexOf("/") + 1)

    // The file's size, from a listing of its folder: -1 until it is known.
    property real fileSize: -1

    onPathChanged: {
        fileSize = -1;
        if (path !== "") {
            // Worked out here: `folderPath` may not have followed `path` yet.
            var inside = path.substring(0, path.lastIndexOf("/"));
            folder.folder = "file://" + inside.split("/").map(encodeURIComponent).join("/");
            lookUp();
        }
    }

    function lookUp() {
        if (path === "" || folder.status !== FolderListModel.Ready)
            return;
        for (var i = 0; i < folder.count; i++) {
            if (folder.get(i, "fileName") === path.substring(path.lastIndexOf("/") + 1)) {
                fileSize = folder.get(i, "fileSize");
                return;
            }
        }
    }

    FolderListModel {
        id: folder
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready) page.lookUp()
    }

    readonly property var rows: {
        if (!media)
            return [];
        var list = [];
        var dot = fileName.lastIndexOf(".");
        if (music) {
            if (media.artist)
                list.push({ label: "Artist", value: media.artist });
            if (media.album)
                list.push({ label: "Album", value: media.album });
            if (media.albumArtist && media.albumArtist !== media.artist)
                list.push({ label: "Album artist", value: media.albumArtist });
            if (media.trackNumber > 0)
                list.push({ label: "Track", value: (media.discNumber > 0 ? media.discNumber + " \u2013 " : "") + media.trackNumber });
            if (media.genre)
                list.push({ label: "Genre", value: media.genre });
            if (media.date)
                list.push({ label: "Released", value: media.date });
        }
        list.push({ label: "Length", value: Format.clock(media.duration) });
        if (fileSize >= 0)
            list.push({ label: "File size", value: Format.fileSize(fileSize) });
        var resolution = Format.resolutionClass(media.width, media.height);
        if (resolution)
            list.push({ label: "Resolution", value: resolution });
        if (dot > 0)
            list.push({ label: "Format", value: fileName.substring(dot + 1).toUpperCase() });
        list.push({ label: "File", value: fileName });
        list.push({ label: "Folder", value: folderPath });
        if (media.modified > 0)
            list.push({ label: "Changed", value: Qt.formatDateTime(new Date(media.modified * 1000), "d MMMM yyyy, hh:mm") });
        if (music)
            return list;
        if (entry && entry.seen > 0)
            list.push({ label: "Played", value: "To the end" });
        else if (entry && entry.position > 0)
            list.push({ label: "Played", value: "Up to " + Format.clock(entry.position) });
        else
            list.push({ label: "Played", value: "Not yet" });
        return list;
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    // Nothing behind the page takes a touch.
    MouseArea { anchors.fill: parent }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "Information"
        onBack: page.closeRequested()
    }

    Flickable {
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
        contentHeight: content.height + Theme.u(3)
        clip: true

        Column {
            id: content
            width: parent.width
            topPadding: Theme.u(2)
            spacing: Theme.u(2)

            // The cover, or the headphones where the file has none.
            Rectangle {
                visible: page.music
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - Theme.u(4), Theme.u(26))
                height: width
                radius: Theme.u(0.5)
                color: Theme.surfaceAlt
                clip: true

                Glyph {
                    anchors.centerIn: parent
                    width: parent.width * 0.4
                    name: "audio"
                    color: Theme.accent
                    visible: cover.status !== Image.Ready
                }
                Image {
                    id: cover
                    anchors.fill: parent
                    source: page.music && page.media.art ? page.media.art : ""
                    sourceSize: Qt.size(512, 512)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            VideoThumb {
                visible: !page.music
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - Theme.u(4), Theme.u(44))
                height: width * 10 / 16
                art: page.media && !page.music ? page.media.art : ""
                seen: page.entry !== null && page.entry.seen > 0
                favourite: page.favourite
                progress: page.entry && page.entry.duration > 0 ? page.entry.position / page.entry.duration : 0
            }

            Text {
                anchors { left: parent.left; right: parent.right; leftMargin: Theme.u(2); rightMargin: Theme.u(2) }
                text: page.media ? page.media.title : ""
                color: Theme.text
                font.pixelSize: Theme.fontL
                font.bold: true
                wrapMode: Text.Wrap
            }

            TextButton {
                anchors { left: parent.left; leftMargin: Theme.u(2) }
                text: !page.music && page.entry && page.entry.position > 0 ? "Resume" : "Play"
                onClicked: page.playRequested()
            }

            Column {
                width: parent.width

                Repeater {
                    model: page.rows

                    delegate: Item {
                        width: content.width
                        height: Math.max(Theme.u(5.5), valueText.height + Theme.u(2.4))

                        Text {
                            id: labelText
                            anchors { left: parent.left; leftMargin: Theme.u(2); top: parent.top; topMargin: Theme.u(1.2) }
                            width: Theme.u(11)
                            text: modelData.label
                            color: Theme.textDim
                            font.pixelSize: Theme.fontM
                        }
                        Text {
                            id: valueText
                            anchors { left: labelText.right; right: parent.right; rightMargin: Theme.u(2)
                                      top: parent.top; topMargin: Theme.u(1.2) }
                            text: modelData.value
                            color: Theme.text
                            font.pixelSize: Theme.fontM
                            wrapMode: Text.WrapAnywhere
                        }
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: Theme.u(2) }
                            height: 1
                            color: Theme.line
                        }
                    }
                }
            }
        }
    }
}
