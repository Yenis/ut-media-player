import QtQuick 2.12
import Gem 1.0

/* A settings entry: title and explanation, a control on the right or below. */
Item {
    id: row

    property string title: ""
    property string detail: ""
    property alias trailing: trailingSlot.data
    property alias below: belowSlot.data

    width: parent ? parent.width : 0
    implicitHeight: column.height + Theme.u(3.2)

    Column {
        id: column
        anchors {
            left: parent.left; leftMargin: Theme.u(2)
            right: trailingSlot.left; rightMargin: trailingSlot.width > 0 ? Theme.u(1.5) : 0
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.u(0.7)

        Text {
            width: parent.width
            text: row.title
            color: Theme.text
            font.pixelSize: Theme.fontM
            wrapMode: Text.WordWrap
        }
        Text {
            width: parent.width
            text: row.detail
            visible: row.detail.length > 0
            color: Theme.textFaint
            font.pixelSize: Theme.fontXS
            wrapMode: Text.WordWrap
            lineHeight: 1.15
        }
        Item {
            id: belowSlot
            width: parent.width
            height: childrenRect.height + (children.length > 0 ? Theme.u(0.6) : 0)
            visible: children.length > 0
        }
    }

    Item {
        id: trailingSlot
        anchors { right: parent.right; rightMargin: Theme.u(2); verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: Theme.u(2) }
        height: 1
        color: Theme.line
    }
}
