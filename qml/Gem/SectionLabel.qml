import QtQuick 2.12
import Gem 1.0

/* Small uppercase heading between groups of settings. */
Item {
    property alias text: label.text

    width: parent ? parent.width : 0
    height: Theme.u(5.5)

    Text {
        id: label
        anchors { left: parent.left; leftMargin: Theme.u(2); bottom: parent.bottom; bottomMargin: Theme.u(1) }
        color: Theme.topaz
        font.pixelSize: Theme.fontXS
        font.bold: true
        font.letterSpacing: 1.2
        font.capitalization: Font.AllUppercase
    }
}
