import QtQuick 2.12
import Gem 1.0

/*
 * Asked when a stream is wanted while streams are off (docs/PLAN.md, D14):
 * what allowing means, "Cancel" and "Allow streams". The system has no
 * network permission to grant at run time, so this is the app's own
 * question, and the switch behind it the app's own.
 *
 * One of these serves the whole app; the shell owns it.
 */
Item {
    id: gate

    property bool open: false
    property string address: ""         // what was asked for, to show it
    property var _then: null            // what to do once streams are allowed

    // The user allowed streams. The owner switches them on; `proceed` then
    // does what was asked for.
    signal allowed()

    visible: open

    function ask(forAddress, then) {
        address = forAddress || "";
        _then = then || null;
        open = true;
    }

    function close() {
        open = false;
        _then = null;
    }

    function allow() {
        var then = _then;
        close();
        allowed();
        if (then)
            then();
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    MouseArea {
        anchors.fill: parent
        onClicked: gate.close()
    }

    Rectangle {
        width: Math.min(parent.width - Theme.u(4), Theme.u(44))
        height: column.height + Theme.u(4)
        anchors.centerIn: parent
        radius: Theme.u(1.6)
        color: Theme.surface
        border.width: 1
        border.color: Theme.line

        // Swallows taps on the panel itself.
        MouseArea { anchors.fill: parent }

        Column {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.u(2) }
            spacing: Theme.u(1.6)

            Text {
                width: parent.width
                text: "GemPlayer is offline"
                color: Theme.text
                font.pixelSize: Theme.fontL
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: "Streams are switched off, and nothing in the app reaches the network."
                color: Theme.text
                font.pixelSize: Theme.fontM
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }
            Text {
                width: parent.width
                text: "If you allow streams, an address you open is handed to the system's player, "
                      + "which connects to it. GemPlayer itself connects to nothing, and sends nothing else anywhere."
                color: Theme.textDim
                font.pixelSize: Theme.fontS
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }
            Text {
                width: parent.width
                visible: gate.address.length > 0
                text: gate.address
                color: Theme.accent
                font.pixelSize: Theme.fontS
                elide: Text.ElideMiddle
            }
            Text {
                width: parent.width
                text: "It can be switched off again under More, Streams."
                color: Theme.textFaint
                font.pixelSize: Theme.fontXS
                wrapMode: Text.WordWrap
            }

            Row {
                anchors.right: parent.right
                spacing: Theme.u(1.5)

                TextButton {
                    text: "Cancel"
                    tone: Theme.textDim
                    onClicked: gate.close()
                }
                TextButton {
                    text: "Allow streams"
                    onClicked: gate.allow()
                }
            }
        }
    }
}
