import QtQuick 2.12
import Qt.labs.settings 1.0
import Gem 1.0
import "../js/Format.js" as Format
import "../js/AudioLibrary.js" as AudioLibrary

/*
 * The Audio tab: the music on the phone under VLC's four headings, artists,
 * albums, tracks and genres (docs/VLC-FEATURES.md, "Audio library"), and
 * under "Files", the plain list of audio files. An
 * artist, album or genre opens in place and lists its tracks; a tap on a
 * track plays the list it is in from that track on, behind the page, with
 * the mini-player showing it.
 *
 * What is listed and in which order is worked out in js/AudioLibrary.js.
 */
Item {
    id: page

    property var library: null          // platform/MediaLibrary.qml, or null off the device
    property var store: null            // PlayerStore: favourites
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property string playingUrl: ""      // the track that plays as audio now, to mark it

    property var tracks: []
    property string tab: "artists"      // one of AudioLibrary.TABS
    property string openKey: ""         // the artist, album or genre that is open; "" for none

    // The filter narrows the list of the tab, not of an open artist, album
    // or genre.
    property bool filtering: false
    property string filter: ""

    // Each tab keeps its own order. Favourites are tracks; "only favourites"
    // leaves every list with what those tracks make of it.
    property string sort: "name"
    property bool descending: false
    property bool onlyFavourites: false
    readonly property var favourites: store && store.favouriteRevision >= 0 ? store.favourites() : ({})

    readonly property var kept: onlyFavourites ? AudioLibrary.favouritesOnly(tracks, favourites) : tracks
    readonly property var topLevel: AudioLibrary.topLevel(AudioLibrary.filtered(kept, tab, filter), tab, sort, descending)
    readonly property var openItem: openKey ? AudioLibrary.findGroup(topLevel, openKey) : null
    // Rows: a group { kind, key, title, subtitle, tracks, art }, a track, or
    // a heading { section }.
    readonly property var shown: openKey ? (openItem ? AudioLibrary.rowsOf(openItem) : []) : topLevel

    // Multiple selection, as in the Video tab: { key: true } for each
    // selected row, by a track's address or a group's key. A long press
    // starts it, taps add and take out, and the bar in the header's place
    // acts on what is selected.
    property var selection: ({})
    readonly property int selectionCount: Object.keys(selection).length
    readonly property bool selecting: selectionCount > 0

    property var menuItem: null
    property var infoTrack: null        // the track whose information page is open

    // Play `list` from its item `index`. options: { asAudio, background }.
    signal playRequested(var list, int index, var options)
    // Add `list` to what plays: after the current item if `next`, otherwise
    // at the end.
    signal queueRequested(var list, bool next)

    function keyOf(item) {
        return item.tracks ? item.key : item.url;
    }

    function toggleSelected(item) {
        if (!item || item.section)
            return;
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

    // The selected tracks, the groups' included, in the order shown.
    function selectedTracks() {
        var list = [];
        for (var i = 0; i < shown.length; i++) {
            if (shown[i].section || !selection[keyOf(shown[i])])
                continue;
            if (shown[i].tracks)
                list = list.concat(shown[i].tracks);
            else
                list.push(shown[i]);
        }
        return list;
    }

    function allSelectedFavourites() {
        var list = selectedTracks();
        for (var i = 0; i < list.length; i++)
            if (!favourites[list[i].url])
                return false;
        return list.length > 0;
    }

    // What the selection bar's buttons do; each ends the selection, as in VLC.
    function selectionAction(key) {
        var list = selectedTracks();
        if (key === "favourite") {
            var on = !allSelectedFavourites();
            for (var i = 0; i < list.length; i++)
                store.setFavourite(list[i].url, on);
        }
        clearSelection();
        if (key === "play")
            play(list, 0);
        else if (key === "append" || key === "insertNext")
            queueRequested(list, key === "insertNext");
    }

    function reload() {
        tracks = library ? library.tracks() : [];
        if (openKey && !openItem)
            openKey = "";
    }

    function setTab(key) {
        tab = AudioLibrary.TABS[AudioLibrary.tabIndex(key)].key;
        clearSelection();
        openKey = "";
        _keep("tab", tab);
        _readSort();
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

    function _readSort() {
        var info = AudioLibrary.sortInfo(tab, settings.value("sort." + tab, "name"));
        sort = info ? info.key : "name";
        descending = info ? _flag("descending." + tab, false) : false;
    }

    function setSort(key, desc) {
        var info = AudioLibrary.sortInfo(tab, key);
        if (!info)
            return;
        sort = info.key;
        descending = desc;
        _keep("sort." + tab, sort);
        _keep("descending." + tab, desc);
    }

    function setOnlyFavourites(on) {
        onlyFavourites = on;
        _keep("onlyFavourites", on);
    }

    function openDisplaySheet() {
        search.dismiss();
        displaySheet.show();
    }

    // Leaves the open artist, album or genre, or else the filter; false if
    // there was neither.
    function back() {
        if (infoTrack) {
            infoTrack = null;
            return true;
        }
        if (selecting) {
            clearSelection();
            return true;
        }
        if (openKey) {
            openKey = "";
            return true;
        }
        if (filtering) {
            closeFilter();
            return true;
        }
        return false;
    }

    function openFilter() {
        filtering = true;
        search.open();
    }

    function closeFilter() {
        search.reset();
        filtering = false;
    }

    // For the development remote.
    function setFilter(text) {
        filtering = true;
        search.text = text;
    }

    // The tracks a row stands for, and those around a track.
    function tracksOf(item) {
        return item.tracks || [item];
    }

    function surrounding() {
        return openItem ? openItem.tracks : tab === "tracks" || tab === "files" ? topLevel : [];
    }

    function play(list, index) {
        playRequested(list, index, { asAudio: true, background: true });
    }

    // A tap on a row.
    function activate(item) {
        if (!item || item.section)
            return;
        search.dismiss();
        if (selecting) {
            toggleSelected(item);
            return;
        }
        if (item.tracks) {
            openKey = item.key;
            return;
        }
        var list = surrounding();
        for (var i = 0; i < list.length; i++) {
            if (list[i].url === item.url) {
                play(list, i);
                return;
            }
        }
        play([item], 0);
    }

    // One choice from a row's menu.
    function itemAction(item, key) {
        if (!item || item.section)
            return;
        if (key === "play")
            play(tracksOf(item), 0);
        else if (key === "append" || key === "insertNext")
            queueRequested(tracksOf(item), key === "insertNext");
        else if (key === "favourite" && !item.tracks)
            store.setFavourite(item.url, !favourites[item.url]);
        else if (key === "info" && !item.tracks)
            infoTrack = item;
        else if ((key === "goAlbum" || key === "goArtist") && !item.tracks)
            goTo(key === "goAlbum" ? "album" : "artist", item);
    }

    // Opens the album or the artist a track belongs to, in that list. What
    // would hide it there, the filter or "only favourites", is switched off.
    function goTo(kind, track) {
        var key = AudioLibrary.groupKey(kind, track);
        closeFilter();
        setTab(kind === "album" ? "albums" : "artists");
        if (!AudioLibrary.findGroup(topLevel, key))
            setOnlyFavourites(false);
        if (AudioLibrary.findGroup(topLevel, key))
            openKey = key;
    }

    function openItemMenu(index) {
        if (index >= 0 && index < shown.length && !shown[index].section) {
            menuItem = shown[index];
            itemMenu.show();
        }
    }

    function closeSheets() {
        itemMenu.close();
        displaySheet.close();
    }

    function shownTitles() {
        return shown.map(function(item) {
            return item.section ? "# " + item.section
                 : item.tracks ? item.title + " [" + item.tracks.length + "]"
                 : tab === "files" ? AudioLibrary.fileName(item) : item.title;
        });
    }

    onLibraryChanged: reload()
    onOpenKeyChanged: clearSelection()

    // The keyboard goes when the page does.
    onVisibleChanged: {
        if (!visible) {
            search.dismiss();
            clearSelection();
            infoTrack = null;
        }
    }

    Settings {
        id: settings
        category: "audioLibrary"
    }

    Component.onCompleted: {
        tab = AudioLibrary.TABS[AudioLibrary.tabIndex(settings.value("tab", "artists"))].key;
        onlyFavourites = _flag("onlyFavourites", false);
        _readSort();
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
        title: page.openItem ? page.openItem.title : "Audio"
        canGoBack: page.openKey.length > 0
        onBack: page.back()
        trailing: Row {
            IconButton {
                visible: page.openItem !== null
                glyph: "play"
                color: Theme.text
                onClicked: page.itemAction(page.openItem, "play")
            }
            IconButton {
                visible: !page.openKey
                glyph: "search"
                color: page.filtering ? Theme.accent : Theme.textDim
                onClicked: {
                    if (page.filtering)
                        page.closeFilter();
                    else
                        page.openFilter();
                }
            }
            IconButton {
                visible: !page.openKey
                glyph: "settings"
                color: page.onlyFavourites ? Theme.accent : Theme.textDim
                onClicked: page.openDisplaySheet()
            }
        }
    }

    // The selection bar, in the header's place.
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
                glyph: "play"
                color: Theme.text
                onClicked: page.selectionAction("play")
            }
            IconButton {
                glyph: "next"
                color: Theme.text
                onClicked: page.selectionAction("insertNext")
            }
            IconButton {
                glyph: "add"
                color: Theme.text
                onClicked: page.selectionAction("append")
            }
            IconButton {
                glyph: "star"
                color: page.selecting && page.allSelectedFavourites() ? Theme.accent : Theme.text
                onClicked: page.selectionAction("favourite")
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
        height: page.filtering && !page.openKey ? Theme.u(7) : 0
        visible: height > 0

        SearchField {
            id: search
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                      leftMargin: Theme.u(2); rightMargin: Theme.u(2) }
            placeholder: page.tab === "artists" ? "Filter artists" : page.tab === "albums" ? "Filter albums"
                       : page.tab === "genres" ? "Filter genres" : page.tab === "files" ? "Filter files"
                       : "Filter tracks"
            onTextChanged: page.filter = text
        }
    }

    Item {
        id: tabRow
        anchors { left: parent.left; right: parent.right; top: filterBar.bottom }
        height: page.openKey ? 0 : Theme.u(7)
        visible: !page.openKey

        SegmentedChoice {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                      leftMargin: Theme.u(2); rightMargin: Theme.u(2) }
            options: AudioLibrary.TABS.map(function(t) { return t.label; })
            currentIndex: AudioLibrary.tabIndex(page.tab)
            onChosen: page.setTab(AudioLibrary.TABS[index].key)
        }
    }

    Text {
        visible: page.shown.length === 0
        anchors.centerIn: parent
        width: parent.width - Theme.u(8)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: !page.library ? "The media library is not available."
              : page.tracks.length > 0 && page.filter.trim().length > 0
                ? "Nothing matches \u201c" + page.filter.trim() + "\u201d."
              : page.tracks.length > 0 && page.onlyFavourites
                ? "No favourites yet.\nA track's menu adds it to them."
              : "No music found.\nPut some in the Music folder and it will appear here."
        color: Theme.textDim
        font.pixelSize: Theme.fontM
        lineHeight: 1.3
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: tabRow.bottom; bottom: parent.bottom }
        clip: true
        model: page.shown
        onMovementStarted: search.dismiss()

        delegate: Item {
            id: row
            width: list.width
            height: isSection ? Theme.u(5.5) : Theme.u(8.25)

            readonly property bool isSection: !!modelData.section
            readonly property bool isGroup: !!modelData.tracks
            readonly property bool selected: !isSection && !!page.selection[page.keyOf(modelData)]
            readonly property bool asFile: page.tab === "files" && !isSection && !isGroup
            readonly property bool playing: !isSection && !isGroup && modelData.url === page.playingUrl

            SectionLabel {
                visible: row.isSection
                text: row.isSection ? modelData.section : ""
            }

            Rectangle {
                anchors.fill: parent
                color: row.selected ? Theme.accent : Theme.text
                opacity: row.selected ? 0.18 : (!row.isSection && rowMouse.pressed ? 0.06 : 0)
            }

            Rectangle {
                id: rowThumb
                visible: !row.isSection
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(6.25)
                height: width
                // Round for an artist, as VLC draws them.
                radius: row.isGroup && modelData.kind === "artist" ? width / 2 : Theme.u(0.5)
                color: Theme.surfaceAlt
                clip: true

                Glyph {
                    anchors.centerIn: parent
                    width: Theme.u(2.8)
                    name: "audio"
                    color: row.playing ? Theme.accent : Theme.textDim
                    visible: rowArt.status !== Image.Ready
                }
                // A favourite, marked as on a video's picture.
                Rectangle {
                    z: 1
                    visible: !row.isSection && !row.isGroup && !!page.favourites[modelData.url]
                    anchors { left: parent.left; bottom: parent.bottom; margins: Theme.u(0.4) }
                    width: Theme.u(2)
                    height: Theme.u(2)
                    radius: Theme.u(0.4)
                    color: Qt.rgba(0, 0, 0, 0.6)

                    Glyph {
                        anchors.centerIn: parent
                        width: Theme.u(1.3)
                        name: "star"
                        color: Theme.accent
                    }
                }
                Image {
                    id: rowArt
                    anchors.fill: parent
                    // An artist has no picture of their own; a cover would only stand for one album.
                    source: row.isSection || (row.isGroup && modelData.kind !== "album") ? "" : (modelData.art || "")
                    sourceSize: Qt.size(256, 256)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Column {
                visible: !row.isSection
                anchors { left: rowThumb.right; leftMargin: Theme.u(1.5); right: rowMore.left
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.5)

                Text {
                    width: parent.width
                    text: row.isSection ? "" : row.asFile ? AudioLibrary.fileName(modelData) : modelData.title
                    color: row.playing ? Theme.accent : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: row.isSection ? "" : row.isGroup ? modelData.subtitle
                          : row.asFile ? AudioLibrary.folderName(modelData) + "  \u2022  " + Format.clock(modelData.duration)
                          : AudioLibrary.artistOf(modelData) + "  •  " + Format.clock(modelData.duration)
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                enabled: !row.isSection
                onClicked: page.activate(modelData)
                onPressAndHold: page.toggleSelected(modelData)
            }

            IconButton {
                id: rowMore
                visible: !row.isSection && !page.selecting
                anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
                glyph: "more"
                onClicked: {
                    page.menuItem = modelData;
                    itemMenu.show();
                }
            }
        }
    }

    // A row's menu, in VLC's order.
    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuItem ? page.menuItem.title : ""
        options: {
            var item = page.menuItem;
            var rows = [
                { key: "play", label: item && item.tracks ? "Play all" : "Play", glyph: "play" },
                { key: "insertNext", label: "Insert next", glyph: "next" },
                { key: "append", label: "Add to play queue", glyph: "add" }
            ];
            if (item && !item.tracks && !item.section) {
                rows.push({ key: "info", label: "Information", glyph: "info" });
                if (page.store) {
                    var favourite = !!page.favourites[item.url];
                    rows.push({ key: "favourite", glyph: "star", selected: favourite,
                                label: favourite ? "Remove from favourites" : "Add to favourites" });
                }
                // Not to where one is already.
                var here = page.openItem ? page.openItem.kind : "";
                if (here !== "album")
                    rows.push({ key: "goAlbum", label: "Go to album", glyph: "playlist" });
                if (here !== "artist")
                    rows.push({ key: "goArtist", label: "Go to artist", glyph: "audio" });
            }
            return rows;
        }
        onChosen: page.itemAction(page.menuItem, key)
    }

    MediaInfoPage {
        parent: page.overlay
        anchors.fill: parent
        media: page.infoTrack
        favourite: page.infoTrack ? !!page.favourites[page.infoTrack.url] : false
        onCloseRequested: page.infoTrack = null
        onPlayRequested: {
            var track = page.infoTrack;
            page.infoTrack = null;
            page.play([track], 0);
        }
    }

    // What the list shows and in which order, as the Video tab has it.
    OptionSheet {
        id: displaySheet
        parent: page.overlay
        anchors.fill: parent
        title: "Display settings"
        options: {
            var rows = [
                { key: "favourites", label: "Show only favourites", glyph: "star",
                  selected: page.onlyFavourites, value: page.onlyFavourites ? "on" : "off", stay: true }
            ];
            var sorts = AudioLibrary.SORTS[page.tab] || [];
            if (sorts.length > 0)
                rows.push({ label: "Sort by\u2026" });
            for (var i = 0; i < sorts.length; i++) {
                var current = sorts[i].key === page.sort;
                rows.push({ key: "sort:" + sorts[i].key, label: sorts[i].label, selected: current, stay: true,
                            value: current ? (page.descending ? sorts[i].descending : sorts[i].ascending) : "" });
            }
            return rows;
        }
        onChosen: {
            if (key === "favourites")
                page.setOnlyFavourites(!page.onlyFavourites);
            else if (key.indexOf("sort:") === 0)
                page.setSort(key.substring(5), key.substring(5) === page.sort ? !page.descending : false);
        }
    }
}
