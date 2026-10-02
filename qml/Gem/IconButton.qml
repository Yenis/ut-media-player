import QtQuick 2.12
import Gem 1.0

/* A tappable icon. The icons themselves are in Glyph.qml. */
Item {
    id: button

    property string glyph: "play"
    property color color: Theme.textDim
    property bool enabled: true
    property real glyphSize: Theme.u(2.6)

    signal clicked()
    signal pressAndHold()

    implicitWidth: Theme.u(5)
    implicitHeight: Theme.u(5)

    Glyph {
        anchors.centerIn: parent
        width: button.glyphSize
        name: button.glyph
        color: button.color
        opacity: !button.enabled ? 0.4 : (mouse.pressed ? 0.5 : 1.0)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: button.enabled
        onClicked: button.clicked()
        onPressAndHold: button.pressAndHold()
    }
}
