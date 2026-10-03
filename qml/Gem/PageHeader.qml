import QtQuick 2.12
import Gem 1.0

Item {
    id: header

    property string title: ""
    // Off for the pages behind the tabs, which have nowhere to go back to.
    property bool canGoBack: true
    property alias trailing: trailingSlot.data
    signal back()

    implicitHeight: Theme.u(8)

    IconButton {
        id: backButton
        anchors { left: parent.left; leftMargin: Theme.u(0.5); verticalCenter: parent.verticalCenter }
        visible: header.canGoBack
        glyph: "back"
        color: Theme.text
        onClicked: header.back()
    }

    Text {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter
                  leftMargin: header.canGoBack ? backButton.width + Theme.u(1) : Theme.u(2) }
        text: header.title
        color: Theme.text
        font.pixelSize: Theme.fontL
        font.bold: true
    }

    Item {
        id: trailingSlot
        anchors { right: parent.right; rightMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.line
    }
}
