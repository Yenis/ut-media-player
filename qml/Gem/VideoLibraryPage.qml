import QtQuick 2.12
import Qt.labs.settings 1.0
import Gem 1.0
import "../js/Format.js" as Format
import "../js/Library.js" as Library

/*
 * The Video tab: the videos on the phone, as a grid of cards or as a list,
 * sorted, filtered, narrowed to the favourites and grouped by folder or by
 * name as VLC's display settings allow. A folder or group opens in place,
 * with a way back in the header. Every entry has a menu behind its three
 * dots, and a long press starts a selection, as in VLC. "Information" in a
 * video's menu opens a page about it over this one.
 */
Item {
    id: page

    property var library: null          // platform/MediaLibrary.qml, or null off the device
    property var store: null            // PlayerStore
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property var videos: []

    // VLC's defaults: the grid ("video_display_in_cards"), by name, A to Z,
    // grouped by name.
    property bool grid: true
    property string sort: "name"
    property bool descending: false
    property bool onlyFavourites: false
    property string grouping: "name"    // "name", "folder" or "none"

    // The folder or group being looked into, by its key; empty at the top.
    property string openKey: ""

    property bool filtering: false
    property string filter: ""

    // What was played and what is a favourite, by address, read once per
    // change and not once per card.
    readonly property var played: store && store.revision >= 0 ? store.entries() : ({})
    readonly property var favourites: store && store.favouriteRevision >= 0 ? store.favourites() : ({})

    // The videos that pass, in order; then the top level they form; then what
    // is on screen, which is a folder's or group's content once one is open.
    // An entry of `shown` with `videos` is a folder or group, any other a video.
    readonly property var arranged: Library.arrange(videos, sort, descending, filter, onlyFavourites, favourites)
    // Groups made by hand; they count under "Group by name" only.
    readonly property var manualGroups: store && store.groupRevision >= 0 ? store.videoGroups() : ({ names: {}, members: {} })
    readonly property bool canGroup: grouping === "name"
    readonly property var topLevel: Library.grouped(arranged, grouping, sort, descending, manualGroups)
    readonly property var openItem: openKey ? Library.findGroup(topLevel, openKey) : null
    readonly property var shown: openKey ? (openItem ? openItem.videos : []) : topLevel

    // What a tap on a video does: "play", or "playAll" for everything shown
    // from that video on. VLC's "Playback action"; its other two choices
    // wait for a player that keeps playing behind the library.
    property string tapAction: "play"

    // Multiple selection: { key: true } for each selected entry, by a video's
    // address or a folder's or group's key.
    property var selection: ({})
    readonly property int selectionCount: Object.keys(selection).length
    readonly property bool selecting: selectionCount > 0

    property var groupingVideos: []     // the videos "Add to video group" is about
    property var renamingGroup: null    // the group "Rename video group" is about

    property var infoVideo: null        // the video the information page shows

    property var menuItem: null         // the video, folder or group the item menu is open for

    // Play `list` from its item `index`. options: { fromStart, asAudio }.
    signal playRequested(var list, int index, var options)

    function reload() {
        videos = library ? library.videos() : [];
    }

    function _keep(key, value) {
        settings.setValue(key, value);
        settings.sync();
    }

    // Settings hands a stored true back as the text "true".
    function _flag(key, fallback) {
        var value = settings.value(key, fallback);
        return value === true || value === "true";
    }

    function setGrid(on) {
        grid = on;
        _keep("grid", on);
    }

    function setSort(key, desc) {
        sort = Library.sortInfo(key).key;
        descending = desc;
        _keep("sort", sort);
        _keep("descending", desc);
    }

    function setTapAction(action) {
        tapAction = action === "playAll" ? "playAll" : "play";
        _keep("tapAction", tapAction);
    }

    function keyOf(item) {
        return item.videos ? item.key : item.url;
    }

    function toggleSelected(item) {
        search.dismiss();
        var next = {};
        for (var key in selection)
            next[key] = true;
        if (next[keyOf(item)])
            delete next[keyOf(item)];
        else
            next[keyOf(item)] = true;
        selection = next;
    }

    function clearSelection() {
        selection = ({});
    }

    // The selected videos, the folders' and groups' included, in the order shown.
    function selectedVideos() {
        var list = [];
        for (var i = 0; i < shown.length; i++) {
            if (!selection[keyOf(shown[i])])
                continue;
            if (shown[i].videos)
                list = list.concat(shown[i].videos);
            else
                list.push(shown[i]);
        }
        return list;
    }

    function allSelectedFavourites() {
        var videos = selectedVideos();
        for (var i = 0; i < videos.length; i++)
            if (!favourites[videos[i].url])
                return false;
        return videos.length > 0;
    }

    // ---- groups made by hand ---------------------------------------------------

    function _urls(videos) {
        return videos.map(function(video) { return video.url; });
    }

    // A group that formed by name becomes one kept by hand, so that it can
    // take a name and members of its own. Returns its id.
    function _groupId(group) {
        return group.groupId > 0 ? group.groupId : store.createVideoGroup(group.title, _urls(group.videos));
    }

    function addToGroup(videos) {
        if (videos.length === 0)
            return;
        groupingVideos = videos;
        groupPicker.show();
    }

    function addToNewGroup(videos, name) {
        store.createVideoGroup(name, _urls(videos));
    }

    function addToExistingGroup(videos, key) {
        var group = Library.findGroup(Library.grouped(arranged, "name", sort, descending, manualGroups), key);
        if (group)
            store.setVideoGroup(_urls(videos), _groupId(group));
        _leaveIfGone();
    }

    // A group left with one video is no group any more; if it was the one
    // being looked into, go back to the top.
    function _leaveIfGone() {
        if (openKey && !openItem && !filter.trim() && !onlyFavourites)
            openKey = "";
    }

    function renameGroup(group, name) {
        store.renameVideoGroup(_groupId(group), name);
        openKey = "";
    }

    // Its videos stand alone afterwards, and do not fall back into a group
    // by name: that is what "Regroup automatically" is for.
    function ungroup(group) {
        store.setVideoGroup(_urls(group.videos), 0);
        openKey = "";
    }

    // Placed by hand: kept on its own, or the last one left in a group.
    function isAlone(video) {
        return manualGroups.members[video.url] !== undefined;
    }

    // What the selection bar's buttons do; each ends the selection, as in VLC.
    function selectionAction(key) {
        var videos = selectedVideos();
        if (key === "group") {
            clearSelection();
            addToGroup(videos);
            return;
        }
        if (key === "info") {
            clearSelection();
            infoVideo = videos[0];
            return;
        }
        if (key === "favourite") {
            var on = !allSelectedFavourites();
            for (var i = 0; i < videos.length; i++)
                store.setFavourite(videos[i].url, on);
        }
        clearSelection();
        if (key === "play")
            playRequested(videos, 0, {});
        else if (key === "asAudio")
            playRequested(videos, 0, { asAudio: true });
    }

    function setGrouping(key) {
        grouping = Library.groupingInfo(key).key;
        clearSelection();
        openKey = "";
        _keep("grouping", grouping);
    }

    // Ends a selection, or leaves the open folder or group; false if there
    // was neither.
    function back() {
        if (infoVideo) {
            infoVideo = null;
            return true;
        }
        if (selecting) {
            clearSelection();
            return true;
        }
        if (!openKey)
            return false;
        openKey = "";
        return true;
    }

    // A tap on an entry.
    function activate(item) {
        search.dismiss();
        if (selecting)
            toggleSelected(item);
        else if (item.videos)
            openKey = item.key;
        else
            itemAction(item, tapAction);
    }

    // Every video on screen, the folders' and groups' included, in order.
    function allShown() {
        var list = [];
        for (var i = 0; i < shown.length; i++) {
            if (shown[i].videos)
                list = list.concat(shown[i].videos);
            else
                list.push(shown[i]);
        }
        return list;
    }

    // One choice from an entry's menu.
    function itemAction(item, key) {
        if (!item)
            return;
        var videos = item.videos || [item];
        if (key === "play") {
            playRequested(videos, 0, {});
        } else if (key === "fromStart") {
            playRequested([item], 0, { fromStart: true });
        } else if (key === "playAll") {
            // From this video on through everything shown; a folder or group
            // plays its own videos.
            if (item.videos) {
                playRequested(videos, 0, {});
            } else {
                var all = allShown();
                var at = 0;
                for (var i = 0; i < all.length; i++)
                    if (all[i].url === item.url)
                        at = i;
                playRequested(all, at, {});
            }
        } else if (key === "asAudio") {
            playRequested([item], 0, { asAudio: true });
        } else if (key === "played" || key === "notPlayed") {
            for (var k = 0; k < videos.length; k++)
                store.setSeen(videos[k].url, key === "played", videos[k].duration);
        } else if (key === "favourite") {
            toggleFavourite(item.url);
        } else if (key === "info") {
            search.dismiss();
            infoVideo = item;
        } else if (key === "addToGroup") {
            addToGroup(videos);
        } else if (key === "removeFromGroup") {
            store.setVideoGroup([item.url], 0);
            _leaveIfGone();
        } else if (key === "regroup") {
            store.regroupVideos([item.url]);
        } else if (key === "rename") {
            renamingGroup = item;
            renameDialog.show(item.title);
        } else if (key === "ungroup") {
            ungroup(item);
        }
    }

    function allSeen(videos) {
        for (var i = 0; i < videos.length; i++) {
            var entry = played[videos[i].url];
            if (!entry || !(entry.seen > 0))
                return false;
        }
        return videos.length > 0;
    }

    function arts(videos) {
        return videos.map(function(video) { return video.art; });
    }

    function countLabel(videos) {
        return videos.length === 1 ? "1 video" : videos.length + " videos";
    }

    function setOnlyFavourites(on) {
        onlyFavourites = on;
        _keep("onlyFavourites", on);
    }

    function setFilter(text) {
        filtering = true;
        search.text = text;
    }

    function closeFilter() {
        search.reset();
        filtering = false;
    }

    function toggleFavourite(url) {
        store.setFavourite(url, !favourites[url]);
    }

    function dismissKeyboard() { search.dismiss(); }

    function openFilter() {
        filtering = true;
        search.open();
    }

    function openDisplaySheet() {
        search.dismiss();
        displaySheet.show();
    }

    function closeSheets() {
        displaySheet.close();
        groupingSheet.close();
        itemMenu.close();
        groupPicker.close();
        newGroupDialog.close();
        renameDialog.close();
    }

    function openItemMenu(index) {
        if (index >= 0 && index < shown.length)
            openMenuFor(shown[index]);
    }

    function openMenuFor(item) {
        search.dismiss();
        menuItem = item;
        itemMenu.show();
    }

    function shownTitles() {
        return shown.map(function(item) {
            return item.videos ? item.title + " [" + item.videos.length + "]" : item.title;
        });
    }

    function progressOf(entry) {
        return entry && entry.duration > 0 ? entry.position / entry.duration : 0;
    }

    onLibraryChanged: reload()
    onOpenKeyChanged: clearSelection()

    // The keyboard and a selection go when the page does: another tab, or a video.
    onVisibleChanged: {
        if (!visible) {
            search.dismiss();
            clearSelection();
            infoVideo = null;
        }
    }

    Settings {
        id: settings
        category: "videoLibrary"
    }

    Component.onCompleted: {
        grid = _flag("grid", true);
        sort = Library.sortInfo(settings.value("sort", "name")).key;
        descending = _flag("descending", false);
        onlyFavourites = _flag("onlyFavourites", false);
        grouping = Library.groupingInfo(settings.value("grouping", "name")).key;
        tapAction = settings.value("tapAction", "play") === "playAll" ? "playAll" : "play";
    }

    Connections {
        target: page.library
        ignoreUnknownSignals: true
        onChanged: page.reload()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: page.openItem ? page.openItem.title : "Video"
        canGoBack: page.openKey.length > 0
        onBack: page.back()
        trailing: Row {
            IconButton {
                glyph: "search"
                color: page.filtering ? Theme.accent : Theme.textDim
                onClicked: {
                    if (page.filtering) {
                        page.closeFilter();
                    } else {
                        page.openFilter();
                    }
                }
            }
            IconButton {
                glyph: "settings"
                color: page.onlyFavourites ? Theme.accent : Theme.textDim
                onClicked: page.openDisplaySheet()
            }
        }
    }

    // While entries are selected, this takes the header's place: a way out,
    // how many, and what can be done with them.
    Rectangle {
        visible: page.selecting
        anchors.fill: header
        color: Theme.surface

        IconButton {
            id: selectionClose
            anchors { left: parent.left; leftMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
            glyph: "clear"
            color: Theme.text
            onClicked: page.clearSelection()
        }
        Text {
            anchors { left: selectionClose.right; leftMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
            text: page.selectionCount + " selected"
            color: Theme.text
            font.pixelSize: Theme.fontL
            font.bold: true
        }
        Row {
            anchors { right: parent.right; rightMargin: Theme.u(1); verticalCenter: parent.verticalCenter }

            IconButton {
                // For one video only, as in VLC.
                visible: page.selectionCount === 1 && page.selectedVideos().length === 1
                glyph: "info"
                color: Theme.text
                onClicked: page.selectionAction("info")
            }
            IconButton {
                glyph: "play"
                color: Theme.text
                onClicked: page.selectionAction("play")
            }
            IconButton {
                glyph: "audio"
                color: Theme.text
                onClicked: page.selectionAction("asAudio")
            }
            IconButton {
                glyph: "star"
                color: page.selecting && page.allSelectedFavourites() ? Theme.accent : Theme.text
                onClicked: page.selectionAction("favourite")
            }
            IconButton {
                visible: page.canGroup
                glyph: "folder"
                color: Theme.text
                onClicked: page.selectionAction("group")
            }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.line
        }
    }

    Item {
        id: filterBar
        anchors { left: parent.left; right: parent.right; top: header.bottom }
        height: page.filtering ? Theme.u(7) : 0
        visible: page.filtering

        SearchField {
            id: search
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                      leftMargin: Theme.u(2); rightMargin: Theme.u(2) }
            placeholder: "Filter videos"
            onTextChanged: page.filter = text
        }
    }

    Text {
        visible: page.shown.length === 0
        anchors.centerIn: parent
        width: parent.width - Theme.u(8)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: !page.library ? "The media library is not available."
              : page.videos.length === 0 ? "No videos found.\nPut some in the Videos folder and they will appear here."
              : page.openKey && !page.filter.trim() && !page.onlyFavourites ? "No videos here."
              : page.filter.trim().length > 0 ? "No video matches “" + page.filter.trim() + "”."
              : "No favourites yet.\nA video's menu adds it to them."
        color: Theme.textDim
        font.pixelSize: Theme.fontM
        lineHeight: 1.3
    }

    // A tap beside the results puts the keyboard away, as does moving them.
    MouseArea {
        anchors { left: parent.left; right: parent.right; top: filterBar.bottom; bottom: parent.bottom }
        onClicked: search.dismiss()
    }

    GridView {
        id: cards
        onMovementStarted: search.dismiss()
        visible: page.grid
        anchors { left: parent.left; right: parent.right; top: filterBar.bottom; bottom: parent.bottom
                  leftMargin: Theme.u(0.5); rightMargin: Theme.u(0.5) }
        topMargin: Theme.u(0.5)
        clip: true
        model: page.grid ? page.shown : []

        // As many 160 dp columns as fit, and never fewer than two.
        readonly property int columns: Math.max(2, Math.floor(width / Theme.u(20)))
        readonly property real pad: Theme.u(1)

        cellWidth: Math.floor(width / columns)
        cellHeight: Math.round(pad + (cellWidth - 2 * pad) * 10 / 16 + Theme.u(0.5)
                               + Theme.fontM * 1.4 + Theme.fontXS * 1.5 + Theme.u(1))

        delegate: Item {
            id: card
            width: cards.cellWidth
            height: cards.cellHeight

            readonly property bool isGroup: !!modelData.videos
            readonly property bool selected: !!page.selection[page.keyOf(modelData)]
            readonly property var entry: isGroup ? null : (page.played[modelData.url] || null)

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: cardMouse.pressed ? 0.06 : 0
            }

            GroupThumb {
                visible: card.isGroup
                anchors.fill: cardThumb
                folder: card.isGroup && modelData.kind === "folder"
                arts: card.isGroup ? page.arts(modelData.videos) : []
                seen: card.isGroup && page.allSeen(modelData.videos)
            }
            VideoThumb {
                id: cardThumb
                opacity: card.isGroup ? 0 : 1
                anchors { left: parent.left; right: parent.right; top: parent.top
                          leftMargin: cards.pad; rightMargin: cards.pad; topMargin: cards.pad }
                height: width * 10 / 16
                art: card.isGroup ? "" : modelData.art
                resolution: card.isGroup ? "" : Format.resolutionClass(modelData.width, modelData.height)
                seen: card.entry !== null && card.entry.seen > 0
                favourite: !!page.favourites[modelData.url]
                progress: page.progressOf(card.entry)
            }
            Text {
                id: cardTitle
                anchors { left: cardThumb.left; right: cardThumb.right; top: cardThumb.bottom; topMargin: Theme.u(0.5) }
                text: modelData.title
                color: Theme.text
                font.pixelSize: Theme.fontM
                elide: Text.ElideRight
            }
            Text {
                anchors { left: cardThumb.left; right: cardThumb.right; top: cardTitle.bottom }
                text: card.isGroup ? page.countLabel(modelData.videos) : Format.clock(modelData.duration)
                color: Theme.textFaint
                font.pixelSize: Theme.fontXS
            }

            Rectangle {
                visible: card.selected
                anchors.fill: cardThumb
                radius: cardThumb.radius
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                border.width: Math.max(2, Theme.u(0.3))
                border.color: Theme.accent

                Glyph {
                    anchors { right: parent.right; top: parent.top; margins: Theme.u(1) }
                    width: Theme.u(2.6)
                    name: "check"
                    color: "white"
                }
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                onClicked: page.activate(modelData)
                onPressAndHold: page.toggleSelected(modelData)
            }

            // The item menu, on the thumbnail's corner as in VLC.
            IconButton {
                visible: !page.selecting
                anchors { right: cardThumb.right; top: cardThumb.top }
                implicitWidth: Theme.u(4.5)
                implicitHeight: Theme.u(4.5)
                glyphSize: Theme.u(2.2)
                glyph: "more"
                color: "white"
                onClicked: page.openMenuFor(modelData)
            }
        }
    }

    ListView {
        id: list
        onMovementStarted: search.dismiss()
        visible: !page.grid
        anchors { left: parent.left; right: parent.right; top: filterBar.bottom; bottom: parent.bottom }
        clip: true
        model: page.grid ? [] : page.shown

        delegate: Item {
            id: row
            width: list.width
            height: Theme.u(8.25)

            readonly property bool isGroup: !!modelData.videos
            readonly property bool selected: !!page.selection[page.keyOf(modelData)]
            readonly property var entry: isGroup ? null : (page.played[modelData.url] || null)
            readonly property string resolution: isGroup ? "" : Format.resolutionClass(modelData.width, modelData.height)

            Rectangle {
                anchors.fill: parent
                color: row.selected ? Theme.accent : Theme.text
                opacity: row.selected ? 0.18 : (rowMouse.pressed ? 0.06 : 0)
            }

            GroupThumb {
                visible: row.isGroup
                anchors.fill: rowThumb
                folder: row.isGroup && modelData.kind === "folder"
                arts: row.isGroup ? page.arts(modelData.videos) : []
                seen: row.isGroup && page.allSeen(modelData.videos)
            }
            VideoThumb {
                id: rowThumb
                opacity: row.isGroup ? 0 : 1
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(10)
                height: Theme.u(6.25)
                sourcePixels: 256
                art: row.isGroup ? "" : modelData.art
                seen: row.entry !== null && row.entry.seen > 0
                favourite: !!page.favourites[modelData.url]
                progress: page.progressOf(row.entry)
            }

            Column {
                anchors { left: rowThumb.right; leftMargin: Theme.u(1.5); right: rowMore.left
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.5)

                Text {
                    width: parent.width
                    text: modelData.title
                    color: Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: row.isGroup ? page.countLabel(modelData.videos)
                          : Format.clock(modelData.duration) + (row.resolution ? "  •  " + row.resolution : "")
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                onClicked: page.activate(modelData)
                onPressAndHold: page.toggleSelected(modelData)
            }

            Glyph {
                visible: row.selected
                anchors.centerIn: rowMore
                width: Theme.u(2.6)
                name: "check"
                color: Theme.accent
            }

            IconButton {
                id: rowMore
                opacity: page.selecting ? 0 : 1
                enabled: !page.selecting
                anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
                glyphSize: Theme.u(2.2)
                glyph: "more"
                onClicked: page.openMenuFor(modelData)
            }
        }
    }

    // VLC's display settings: grid or list, only favourites, and the order.
    // Choosing the order already in use turns it round.
    OptionSheet {
        id: displaySheet
        parent: page.overlay
        anchors.fill: parent
        title: "Display settings"
        options: {
            var rows = [
                { key: "view", label: page.grid ? "Display in list" : "Display in grid",
                  glyph: page.grid ? "list" : "grid", stay: true },
                { key: "favourites", label: "Show only favourites", glyph: "star",
                  selected: page.onlyFavourites, value: page.onlyFavourites ? "on" : "off", stay: true },
                { key: "grouping", label: "Group videos", glyph: "folder",
                  value: Library.groupingInfo(page.grouping).short },
                { key: "tapAction", label: "Playback action", glyph: "play", stay: true,
                  value: page.tapAction === "playAll" ? "Play all" : "Play" },
                { label: "Sort by…" }
            ];
            for (var i = 0; i < Library.SORTS.length; i++) {
                var s = Library.SORTS[i];
                var current = s.key === page.sort;
                rows.push({ key: "sort:" + s.key, label: s.label, selected: current, stay: true,
                            value: current ? (page.descending ? s.descending : s.ascending) : "" });
            }
            return rows;
        }
        onChosen: {
            if (key === "view")
                page.setGrid(!page.grid);
            else if (key === "favourites")
                page.setOnlyFavourites(!page.onlyFavourites);
            else if (key === "grouping")
                groupingSheet.show();
            else if (key === "tapAction")
                page.setTapAction(page.tapAction === "playAll" ? "play" : "playAll");
            else if (key.indexOf("sort:") === 0)
                page.setSort(key.substring(5), key.substring(5) === page.sort ? !page.descending : false);
        }
    }

    OptionSheet {
        id: groupingSheet
        parent: page.overlay
        anchors.fill: parent
        title: "Group videos"
        options: Library.GROUPINGS.map(function(g) {
            return { key: g.key, label: g.label, selected: g.key === page.grouping };
        })
        onChosen: page.setGrouping(key)
    }

    // An entry's own menu, in VLC's order (ContextSheet.kt). An entry appears
    // only when it can do something: the queue entries wait for a player that
    // keeps playing behind the library, playlists and groups for theirs.
    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuItem ? page.menuItem.title : ""
        options: {
            var item = page.menuItem;
            if (!item)
                return [];
            if (item.videos) {
                var all = page.allSeen(item.videos);
                var groupRows = [{ key: "playAll", label: "Play all", glyph: "playlist" }];
                if (item.kind === "group") {
                    groupRows.push({ key: "rename", label: "Rename video group", glyph: "subtitles" });
                    groupRows.push({ key: "ungroup", label: "Ungroup", glyph: "clear" });
                }
                groupRows.push({ key: all ? "notPlayed" : "played", glyph: "check",
                                 label: all ? "Mark all as not played" : "Mark all as played" });
                return groupRows;
            }
            var entry = page.played[item.url] || null;
            var seen = entry !== null && entry.seen > 0;
            var favourite = !!page.favourites[item.url];
            var rows = [{ key: "play", label: "Play", glyph: "play" }];
            if (entry !== null && entry.position > 0)
                rows.push({ key: "fromStart", label: "Play from start", glyph: "previous" });
            if (page.allShown().length > 1)
                rows.push({ key: "playAll", label: "Play all", glyph: "playlist" });
            rows.push({ key: "asAudio", label: "Play as audio", glyph: "audio" });
            rows.push({ key: "info", label: "Information", glyph: "info" });
            rows.push({ key: "favourite", glyph: "star", selected: favourite,
                        label: favourite ? "Remove from favourites" : "Add to favourites" });
            if (page.canGroup) {
                rows.push({ key: "addToGroup", label: "Add to video group", glyph: "folder" });
                if (page.openItem && page.openItem.kind === "group")
                    rows.push({ key: "removeFromGroup", label: "Remove from video group", glyph: "clear" });
                else if (page.isAlone(item))
                    rows.push({ key: "regroup", label: "Regroup automatically", glyph: "refresh" });
            }
            rows.push({ key: seen ? "notPlayed" : "played", glyph: "check",
                        label: seen ? "Mark as not played" : "Mark as played" });
            return rows;
        }
        onChosen: page.itemAction(page.menuItem, key)
    }
    MediaInfoPage {
        parent: page.overlay
        anchors.fill: parent
        media: page.infoVideo
        entry: page.infoVideo ? (page.played[page.infoVideo.url] || null) : null
        favourite: page.infoVideo ? !!page.favourites[page.infoVideo.url] : false
        onCloseRequested: page.infoVideo = null
        onPlayRequested: {
            var video = page.infoVideo;
            page.infoVideo = null;
            page.playRequested([video], 0, {});
        }
    }

    // "Add to video group": a new group, as VLC offers for more than one
    // video, or one of the groups there are.
    OptionSheet {
        id: groupPicker
        parent: page.overlay
        anchors.fill: parent
        title: "Add to video group"
        options: {
            if (!open)
                return [];
            var rows = [];
            if (page.groupingVideos.length > 1)
                rows.push({ key: "new", label: "New group", glyph: "add" });
            var all = Library.grouped(page.arranged, "name", page.sort, page.descending, page.manualGroups);
            for (var i = 0; i < all.length; i++)
                if (all[i].videos)
                    rows.push({ key: all[i].key, label: all[i].title, glyph: "folder",
                                value: page.countLabel(all[i].videos) });
            if (rows.length === 0)
                rows.push({ label: "There are no groups yet. Select two or more videos to make one." });
            return rows;
        }
        onChosen: {
            if (key === "new")
                newGroupDialog.show(Library.commonTitle(page.groupingVideos));
            else
                page.addToExistingGroup(page.groupingVideos, key);
        }
    }

    NameDialog {
        id: newGroupDialog
        parent: page.overlay
        anchors.fill: parent
        title: "New group"
        confirmLabel: "Create"
        onAccepted: page.addToNewGroup(page.groupingVideos, name)
    }

    NameDialog {
        id: renameDialog
        parent: page.overlay
        anchors.fill: parent
        title: "Rename video group"
        confirmLabel: "Rename"
        onAccepted: page.renameGroup(page.renamingGroup, name)
    }
}
