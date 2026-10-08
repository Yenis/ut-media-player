import QtQuick 2.12
import Qt.labs.folderlistmodel 2.11
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The Browse tab: the phone's folders, as VLC's browser has them
 * (docs/VLC-FEATURES.md, "Browse"). It starts at an overview with the
 * storages and the folders marked as favourites. Inside a storage it lists
 * folders and the media files among them, with the way back up along the
 * path bar. A tap on a file plays it and what follows it in its folder; a
 * folder plays whole from its menu or from the button at the top.
 *
 * Local and removable storage only: there are no network places (D13).
 */
Item {
    id: page

    property var library: null          // platform/MediaLibrary.qml: titles and lengths for the files it knows
    property var store: null            // PlayerStore: the favourite folders
    property var overlay: page          // what the sheets cover
    property string homePath: ""            // the user's home folder, the "internal storage"
    property string playingUrl: ""      // what plays as audio now, to mark it

    property string path: ""            // the folder shown; "" is the overview
    property string root: ""            // the storage or favourite the path was entered from

    // Favourite folders, as paths. Kept as one text in the store.
    property var favouriteFolders: []
    readonly property bool isFavourite: favouriteFolders.indexOf(path) >= 0

    property var menuRow: null

    // Play `list` from its item `index`. options: { asAudio, background }.
    signal playRequested(var list, int index, var options)

    readonly property string removableRoot: homePath ? "/media/" + homePath.substring(homePath.lastIndexOf("/") + 1) : ""

    function fileUrl(folderPath) {
        return "file://" + folderPath.split("/").map(encodeURIComponent).join("/");
    }

    function nameOf(folderPath) {
        return folderPath === homePath ? "Internal storage" : folderPath.substring(folderPath.lastIndexOf("/") + 1);
    }

    // ---- where we are ---------------------------------------------------------------

    function enter(folderPath) {
        root = folderPath;
        path = folderPath;
    }

    function open(folderPath) {
        path = folderPath;
    }

    // One folder up; from a storage's or favourite's top, back to the
    // overview. False from the overview: there is nowhere further back.
    function back() {
        if (path === "")
            return false;
        if (path === root || path.lastIndexOf("/") <= 0)
            path = "";
        else
            path = path.substring(0, path.lastIndexOf("/"));
        return true;
    }

    // The path bar: the folders from the entered one down to the one shown.
    readonly property var crumbs: {
        var list = [];
        if (path === "")
            return list;
        var at = path;
        while (at.length >= root.length && at !== "") {
            list.unshift({ path: at, name: nameOf(at) });
            if (at === root)
                break;
            at = at.substring(0, at.lastIndexOf("/"));
        }
        return list;
    }

    // ---- favourites -----------------------------------------------------------------

    function loadFavourites() {
        var list = [];
        try {
            list = JSON.parse(store ? (store.kept("browseFavourites") || "[]") : "[]");
        } catch (e) {
            list = [];
        }
        favouriteFolders = list.filter(function(folderPath) { return !!folderPath; });
    }

    // The overview is no folder, and cannot be a favourite.
    function setFavourite(folderPath, on) {
        if (!folderPath)
            return;
        var list = favouriteFolders.filter(function(other) { return other !== folderPath; });
        if (on)
            list.push(folderPath);
        list.sort();
        favouriteFolders = list;
        store.keep("browseFavourites", JSON.stringify(list));
    }

    onStoreChanged: loadFavourites()

    // ---- what a folder holds ----------------------------------------------------------

    // A file as the players take it: what the library knows of it, or else
    // its name and the kind its extension says.
    function mediaFor(filePath, fileName) {
        var known = library ? library.lookup(filePath) : null;
        if (known)
            return known;
        return { url: fileUrl(filePath), filename: filePath, title: Format.baseName(fileName), artist: "",
                 duration: 0, art: "", hasPicture: !Format.isAudioName(fileName) };
    }

    // The rows of the folder shown: folders first, then media files.
    // { folder: true, path, name } or { path, name, size, media }.
    property var rows: []

    function readRows() {
        // With no folder to show, the model lists the app's own.
        if (path === "") {
            rows = [];
            return;
        }
        var list = [];
        for (var i = 0; i < folder.count; i++) {
            var name = folder.get(i, "fileName");
            var filePath = folder.get(i, "filePath");
            if (folder.get(i, "fileIsDir"))
                list.push({ folder: true, path: filePath, name: name });
            else
                list.push({ path: filePath, name: name, size: folder.get(i, "fileSize"), media: mediaFor(filePath, name) });
        }
        rows = list;
    }

    // What the overview lists: the storages, then the favourites.
    readonly property var overviewRows: {
        var list = [{ section: "Storages" }];
        if (homePath)
            list.push({ folder: true, path: homePath, name: "Internal storage", entry: true });
        for (var i = 0; removableThere && i < removable.count; i++)
            list.push({ folder: true, path: removable.get(i, "filePath"), name: removable.get(i, "fileName"),
                        entry: true, removable: true });
        list.push({ section: "Favourites" });
        for (var k = 0; k < favouriteFolders.length; k++)
            list.push({ folder: true, path: favouriteFolders[k], name: nameOf(favouriteFolders[k]),
                        detail: favouriteFolders[k], entry: true });
        if (favouriteFolders.length === 0)
            list.push({ note: "No favourite folders yet. The star at the top of a folder adds it here." });
        return list;
    }

    readonly property var shown: path === "" ? overviewRows : rows

    function mediaRows() {
        return rows.filter(function(row) { return !row.folder; });
    }

    // Plays the media of the folder shown: all of one kind, from `from` on.
    // Music and videos do not share a queue, so a tap plays its own kind.
    function playHere(from) {
        var files = mediaRows();
        if (files.length === 0)
            return;
        var first = from || files[0];
        var asAudio = !first.media.hasPicture;
        var list = [];
        var index = 0;
        for (var i = 0; i < files.length; i++) {
            if (!files[i].media.hasPicture !== asAudio)
                continue;
            if (files[i].path === first.path)
                index = list.length;
            list.push(files[i].media);
        }
        playRequested(list, index, { asAudio: asAudio, background: asAudio });
    }

    // A tap on a row.
    function activate(row) {
        if (!row || row.section || row.note)
            return;
        if (row.folder) {
            if (row.entry)
                enter(row.path);
            else
                open(row.path);
        } else {
            playHere(row);
        }
    }

    // "Play all" on a folder that is not open: it is listed first.
    property string pendingFolder: ""

    function playFolder(folderPath) {
        pendingFolder = folderPath;
        // A listing arrives later, announced by the model's status. Only a
        // folder that is listed already can be played at once: asked too
        // early, the model still holds the folder before.
        if (other.folder.toString() === fileUrl(folderPath))
            playPending();
        else
            other.folder = fileUrl(folderPath);
    }

    function playPending() {
        if (pendingFolder === "" || other.status !== FolderListModel.Ready
                || other.folder.toString() !== fileUrl(pendingFolder))
            return;
        var music = [], videos = [];
        for (var i = 0; i < other.count; i++) {
            if (other.get(i, "fileIsDir"))
                continue;
            var media = mediaFor(other.get(i, "filePath"), other.get(i, "fileName"));
            (media.hasPicture ? videos : music).push(media);
        }
        pendingFolder = "";
        // Whichever the folder has more of; a folder of music plays as music.
        var list = music.length >= videos.length ? music : videos;
        if (list.length > 0)
            playRequested(list, 0, { asAudio: !list[0].hasPicture, background: !list[0].hasPicture });
    }

    function itemAction(row, key) {
        if (!row)
            return;
        if (key === "open")
            activate(row);
        else if (key === "playAll")
            playFolder(row.path);
        else if (key === "favourite")
            setFavourite(row.path, favouriteFolders.indexOf(row.path) < 0);
    }

    function closeSheets() {
        itemMenu.close();
    }

    function shownTitles() {
        return shown.map(function(row) {
            return row.section ? "# " + row.section : row.note ? "(note)" : row.folder ? row.name + "/" : row.name;
        });
    }

    // Folders and media files, folders first, by name.
    FolderListModel {
        id: folder
        folder: page.path === "" ? "" : page.fileUrl(page.path)
        showDirs: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
        nameFilters: Format.mediaNameFilters()
        sortField: FolderListModel.Name
        onStatusChanged: if (status === FolderListModel.Ready) page.readRows()
        onCountChanged: if (status === FolderListModel.Ready) page.readRows()
    }

    // Cards and sticks, where the system mounts them: /media/<user>, which
    // is only there while something is mounted. A model given a folder that
    // does not exist lists the app's own folder instead, so /media is looked
    // at first.
    property bool removableThere: false

    FolderListModel {
        id: mounts
        folder: "file:///media"
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        onStatusChanged: page.findRemovable()
        onCountChanged: page.findRemovable()
    }

    function findRemovable() {
        var there = false;
        for (var i = 0; mounts.status === FolderListModel.Ready && i < mounts.count; i++)
            if (mounts.get(i, "filePath") === removableRoot)
                there = true;
        removableThere = there;
    }

    FolderListModel {
        id: removable
        folder: page.removableThere ? page.fileUrl(page.removableRoot) : "file:///media"
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
    }

    // For "Play all" on a folder that is not the one shown.
    FolderListModel {
        id: other
        showDirs: true
        showDotAndDotDot: false
        showHidden: false
        nameFilters: Format.mediaNameFilters()
        sortField: FolderListModel.Name
        onStatusChanged: page.playPending()
    }

    onPathChanged: rows = []

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: page.path === "" ? "Browse" : page.nameOf(page.path)
        canGoBack: page.path !== ""
        onBack: page.back()
        trailing: Row {
            IconButton {
                visible: page.path !== "" && page.rows.some(function(row) { return !row.folder; })
                glyph: "play"
                color: Theme.text
                onClicked: page.playHere(null)
            }
            IconButton {
                visible: page.path !== ""
                glyph: "star"
                color: page.isFavourite ? Theme.accent : Theme.textDim
                onClicked: page.setFavourite(page.path, !page.isFavourite)
            }
        }
    }

    // The path bar: a tap on a folder of the path goes there.
    Flickable {
        id: pathBar
        anchors { left: parent.left; right: parent.right; top: header.bottom }
        height: page.crumbs.length > 1 ? Theme.u(5) : 0
        visible: height > 0
        contentWidth: crumbRow.width + Theme.u(4)
        clip: true
        // The end of the path is what matters.
        onContentWidthChanged: contentX = Math.max(0, contentWidth - width)

        Row {
            id: crumbRow
            x: Theme.u(2)
            height: parent.height

            Repeater {
                model: page.crumbs
                delegate: Row {
                    height: crumbRow.height

                    Text {
                        visible: index > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: "  ›  "
                        color: Theme.textFaint
                        font.pixelSize: Theme.fontS
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: index === page.crumbs.length - 1 ? Theme.text : Theme.accent
                        font.pixelSize: Theme.fontS

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -Theme.u(1)
                            onClicked: page.open(modelData.path)
                        }
                    }
                }
            }
        }
    }

    Text {
        visible: page.path !== "" && page.rows.length === 0 && folder.status === FolderListModel.Ready
        anchors.centerIn: parent
        width: parent.width - Theme.u(8)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "No folders, music or videos here."
        color: Theme.textDim
        font.pixelSize: Theme.fontM
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: pathBar.bottom; bottom: parent.bottom }
        clip: true
        model: page.shown

        delegate: Item {
            id: row
            width: list.width
            height: isSection ? Theme.u(5.5) : isNote ? noteText.height + Theme.u(3) : Theme.u(7.5)

            readonly property bool isSection: !!modelData.section
            readonly property bool isNote: !!modelData.note
            readonly property bool isFolder: !!modelData.folder
            readonly property bool isFile: !isSection && !isNote && !isFolder
            readonly property bool playing: isFile && modelData.media.url.toString() === page.playingUrl

            SectionLabel {
                visible: row.isSection
                text: row.isSection ? modelData.section : ""
            }

            Text {
                id: noteText
                visible: row.isNote
                anchors { left: parent.left; right: parent.right; top: parent.top
                          leftMargin: Theme.u(2); rightMargin: Theme.u(2); topMargin: Theme.u(1) }
                wrapMode: Text.WordWrap
                text: row.isNote ? modelData.note : ""
                color: Theme.textDim
                font.pixelSize: Theme.fontS
                lineHeight: 1.3
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: (row.isFolder || row.isFile) && rowMouse.pressed ? 0.06 : 0
            }

            Glyph {
                id: rowIcon
                visible: row.isFolder || row.isFile
                anchors { left: parent.left; leftMargin: Theme.u(2.5); verticalCenter: parent.verticalCenter }
                width: Theme.u(3)
                name: row.isFolder ? "folder" : row.isFile && modelData.media.hasPicture ? "video" : "audio"
                color: row.isFolder ? Theme.accent : row.playing ? Theme.accent : Theme.textDim
            }

            Column {
                visible: row.isFolder || row.isFile
                anchors { left: rowIcon.right; leftMargin: Theme.u(2); right: rowMore.left
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.4)

                Text {
                    width: parent.width
                    text: row.isFolder || row.isFile ? modelData.name : ""
                    color: row.playing ? Theme.accent : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideMiddle
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: row.isFile ? (modelData.media.duration > 0 ? Format.clock(modelData.media.duration) + "  •  " : "")
                                       + Format.fileSize(modelData.size)
                        : row.isFolder ? (modelData.detail || (modelData.removable ? "Removable storage" : "")) : ""
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideMiddle
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                enabled: row.isFolder || row.isFile
                onClicked: page.activate(modelData)
            }

            IconButton {
                id: rowMore
                visible: row.isFolder
                anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
                glyph: "more"
                onClicked: {
                    page.menuRow = modelData;
                    itemMenu.show();
                }
            }
        }
    }

    // A folder's menu.
    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuRow ? page.menuRow.name : ""
        options: {
            var row = page.menuRow;
            if (!row)
                return [];
            var favourite = page.favouriteFolders.indexOf(row.path) >= 0;
            return [
                { key: "open", label: "Open", glyph: "folder" },
                { key: "playAll", label: "Play all", glyph: "play" },
                { key: "favourite", glyph: "star", selected: favourite,
                  label: favourite ? "Remove from favourites" : "Add to favourites" }
            ];
        }
        onChosen: page.itemAction(page.menuRow, key)
    }
}
