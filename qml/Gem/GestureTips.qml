import QtQuick 2.12
import Gem 1.0

/*
 * The gesture tips, a step at a time, after VLC's VideoTipsDelegate: the
 * part of the screen a gesture is made on is lit, with what it does below,
 * and "Next" leads on. A tap anywhere also leads on; "Close" ends them.
 *
 * The page gives the steps, leaving out what the settings switched off,
 * and `area`, the item the gestures are made on: the zones are drawn over
 * it, the card below it.
 *
 * steps: [{ title, text, zone, mark }]
 *   zone   "all", "left", "right", "middle", "sides" or "none"
 *   mark   a sign drawn in the zone: "tap", "doubleTap", "vertical",
 *          "horizontal", "pinch", or "" for none
 */
Item {
    id: tips

    property var steps: []
    property Item area: tips
    property int index: 0
    property bool open: false

    signal finished()

    readonly property var step: open && index < steps.length ? steps[index] : null

    visible: open

    function start(list) {
        if (!list || list.length === 0)
            return;
        steps = list;
        index = 0;
        open = true;
    }

    function next() {
        if (index < steps.length - 1)
            index++;
        else
            close();
    }

    function close() {
        if (!open)
            return;
        open = false;
        finished();
    }

    // The gesture area's place on this item; read when a step is drawn.
    function _areaRect() {
        var at = area.mapToItem(tips, 0, 0);
        return { x: at.x, y: at.y, w: area.width, h: area.height };
    }
    readonly property var areaRect: open && step ? _areaRect() : ({ x: 0, y: 0, w: width, h: height })

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.6
    }

    // A tap anywhere leads on.
    MouseArea {
        anchors.fill: parent
        onClicked: tips.next()
    }

    // The zones of the step, lit.
    Repeater {
        model: {
            var s = tips.step;
            var r = tips.areaRect;
            if (!s)
                return [];
            var third = r.w / 3;
            if (s.zone === "left")
                return [{ x: r.x, y: r.y, w: r.w / 2, h: r.h }];
            if (s.zone === "right")
                return [{ x: r.x + r.w / 2, y: r.y, w: r.w / 2, h: r.h }];
            if (s.zone === "middle")
                return [{ x: r.x + third, y: r.y, w: third, h: r.h }];
            if (s.zone === "sides")
                return [{ x: r.x, y: r.y, w: r.w / 4, h: r.h }, { x: r.x + r.w * 0.75, y: r.y, w: r.w / 4, h: r.h }];
            if (s.zone === "none")
                return [];
            return [{ x: r.x, y: r.y, w: r.w, h: r.h }];
        }

        delegate: Rectangle {
            x: modelData.x + Theme.u(0.5)
            y: modelData.y + Theme.u(0.5)
            width: Math.max(0, modelData.w - Theme.u(1))
            height: Math.max(0, modelData.h - Theme.u(1))
            radius: Theme.u(1.2)
            color: Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.16)
            border.width: 2
            border.color: Qt.rgba(Theme.topaz.r, Theme.topaz.g, Theme.topaz.b, 0.8)

            // The sign of the gesture, from the app's own icons: a text
            // arrow would come out as a coloured emoji [device].
            Item {
                id: sign
                anchors.centerIn: parent
                width: Theme.u(8)
                height: Theme.u(8)
                readonly property string mark: tips.step ? tips.step.mark : ""

                Column {
                    visible: sign.mark === "vertical"
                    anchors.centerIn: parent
                    spacing: Theme.u(1)
                    Glyph { width: Theme.u(4); name: "up"; color: Theme.topaz }
                    Glyph { width: Theme.u(4); name: "down"; color: Theme.topaz }
                }
                Row {
                    visible: sign.mark === "horizontal" || sign.mark === "pinch"
                    anchors.centerIn: parent
                    spacing: Theme.u(1.5)
                    rotation: sign.mark === "pinch" ? -45 : 0
                    Glyph { width: Theme.u(4); name: "back"; color: Theme.topaz }
                    Glyph { width: Theme.u(4); name: "forward"; color: Theme.topaz }
                }
                Row {
                    visible: sign.mark === "tap" || sign.mark === "doubleTap"
                    anchors.centerIn: parent
                    spacing: Theme.u(1)
                    Repeater {
                        model: sign.mark === "doubleTap" ? 2 : 1
                        Rectangle {
                            width: Theme.u(2.6)
                            height: width
                            radius: width / 2
                            color: Theme.topaz
                        }
                    }
                }
            }
        }
    }

    // What the step is, and the way on.
    Rectangle {
        id: card
        width: Math.min(parent.width - Theme.u(4), Theme.u(44))
        height: cardColumn.height + Theme.u(4)
        anchors.horizontalCenter: parent.horizontalCenter
        // Below the gesture area where there is room, else over its foot.
        y: Math.min(parent.height - height - Theme.u(2), tips.areaRect.y + tips.areaRect.h + Theme.u(2))
        radius: Theme.u(1.6)
        color: Theme.surface
        border.width: 1
        border.color: Theme.line

        // Taps on the card do not lead on; its buttons do.
        MouseArea { anchors.fill: parent }

        Column {
            id: cardColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.u(2) }
            spacing: Theme.u(1.2)

            Text {
                width: parent.width
                text: tips.step ? tips.step.title : ""
                color: Theme.text
                font.pixelSize: Theme.fontL
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: tips.step ? tips.step.text : ""
                color: Theme.textDim
                font.pixelSize: Theme.fontM
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }

            Item {
                width: parent.width
                height: Theme.u(4.5)

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: (tips.index + 1) + " of " + tips.steps.length
                    color: Theme.textFaint
                    font.pixelSize: Theme.fontS
                }
                Row {
                    anchors.right: parent.right
                    spacing: Theme.u(1.5)

                    TextButton {
                        visible: tips.index < tips.steps.length - 1
                        text: "Close"
                        tone: Theme.textDim
                        onClicked: tips.close()
                    }
                    TextButton {
                        text: tips.index < tips.steps.length - 1 ? "Next" : "Done"
                        onClicked: tips.next()
                    }
                }
            }
        }
    }
}
