import QtQuick 2.12
import Gem 1.0
import "../js/AudioLibrary.js" as AudioLibrary
import "../js/Format.js" as Format

/*
 * Search, behind the More tab: one text looked for across the whole
 * library, after VLC's SearchActivity (docs/VLC-FEATURES.md, "Search").
 * The results come in sections: videos, artists, albums, tracks, genres and
 * playlists. A video or a track plays; an artist, an album, a genre or a
 * playlist is opened where it lives, in its own tab.
 *
 * Each tab still has its own filter for its own list; this is the one place
 * that looks everywhere.
 */
Item {
    id: page

    property var library: null          // platform/MediaLibrary.qml, or null off the device
    property var store: null            // PlayerStore: the playlists
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property string playingUrl: ""      // what plays as audio now, to mark it

    property string query: ""
    property var videos: []
    property var tracks: []
    property var menuRow: null

    // A section lists this many; a line under it says how many more there are.
    readonly property int sectionLimit: 20

    signal closeRequested()
    // Play `list` from its item `index`. options: { asAudio, background }.
    signal playRequested(var list, int index, var options)
    signal queueRequested(var list, bool next)
    signal playlistRequested(var list)
    // Open an artist, album or genre in the Audio tab, or a playlist in its own.
    signal groupRequested(string listKey, string key)
    signal playlistOpenRequested(int playlistId)

    // The library as it is now: read when the page comes up, not on every key.
    function reload() {
        videos = library ? library.videos() : [];
        tracks = library ? library.tracks() : [];
    }

    function open() {
        reload();
        field.open();
    }

    function has(text, needle) {
        return (text || "").toLowerCase().indexOf(needle) >= 0;
    }

    function _section(rows, title, found) {
        if (found.length === 0)
            return;
        rows.push({ section: title + "  •  " + found.length });
        for (var i = 0; i < found.length && i < sectionLimit; i++)
            rows.push(found[i]);
        if (found.length > sectionLimit)
            rows.push({ note: (found.length - sectionLimit) + " more. Type more to narrow it down." });
    }

    // Every result, section by section: a heading is { section }, a line of
    // text { note }, and a result { kind, title, detail, art, ... }.
    readonly property var rows: {
        var needle = query.trim().toLowerCase();
        var list = [];
        if (needle.length === 0)
            return list;

        var foundVideos = [];
        for (var v = 0; v < videos.length; v++)
            if (has(videos[v].title, needle))
                foundVideos.push({ kind: "video", title: videos[v].title, detail: Format.clock(videos[v].duration),
                                   art: videos[v].art, media: videos[v] });
        foundVideos.sort(function(a, b) { return a.title.toLowerCase() < b.title.toLowerCase() ? -1 : 1; });
        _section(list, "Videos", foundVideos);

        var kinds = [["artists", "Artists"], ["albums", "Albums"]];
        for (var k = 0; k < kinds.length; k++) {
            var groups = AudioLibrary.topLevel(AudioLibrary.filtered(tracks, kinds[k][0], needle), kinds[k][0], "name", false);
            _section(list, kinds[k][1], groups.map(function(group) {
                return { kind: group.kind, title: group.title, detail: group.subtitle, art: group.kind === "album" ? group.art : "",
                         tab: kinds[k][0], key: group.key, tracks: group.tracks };
            }));
        }

        // By title only: a track whose artist or album matches is found
        // through that artist or album above.
        var matching = tracks.filter(function(t) { return page.has(t.title, needle); });
        var named = AudioLibrary.topLevel(matching, "tracks", "name", false);
        _section(list, "Tracks", named.map(function(t) {
            return { kind: "track", title: t.title, detail: AudioLibrary.artistOf(t) + "  •  " + Format.clock(t.duration),
                     art: t.art, media: t };
        }));

        var genres = AudioLibrary.topLevel(AudioLibrary.filtered(tracks, "genres", needle), "genres", "name", false);
        _section(list, "Genres", genres.map(function(group) {
            return { kind: "genre", title: group.title, detail: group.subtitle, art: "", tab: "genres", key: group.key,
                     tracks: group.tracks };
        }));

        var playlists = store && store.playlistRevision >= 0 ? store.playlists() : [];
        _section(list, "Playlists", playlists.filter(function(p) { return page.has(p.name, needle); }).map(function(p) {
            return { kind: "playlist", title: p.name, detail: p.count === 1 ? "1 item" : p.count + " items", art: p.art, id: p.id };
        }));
        return list;
    }

    readonly property bool nothingFound: query.trim().length > 0 && rows.length === 0

    // What a result stands for, as media to play or to add.
    function mediaOf(row) {
        if (row.media)
            return [row.media];
        if (row.tracks)
            return row.tracks;
        if (row.kind === "playlist")
            return store.playlistItems(row.id);
        return [];
    }

    function _play(list, index) {
        if (list.length === 0)
            return;
        var videosOnly = list.every(function(media) { return media.hasPicture; });
        playRequested(list, index, videosOnly ? {} : { asAudio: true, background: true });
    }

    // A tap on a result.
    function activate(index) {
        var row = rows[index];
        if (!row || row.section || row.note)
            return;
        field.dismiss();
        if (row.kind === "video") {
            playRequested([row.media], 0, {});
        } else if (row.kind === "track") {
            // The tracks found, from this one on, as a filtered list plays.
            var found = rows.filter(function(r) { return r.kind === "track"; });
            var list = found.map(function(r) { return r.media; });
            for (var i = 0; i < found.length; i++)
                if (found[i].media.url === row.media.url)
                    _play(list, i);
        } else if (row.kind === "playlist") {
            playlistOpenRequested(row.id);
        } else {
            groupRequested(row.tab, row.key);
        }
    }

    // One choice from a result's menu.
    function itemAction(index, key) {
        var row = rows[index];
        if (!row || row.section || row.note)
            return;
        var list = mediaOf(row);
        if (key === "open")
            activate(index);
        else if (key === "play")
            _play(list, 0);
        else if (key === "insertNext" || key === "append")
            queueRequested(list, key === "insertNext");
        else if (key === "addToPlaylist")
            playlistRequested(list);
    }

    function openMenu(index) {
        var row = rows[index];
        if (!row || row.section || row.note)
            return;
        field.dismiss();
        menuRow = { index: index, row: row };
        itemMenu.show();
    }

    function closeSheets() {
        itemMenu.close();
    }

    function setQuery(text) {
        field.text = text;
    }

    function shownTitles() {
        return rows.map(function(row) {
            return row.section ? "# " + row.section : row.note ? "(" + row.note + ")" : row.kind + ": " + row.title;
        });
    }

    onVisibleChanged: if (!visible) field.dismiss()

    Connections {
        target: page.library
        ignoreUnknownSignals: true
        onChanged: if (page.visible) page.reload()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    // Nothing behind the page takes a touch.
    MouseArea {
        anchors.fill: parent
        onClicked: field.dismiss()
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "Search"
        onBack: page.closeRequested()
    }

    Item {
        id: fieldBar
        anchors { left: parent.left; right: parent.right; top: header.bottom }
        height: Theme.u(7)

        SearchField {
            id: field
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                      leftMargin: Theme.u(2); rightMargin: Theme.u(2) }
            placeholder: "Search the library"
            onTextChanged: page.query = text
        }
    }

    Text {
        visible: page.query.trim().length === 0 || page.nothingFound
        anchors { left: parent.left; right: parent.right; top: fieldBar.bottom
                  leftMargin: Theme.u(2); rightMargin: Theme.u(2); topMargin: Theme.u(2) }
        wrapMode: Text.WordWrap
        text: page.nothingFound ? "Nothing in the library matches “" + page.query.trim() + "”."
                                : "Looks through videos, artists, albums, tracks, genres and playlists."
        color: Theme.textDim
        font.pixelSize: Theme.fontS
        lineHeight: 1.3
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: fieldBar.bottom; bottom: parent.bottom }
        clip: true
        model: page.rows
        onMovementStarted: field.dismiss()

        delegate: Item {
            id: row
            width: list.width
            height: isSection ? Theme.u(5.5) : isNote ? Theme.u(4.5) : Theme.u(8.25)

            readonly property bool isSection: !!modelData.section
            readonly property bool isNote: !!modelData.note
            readonly property bool isResult: !isSection && !isNote
            readonly property bool playing: isResult && !!modelData.media && modelData.media.url === page.playingUrl

            SectionLabel {
                visible: row.isSection
                text: row.isSection ? modelData.section : ""
            }

            Text {
                visible: row.isNote
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                          leftMargin: Theme.u(2); rightMargin: Theme.u(2) }
                text: row.isNote ? modelData.note : ""
                color: Theme.textFaint
                font.pixelSize: Theme.fontXS
                elide: Text.ElideRight
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.text
                opacity: row.isResult && rowMouse.pressed ? 0.06 : 0
            }

            Rectangle {
                id: rowThumb
                visible: row.isResult
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(6.25)
                height: width
                // Round for an artist, as in the Audio tab.
                radius: row.isResult && modelData.kind === "artist" ? width / 2 : Theme.u(0.5)
                color: Theme.surfaceAlt
                clip: true

                Glyph {
                    anchors.centerIn: parent
                    width: Theme.u(2.8)
                    name: !row.isResult ? "audio" : modelData.kind === "video" ? "video"
                          : modelData.kind === "playlist" ? "playlist" : "audio"
                    color: row.playing ? Theme.accent : Theme.textDim
                    visible: rowArt.status !== Image.Ready
                }
                Image {
                    id: rowArt
                    anchors.fill: parent
                    source: row.isResult ? (modelData.art || "") : ""
                    sourceSize: Qt.size(256, 256)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Column {
                visible: row.isResult
                anchors { left: rowThumb.right; leftMargin: Theme.u(1.5); right: rowMore.left
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.5)

                Text {
                    width: parent.width
                    text: row.isResult ? modelData.title : ""
                    color: row.playing ? Theme.accent : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: row.isResult ? (modelData.detail || "") : ""
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                enabled: row.isResult
                onClicked: page.activate(index)
            }

            IconButton {
                id: rowMore
                visible: row.isResult
                anchors { right: parent.right; rightMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
                glyph: "more"
                onClicked: page.openMenu(index)
            }
        }
    }

    // A result's menu. What can be opened has "Open" first.
    OptionSheet {
        id: itemMenu
        parent: page.overlay
        anchors.fill: parent
        title: page.menuRow ? page.menuRow.row.title : ""
        options: {
            var row = page.menuRow ? page.menuRow.row : null;
            if (!row)
                return [];
            var list = [];
            if (row.kind !== "video" && row.kind !== "track")
                list.push({ key: "open", label: "Open", glyph: "forward" });
            list.push({ key: "play", label: row.media ? "Play" : "Play all", glyph: "play" });
            list.push({ key: "insertNext", label: "Insert next", glyph: "next" });
            list.push({ key: "append", label: "Add to play queue", glyph: "add" });
            if (row.kind !== "playlist")
                list.push({ key: "addToPlaylist", label: "Add to playlist", glyph: "playlist" });
            return list;
        }
        onChosen: page.itemAction(page.menuRow.index, key)
    }
}
