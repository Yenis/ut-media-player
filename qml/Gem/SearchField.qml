import QtQuick 2.12
import Gem 1.0

/* Plain TextInput in a rounded surface - no QtQuick.Controls dependency. */
FocusScope {
    id: field

    property alias text: input.text
    property string placeholder: "Filter"

    function open() { input.forceActiveFocus(); }

    implicitHeight: Theme.u(5)

    /* Empty the field and put the on-screen keyboard away. */
    function reset() {
        input.text = "";
        dismiss();
    }

    /* Put the keyboard away and keep what was typed. Nothing else in the app
       takes focus, so the field has to give it up itself. */
    function dismiss() {
        Qt.inputMethod.commit();
        input.focus = false;
        Qt.inputMethod.hide();
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.u(0.9)
        color: Theme.surfaceAlt
        border.width: 1
        border.color: input.activeFocus ? Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.7)
                                        : Theme.line

        Glyph {
            id: lens
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.u(1.4)
            width: Theme.u(1.9)
            name: "search"
            color: Theme.textFaint
        }

        TextInput {
            id: input
            anchors {
                left: lens.right; leftMargin: Theme.u(1.1)
                right: clearButton.left; rightMargin: Theme.u(0.5)
                verticalCenter: parent.verticalCenter
            }
            // No focus: true - on a phone that would open the keyboard at launch.
            color: Theme.text
            font.pixelSize: Theme.fontM
            selectByMouse: true
            selectionColor: Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.35)
            clip: true
            inputMethodHints: Qt.ImhNoPredictiveText
            // The keyboard's enter key.
            onAccepted: field.dismiss()

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: field.placeholder
                color: Theme.textFaint
                font.pixelSize: Theme.fontM
                visible: input.text.length === 0 && !input.activeFocus
            }
        }

        IconButton {
            id: clearButton
            anchors {
                right: parent.right; rightMargin: Theme.u(0.4)
                verticalCenter: parent.verticalCenter
            }
            width: Theme.u(4); height: Theme.u(4)
            glyph: "clear"
            visible: input.text.length > 0
            onClicked: { input.text = ""; input.forceActiveFocus(); }
        }
    }
}
