import QtQuick 2.12
import Gem 1.0

Rectangle {
    id: button

    property string text: ""
    property color tone: Theme.topaz
    property bool enabled: true
    signal clicked()

    implicitWidth: label.implicitWidth + Theme.u(4)
    implicitHeight: Theme.u(4.5)
    radius: Theme.u(0.8)
    opacity: enabled ? 1 : 0.5
    color: mouse.pressed ? Qt.rgba(tone.r, tone.g, tone.b, 0.25)
                         : Qt.rgba(tone.r, tone.g, tone.b, 0.12)
    border.width: 1
    border.color: Qt.rgba(tone.r, tone.g, tone.b, 0.6)

    Text {
        id: label
        anchors.centerIn: parent
        text: button.text
        color: button.tone
        font.pixelSize: Theme.fontS
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: button.enabled
        onClicked: button.clicked()
    }
}
