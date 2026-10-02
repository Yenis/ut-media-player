import QtQuick 2.12
import Gem 1.0

/*
 * A time typed on a keypad, for "Jump to time" and the sleep timer. It works
 * like VLC's PickTimeFragment: digits fill in from the right, two each for
 * seconds, minutes and hours; ":00" and ":30" type two digits at once.
 *
 * Its own keypad, not the system keyboard: the player turns its own content,
 * and the system keyboard would appear on the wrong edge.
 */
Item {
    id: picker

    property bool open: false
    property string title: ""
    property bool withSeconds: true         // false: hours and minutes only
    property bool sleepOptions: false       // the two sleep-timer switches and "Remove current"
    property bool canRemove: false

    property string digits: ""
    property bool waitForEnd: false
    property bool resetOnInteraction: false

    readonly property int maxDigits: withSeconds ? 6 : 4

    signal accepted(int ms)
    signal removed()

    visible: open

    function show() {
        digits = "";
        open = true;
    }
    function close() { open = false; }

    function type(text) {
        if (digits.length + text.length <= maxDigits)
            digits += text;
    }

    function parts() {
        var rest = digits;
        function take() {
            var two = rest.length <= 2 ? rest : rest.substring(rest.length - 2);
            rest = rest.length <= 2 ? "" : rest.substring(0, rest.length - 2);
            return two;
        }
        var s = withSeconds ? take() : "";
        var m = take();
        var h = take();
        return { h: h, m: m, s: s };
    }

    function milliseconds() {
        var p = parts();
        return ((parseInt(p.h || "0", 10) * 60 + parseInt(p.m || "0", 10)) * 60 + parseInt(p.s || "0", 10)) * 1000;
    }

    function shown() {
        var p = parts();
        var text = (p.h ? p.h + "h " : "") + (p.m ? p.m + "m " : "") + (p.s ? p.s + "s" : "");
        return text.trim();
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }
    MouseArea {
        anchors.fill: parent
        onClicked: picker.close()
    }

    // Upright: title, keypad, options, one under the other. On its side, where
    // height is short: keypad on the left, options beside it.
    readonly property bool wide: sleepOptions && width > height * 1.2

    Rectangle {
        id: panel
        readonly property real pad: Theme.u(2)
        readonly property real keyHeight: Math.min(Theme.u(6.5),
            (picker.height * 0.94 - fixed.height - (picker.wide ? 0 : extras.height) - Theme.u(6)) / 4)
        width: Math.min(parent.width, picker.wide ? Theme.u(84) : Theme.u(44))
        height: fixed.height + Theme.u(6)
                + (picker.wide ? Math.max(keys.height, extras.height) : keys.height + extras.height)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        radius: Theme.u(1.6)
        color: Theme.surface
        border.width: 1
        border.color: Theme.line

        MouseArea { anchors.fill: parent }

        Item {
            id: fixed
            x: panel.pad
            y: panel.pad
            width: (picker.wide ? panel.width / 2 : panel.width) - 2 * panel.pad
            height: Theme.u(5)

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: picker.title
                color: Theme.textDim
                font.pixelSize: Theme.fontS
            }
            Text {
                anchors { right: erase.left; rightMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
                text: picker.shown() || (picker.withSeconds ? "0s" : "0m")
                color: picker.digits.length > 0 ? Theme.text : Theme.textFaint
                font.pixelSize: Theme.fontXL
            }
            IconButton {
                id: erase
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                glyph: "erase"
                color: Theme.text
                onClicked: picker.digits = picker.digits.substring(0, picker.digits.length - 1)
            }
        }

        Grid {
            id: keys
            x: panel.pad
            y: fixed.y + fixed.height + Theme.u(1)
            width: fixed.width
            columns: 3
            height: panel.keyHeight * 4

            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", ":00", "0", ":30"]
                delegate: Item {
                    width: keys.width / 3
                    height: panel.keyHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Theme.u(0.3)
                        radius: Theme.u(0.8)
                        color: keyMouse.pressed ? Theme.line : Theme.surfaceAlt
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.text
                        font.pixelSize: Theme.fontL
                    }
                    MouseArea {
                        id: keyMouse
                        anchors.fill: parent
                        onClicked: picker.type(modelData.replace(":", ""))
                    }
                }
            }
        }

        Column {
            id: extras
            x: picker.wide ? panel.width / 2 + panel.pad : panel.pad
            y: picker.wide ? fixed.y + Theme.u(1) : keys.y + keys.height + Theme.u(1)
            width: (picker.wide ? panel.width / 2 : panel.width) - 2 * panel.pad
            spacing: Theme.u(0.6)

            Repeater {
                model: picker.sleepOptions
                       ? [["Wait for current media item to finish first", "waitForEnd"],
                          ["Reset on any interaction", "resetOnInteraction"]]
                       : []
                delegate: Item {
                    width: extras.width
                    height: Math.max(Theme.u(4.4), optionLabel.implicitHeight + Theme.u(1))
                    Text {
                        id: optionLabel
                        anchors { left: parent.left; right: toggle.left; rightMargin: Theme.u(1); verticalCenter: parent.verticalCenter }
                        text: modelData[0]
                        color: Theme.text
                        font.pixelSize: Theme.fontS
                        wrapMode: Text.WordWrap
                    }
                    Toggle {
                        id: toggle
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        checked: picker[modelData[1]]
                        onToggled: picker[modelData[1]] = checked
                    }
                }
            }

            Row {
                anchors.right: parent.right
                spacing: Theme.u(1.5)
                height: Theme.u(5.5)

                TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: picker.canRemove
                    text: "Remove current"
                    tone: Theme.ruby
                    onClicked: {
                        picker.close();
                        picker.removed();
                    }
                }
                TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "OK"
                    onClicked: {
                        picker.close();
                        picker.accepted(picker.milliseconds());
                    }
                }
            }
        }
    }
}
