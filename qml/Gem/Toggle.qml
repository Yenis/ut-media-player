import QtQuick 2.12
import Gem 1.0

/* On/off switch. Controlled: it reports taps, the owner sets `checked`. */
Item {
    id: toggle

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: Theme.u(6.2)
    implicitHeight: Theme.u(3.4)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: toggle.checked ? Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.30) : Theme.surfaceAlt
        border.width: 1
        border.color: toggle.checked ? Theme.topaz : Theme.line
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            width: parent.height - Theme.u(0.8)
            height: width
            radius: width / 2
            y: Theme.u(0.4)
            x: toggle.checked ? parent.width - width - Theme.u(0.4) : Theme.u(0.4)
            color: toggle.checked ? Theme.topaz : Theme.textDim
            Behavior on x { NumberAnimation { duration: 120 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Theme.u(1)
        onClicked: toggle.toggled(!toggle.checked)
    }
}
