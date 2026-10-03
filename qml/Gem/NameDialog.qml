import QtQuick 2.12
import Gem 1.0

/*
 * Asks for a name: a title, one line of text, Cancel and a confirming button.
 * It sits in the upper part of what it covers, clear of the on-screen
 * keyboard, and takes focus only when shown.
 */
Item {
    id: dialog

    property string title: ""
    property string confirmLabel: "OK"
    property bool open: false

    signal accepted(string name)

    visible: open

    function show(initial) {
        input.text = initial || "";
        open = true;
        input.forceActiveFocus();
        input.selectAll();
    }

    function close() {
        Qt.inputMethod.commit();
        input.focus = false;
        Qt.inputMethod.hide();
        open = false;
    }

    function _accept() {
        Qt.inputMethod.commit();
        var name = input.text.trim();
        if (name.length === 0)
            return;
        close();
        accepted(name);
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    MouseArea {
        anchors.fill: parent
        onClicked: dialog.close()
    }

    Rectangle {
        width: Math.min(parent.width - Theme.u(4), Theme.u(44))
        height: column.height + Theme.u(4)
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top
                  topMargin: Math.max(Theme.u(2), Math.min(Theme.u(12), (parent.height - height) / 2)) }
        radius: Theme.u(1.6)
        color: Theme.surface
        border.width: 1
        border.color: Theme.line

        // Swallows taps on the panel itself.
        MouseArea { anchors.fill: parent }

        Column {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.u(2) }
            spacing: Theme.u(2)

            Text {
                width: parent.width
                text: dialog.title
                color: Theme.text
                font.pixelSize: Theme.fontL
                font.bold: true
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: Theme.u(5)
                radius: Theme.u(0.9)
                color: Theme.surfaceAlt
                border.width: 1
                border.color: Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.7)

                TextInput {
                    id: input
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                              leftMargin: Theme.u(1.4); rightMargin: Theme.u(1.4) }
                    color: Theme.text
                    font.pixelSize: Theme.fontM
                    selectByMouse: true
                    selectionColor: Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.35)
                    clip: true
                    maximumLength: 80
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onAccepted: dialog._accept()
                }
            }

            Row {
                anchors.right: parent.right
                spacing: Theme.u(1.5)

                TextButton {
                    text: "Cancel"
                    tone: Theme.textDim
                    onClicked: dialog.close()
                }
                TextButton {
                    text: dialog.confirmLabel
                    onClicked: dialog._accept()
                }
            }
        }
    }
}
