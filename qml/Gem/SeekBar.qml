import QtQuick 2.12
import Gem 1.0

/*
 * The timeline. Dragging previews a time and seeks once, on release: the
 * backend takes up to a second and a half per seek, so seeking while dragging
 * would only queue them up.
 */
Item {
    id: bar

    property int position: 0        // ms
    property int duration: 0        // ms
    property bool enabled: true

    // Marks on the timeline: [{ position (ms), color }], for bookmarks and the
    // two ends of an A-B repeat.
    property var markers: []

    readonly property bool dragging: area.pressed
    readonly property int shownPosition: dragging ? dragPosition : position
    property int dragPosition: 0

    signal seekRequested(int position)

    implicitHeight: Theme.u(4)

    function positionAt(x) {
        var share = Math.max(0, Math.min(1, (x - track.x) / track.width));
        return Math.round(share * bar.duration);
    }

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                  leftMargin: knob.width / 2; rightMargin: knob.width / 2 }
        height: Math.max(2, Theme.u(0.35))
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.28)

        Rectangle {
            width: bar.duration > 0 ? parent.width * Math.min(1, bar.shownPosition / bar.duration) : 0
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }

    Repeater {
        model: bar.duration > 0 ? bar.markers : []
        delegate: Rectangle {
            width: Math.max(2, Theme.u(0.3))
            height: Theme.u(1.4)
            radius: width / 2
            color: modelData.color
            anchors.verticalCenter: track.verticalCenter
            x: track.x + track.width * Math.min(1, modelData.position / bar.duration) - width / 2
        }
    }

    Rectangle {
        id: knob
        width: bar.dragging ? Theme.u(2.2) : Theme.u(1.5)
        height: width
        radius: width / 2
        color: Theme.accent
        visible: bar.enabled && bar.duration > 0
        anchors.verticalCenter: parent.verticalCenter
        x: track.x - width / 2 + (bar.duration > 0 ? track.width * Math.min(1, bar.shownPosition / bar.duration) : 0)
        Behavior on width { NumberAnimation { duration: 80 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.topMargin: -Theme.u(1.5)
        anchors.bottomMargin: -Theme.u(1.5)
        enabled: bar.enabled && bar.duration > 0
        preventStealing: true
        onPressed: bar.dragPosition = bar.positionAt(mouse.x)
        onPositionChanged: bar.dragPosition = bar.positionAt(mouse.x)
        onReleased: bar.seekRequested(bar.dragPosition)
    }
}
