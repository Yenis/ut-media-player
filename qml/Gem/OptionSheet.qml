import QtQuick 2.12
import Gem 1.0

/*
 * A list of choices that slides up from the bottom, over a dimmed page: the
 * player menu and the list of aspect modes. Tapping outside closes it.
 *
 * options: [{ key, label, glyph, selected, value, stay }]
 *   key       what `chosen` reports; a row without one cannot be tapped
 *   value     shown on the right, dimmed
 *   stay      the sheet stays open when this row is chosen
 * Everything but `label` is optional.
 */
Item {
    id: sheet

    property var options: []
    property bool open: false
    property string title: ""

    signal chosen(string key)
    signal held(string key)

    visible: open || slide.running

    function show() { open = true; }
    function close() { open = false; }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: sheet.open ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: sheet.close()
    }

    Rectangle {
        id: panel
        width: Math.min(parent.width, Theme.u(48))
        height: Math.min(parent.height * 0.9, column.height + Theme.u(2))
        anchors.horizontalCenter: parent.horizontalCenter
        y: sheet.open ? parent.height - height : parent.height
        radius: Theme.u(1.6)
        color: Theme.surface
        border.width: 1
        border.color: Theme.line
        Behavior on y { NumberAnimation { id: slide; duration: 180; easing.type: Easing.OutCubic } }

        // Swallows taps on the panel itself.
        MouseArea { anchors.fill: parent }

        Flickable {
            anchors.fill: parent
            anchors.topMargin: Theme.u(1)
            anchors.bottomMargin: Theme.u(1)
            contentHeight: column.height
            clip: true

            Column {
                id: column
                width: parent.width

                Text {
                    visible: sheet.title.length > 0
                    width: parent.width
                    height: Theme.u(5)
                    leftPadding: Theme.u(2.5)
                    verticalAlignment: Text.AlignVCenter
                    text: sheet.title
                    color: Theme.textDim
                    font.pixelSize: Theme.fontS
                }

                Repeater {
                    model: sheet.options

                    delegate: Item {
                        width: column.width
                        height: Theme.u(6.5)

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.text
                            opacity: rowMouse.pressed ? 0.08 : 0
                        }

                        Glyph {
                            id: icon
                            visible: !!modelData.glyph
                            anchors { left: parent.left; leftMargin: Theme.u(2.5); verticalCenter: parent.verticalCenter }
                            width: Theme.u(2.6)
                            name: modelData.glyph || "play"
                            color: modelData.selected ? Theme.accent : Theme.text
                        }

                        Text {
                            anchors { left: icon.visible ? icon.right : parent.left; leftMargin: Theme.u(2.5)
                                      right: valueLabel.left; rightMargin: Theme.u(1.5); verticalCenter: parent.verticalCenter }
                            text: modelData.label
                            color: modelData.selected ? Theme.accent : Theme.text
                            font.pixelSize: Theme.fontM
                            elide: Text.ElideRight
                        }

                        Text {
                            id: valueLabel
                            anchors { right: parent.right; rightMargin: Theme.u(2.5); verticalCenter: parent.verticalCenter }
                            width: Math.min(implicitWidth, parent.width * 0.6)
                            text: modelData.value || ""
                            color: Theme.textDim
                            font.pixelSize: Theme.fontS
                            elide: Text.ElideLeft
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            enabled: !!modelData.key
                            onClicked: {
                                if (!modelData.stay)
                                    sheet.close();
                                sheet.chosen(modelData.key);
                            }
                            onPressAndHold: sheet.held(modelData.key)
                        }
                    }
                }
            }
        }
    }
}
