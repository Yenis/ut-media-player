import QtQuick 2.12
import Gem 1.0

/* A tab whose content is still to be built: its title, and what will be there. */
Item {
    id: page

    property string title: ""
    property string glyph: ""
    property string text: ""

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: page.title
        canGoBack: false
    }

    Column {
        anchors { left: parent.left; right: parent.right; leftMargin: Theme.u(4); rightMargin: Theme.u(4)
                  verticalCenter: parent.verticalCenter; verticalCenterOffset: header.height / 2 }
        spacing: Theme.u(2)

        Glyph {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.u(8)
            name: page.glyph
            color: Theme.textFaint
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: page.text
            color: Theme.textDim
            font.pixelSize: Theme.fontM
            lineHeight: 1.3
        }
    }
}
