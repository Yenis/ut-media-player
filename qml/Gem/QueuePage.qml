import QtQuick 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * The play queue as a page over the audio player: every item with its place,
 * the one that plays marked, and a filter for a long queue. A tap goes to an
 * item; holding one that plays or is still to come asks for its menu. After
 * VLC's queue inside its audio player (docs/VLC-FEATURES.md, "Audio player").
 */
Item {
    id: page

    property var playback: null
    property bool open: false
    property bool filtering: false
    property string filter: ""

    // The item's menu is wanted: its place in the queue.
    signal menuRequested(int index)

    visible: open

    function show() {
        open = true;
        // Start at the item that plays, not at the top of a long queue.
        list.positionViewAtIndex(Math.max(0, currentRow()), ListView.Center);
    }

    function close() {
        search.reset();
        filtering = false;
        open = false;
    }

    // Closes the filter first, then the page.
    function back() {
        if (filtering) {
            search.reset();
            filtering = false;
        } else {
            close();
        }
    }

    // For the development remote.
    function setFilter(text) {
        filtering = text.length > 0;
        search.text = text;
    }

    // The queue's items that pass the filter, each with its place in the queue.
    readonly property var rows: {
        var list = [];
        var queue = playback ? playback.queue : [];
        var needle = filter.trim().toLowerCase();
        for (var i = 0; i < queue.length; i++) {
            var item = queue[i];
            if (needle && (item.title || "").toLowerCase().indexOf(needle) < 0
                       && (item.artist || "").toLowerCase().indexOf(needle) < 0)
                continue;
            list.push({ index: i, item: item });
        }
        return list;
    }

    function currentRow() {
        for (var i = 0; i < rows.length; i++)
            if (rows[i].index === playback.queueIndex)
                return i;
        return -1;
    }

    function rowTitles() {
        return rows.map(function(row) { return (row.index + 1) + " " + row.item.title; });
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
        title: page.playback ? "Queue – " + (page.playback.queueIndex + 1) + " of " + page.playback.queue.length
                             : "Queue"
        onBack: page.close()
        trailing: Row {
            IconButton {
                glyph: "search"
                color: page.filtering ? Theme.accent : Theme.textDim
                onClicked: {
                    if (page.filtering) {
                        search.reset();
                        page.filtering = false;
                    } else {
                        page.filtering = true;
                        search.open();
                    }
                }
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
            placeholder: "Filter the queue"
            onTextChanged: page.filter = text
        }
    }

    Text {
        visible: page.rows.length === 0 && page.filter.trim().length > 0
        anchors.centerIn: parent
        width: parent.width - Theme.u(8)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "Nothing in the queue matches “" + page.filter.trim() + "”."
        color: Theme.textDim
        font.pixelSize: Theme.fontM
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: filterBar.bottom; bottom: parent.bottom }
        clip: true
        model: page.rows
        onMovementStarted: search.dismiss()

        delegate: Item {
            id: row
            width: list.width
            height: Theme.u(7)

            readonly property bool current: page.playback ? modelData.index === page.playback.queueIndex : false
            readonly property bool played: page.playback ? modelData.index < page.playback.queueIndex : false
            readonly property bool stopsHere: page.playback ? modelData.index === page.playback.stopAfter : false

            Rectangle {
                anchors.fill: parent
                color: row.current ? Theme.accent : Theme.text
                opacity: rowMouse.pressed ? 0.06 : (row.current ? 0.10 : 0)
            }

            Text {
                id: place
                anchors { left: parent.left; leftMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                width: Theme.u(4)
                text: modelData.index + 1
                color: row.current ? Theme.accent : Theme.textFaint
                font.pixelSize: Theme.fontS
            }

            Column {
                anchors { left: place.right; leftMargin: Theme.u(1); right: length.left; rightMargin: Theme.u(1.5)
                          verticalCenter: parent.verticalCenter }
                spacing: Theme.u(0.4)
                opacity: row.played ? 0.55 : 1

                Text {
                    width: parent.width
                    text: modelData.item.title
                    color: row.current ? Theme.accent : Theme.text
                    font.pixelSize: Theme.fontM
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: (row.stopsHere ? "Stops after this track" : "")
                          + (row.stopsHere && modelData.item.artist ? "  •  " : "")
                          + (modelData.item.artist || "")
                    color: row.stopsHere ? Theme.accent : Theme.textFaint
                    font.pixelSize: Theme.fontXS
                    elide: Text.ElideRight
                }
            }

            Text {
                id: length
                anchors { right: parent.right; rightMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
                text: Format.clock(modelData.item.duration)
                color: Theme.textFaint
                font.pixelSize: Theme.fontS
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                onClicked: {
                    search.dismiss();
                    page.playback.jumpTo(modelData.index);
                }
                onPressAndHold: {
                    if (modelData.index >= page.playback.queueIndex)
                        page.menuRequested(modelData.index);
                }
            }
        }
    }
}
