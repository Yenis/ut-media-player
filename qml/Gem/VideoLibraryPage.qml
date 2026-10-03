import QtQuick 2.12
import Qt.labs.settings 1.0
import Gem 1.0
import "../js/Format.js" as Format
import "../js/Library.js" as Library

/*
 * The Video tab: the videos on the phone, as a grid of cards or as a list,
 * sorted, filtered and narrowed to the favourites as VLC's display settings
 * allow. Grouping and the rest of the item menu go here.
 */
Item {
    id: page

    property var library: null          // platform/MediaLibrary.qml, or null off the device
    property var store: null            // PlayerStore
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property var videos: []

    // VLC's defaults: the grid ("video_display_in_cards"), by name, A to Z.
    property bool grid: true
    property string sort: "name"
    property bool descending: false
    property bool onlyFavourites: false

    property bool filtering: false
    property string filter: ""

    // What was played and what is a favourite, by address, read once per
    // change and not once per card.
    readonly property var played: store && store.revision >= 0 ? store.entries() : ({})
    readonly property var favourites: store && store.favouriteRevision >= 0 ? store.favourites() : ({})

    readonly property var shown: Library.arrange(videos, sort, descending, filter, onlyFavourites, favourites)

    property var menuVideo: null        // the video the item menu is open for

    signal mediaChosen(var media)

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

    function openDisplaySheet() { displaySheet.show(); }

    function closeSheets() {
        displaySheet.close();
        itemMenu.close();
    }

    function openItemMenu(index) {
        if (index >= 0 && index < shown.length)
            openMenuFor(shown[index]);
    }

    function openMenuFor(video) {
        menuVideo = video;
        itemMenu.show();
    }

    function shownTitles() {
        return shown.map(function(video) { return video.title; });
    }

    function progressOf(entry) {
        return entry && entry.duration > 0 ? entry.position / entry.duration : 0;
    }

    onLibraryChanged: reload()

    Settings {
        id: settings
        category: "videoLibrary"
    }

    Component.onCompleted: {
        grid = _flag("grid", true);
        sort = Library.sortInfo(settings.value("sort", "name")).key;
        descending = _flag("descending", false);
        onlyFavourites = _flag("onlyFavourites", false);
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
        title: "Video"
        canGoBack: false
        trailing: Row {
            IconButton {
                glyph: "search"
                color: page.filtering ? Theme.accent : Theme.textDim
                onClicked: {
                    if (page.filtering) {
                        page.closeFilter();
                    } else {
                        page.filtering = true;
                        search.open();
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
              : page.filter.trim().length > 0 ? "No video matches “" + page.filter.trim() + "”."
              : "No favourites yet.\nA video's menu adds it to them."
        color: Theme.textDim
        font.pixelSize: Theme.fontM
        lineHeight: 1.3
    }

    GridView {
        id: cards
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

            readonly property var entry: page.played[modelData.url] || null

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: cardMouse.pressed ? 0.06 : 0
            }

            VideoThumb {
                id: cardThumb
                anchors { left: parent.left; right: parent.right; top: parent.top
                          leftMargin: cards.pad; rightMargin: cards.pad; topMargin: cards.pad }
                height: width * 10 / 16
                art: modelData.art
                resolution: Format.resolutionClass(modelData.width, modelData.height)
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
                text: Format.clock(modelData.duration)
                color: Theme.textFaint
                font.pixelSize: Theme.fontXS
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                onClicked: page.mediaChosen(modelData)
            }

            // The item menu, on the thumbnail's corner as in VLC.
            IconButton {
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
        visible: !page.grid
        anchors { left: parent.left; right: parent.right; top: filterBar.bottom; bottom: parent.bottom }
        clip: true
        model: page.grid ? [] : page.shown

        delegate: Item {
            id: row
            width: list.width
            height: Theme.u(8.25)

            readonly property var entry: page.played[modelData.url] || null
            readonly property string resolution: Format.resolutionClass(modelData.width, modelData.height)

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: rowMouse.pressed ? 0.06 : 0
            }

            VideoThumb {
                id: rowThumb
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(10)
                height: Theme.u(6.25)
                sourcePixels: 256
                art: modelData.art
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
                    text: Format.clock(modelData.duration) + (row.resolution ? "  •  " + row.resolution : "")
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                onClicked: page.mediaChosen(modelData)
            }

            IconButton {
                id: rowMore
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
            else if (key.indexOf("sort:") === 0)
                page.setSort(key.substring(5), key.substring(5) === page.sort ? !page.descending : false);
        }
    }

    // A video's own menu. VLC's has many more entries; they join it with the
    // item menu step of Phase 2.
    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuVideo ? page.menuVideo.title : ""
        options: {
            var favourite = page.menuVideo ? !!page.favourites[page.menuVideo.url] : false;
            return [
                { key: "play", label: "Play", glyph: "play" },
                { key: "favourite", glyph: "star", selected: favourite,
                  label: favourite ? "Remove from favourites" : "Add to favourites" }
            ];
        }
        onChosen: {
            if (key === "play")
                page.mediaChosen(page.menuVideo);
            else if (key === "favourite")
                page.toggleFavourite(page.menuVideo.url);
        }
    }
}
