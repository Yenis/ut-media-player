import QtQuick 2.12
import Gem 1.0

/*
 * The bar along the bottom that switches between the app's main pages, as
 * VLC's bottom navigation does. Controlled: it reports taps, the owner sets
 * `current`.
 */
Rectangle {
    id: bar

    property var tabs: []               // [{ name, title, glyph }]
    property string current: ""
    signal chosen(string name)

    implicitHeight: Theme.u(7)
    color: Theme.surface

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: Theme.line
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: bar.tabs

            delegate: Item {
                readonly property bool selected: modelData.name === bar.current
                width: bar.width / Math.max(1, bar.tabs.length)
                height: bar.height
                opacity: tabMouse.pressed ? 0.5 : 1.0

                Glyph {
                    id: icon
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.u(1.1) }
                    width: Theme.u(2.6)
                    name: modelData.glyph
                    color: parent.selected ? Theme.accent : Theme.textDim
                }
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: icon.bottom; topMargin: Theme.u(0.5) }
                    text: modelData.title
                    color: parent.selected ? Theme.accent : Theme.textDim
                    font.pixelSize: Theme.fontXS
                    font.bold: parent.selected
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    onClicked: bar.chosen(modelData.name)
                }
            }
        }
    }
}
