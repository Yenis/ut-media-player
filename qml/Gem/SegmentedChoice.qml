import QtQuick 2.12
import Gem 1.0

/* One-of-several picker. Controlled: it reports taps, the owner sets `currentIndex`. */
Item {
    id: choice

    property var options: []
    property int currentIndex: 0
    signal chosen(int index)

    implicitHeight: Theme.u(4.6)

    Rectangle {
        anchors.fill: parent
        radius: Theme.u(0.9)
        color: Theme.surfaceAlt
        border.width: 1
        border.color: Theme.line

        Row {
            id: segments
            anchors.fill: parent
            anchors.margins: Theme.u(0.35)

            Repeater {
                model: choice.options

                delegate: Rectangle {
                    readonly property bool selected: index === choice.currentIndex
                    width: segments.width / Math.max(1, choice.options.length)
                    height: segments.height
                    radius: Theme.u(0.7)
                    color: selected ? Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.20) : "transparent"
                    border.width: selected ? 1 : 0
                    border.color: Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.7)

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: parent.selected ? Theme.topaz : Theme.textDim
                        font.pixelSize: Theme.fontS
                        font.bold: parent.selected
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: choice.chosen(index)
                    }
                }
            }
        }
    }
}
