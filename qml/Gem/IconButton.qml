import QtQuick 2.12
import Gem 1.0

/* Glyphs are drawn, not typed: no dependency on any font shipping a symbol. */
Item {
    id: button

    property string glyph: "refresh"      // refresh | clear | settings | back
    property color color: Theme.textDim
    property bool spinning: false
    property bool enabled: true
    property real progress: 0             // 0..1 - ring showing a remaining fraction

    signal clicked()

    implicitWidth: Theme.u(5)
    implicitHeight: Theme.u(5)

    onColorChanged: canvas.requestPaint()
    onGlyphChanged: canvas.requestPaint()
    onProgressChanged: ring.requestPaint()

    Canvas {
        id: ring
        anchors.centerIn: parent
        width: Theme.u(4.2)
        height: width
        visible: button.progress > 0
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width, lw = Math.max(1.5, w * 0.06), r = w / 2 - lw;
            ctx.lineWidth = lw;
            ctx.lineCap = "round";
            ctx.strokeStyle = Theme.line;
            ctx.beginPath();
            ctx.arc(w / 2, w / 2, r, 0, Math.PI * 2);
            ctx.stroke();
            ctx.strokeStyle = Theme.topaz;
            ctx.beginPath();
            ctx.arc(w / 2, w / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, button.progress));
            ctx.stroke();
        }
        onWidthChanged: requestPaint()
    }

    Canvas {
        id: canvas
        anchors.centerIn: parent
        width: Theme.u(2.6)
        height: width
        opacity: !button.enabled ? 0.4 : (mouse.pressed ? 0.5 : 1.0)

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width, c = w / 2, lw = Math.max(1.4, w * 0.12);
            ctx.strokeStyle = button.color;
            ctx.fillStyle = button.color;
            ctx.lineWidth = lw;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            if (button.glyph === "refresh") {
                var r = c - lw;
                ctx.beginPath();
                ctx.arc(c, c, r, Math.PI * 0.45, Math.PI * 1.95);
                ctx.stroke();
                var ax = c + r * Math.cos(Math.PI * 0.45);
                var ay = c + r * Math.sin(Math.PI * 0.45);
                var h = w * 0.24;
                ctx.beginPath();
                ctx.moveTo(ax - h, ay - h * 0.35);
                ctx.lineTo(ax + h * 0.5, ay - h * 0.5);
                ctx.lineTo(ax - h * 0.15, ay + h * 0.75);
                ctx.closePath();
                ctx.fill();
            } else if (button.glyph === "clear") {
                var m = w * 0.27;
                ctx.beginPath();
                ctx.moveTo(m, m); ctx.lineTo(w - m, w - m);
                ctx.moveTo(w - m, m); ctx.lineTo(m, w - m);
                ctx.stroke();
            } else if (button.glyph === "settings") {
                // Three sliders.
                var knobs = [0.30, 0.68, 0.45];
                for (var i = 0; i < 3; i++) {
                    var y = w * (0.2 + 0.3 * i);
                    ctx.beginPath();
                    ctx.moveTo(w * 0.08, y); ctx.lineTo(w * 0.92, y);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.fillStyle = Theme.bg;
                    ctx.arc(w * knobs[i], y, w * 0.11, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.stroke();
                }
            } else if (button.glyph === "back") {
                ctx.beginPath();
                ctx.moveTo(w * 0.64, w * 0.16);
                ctx.lineTo(w * 0.30, w * 0.5);
                ctx.lineTo(w * 0.64, w * 0.84);
                ctx.stroke();
            }
        }
        onWidthChanged: requestPaint()
    }

    RotationAnimator {
        target: canvas
        from: 0; to: 360
        duration: 900
        loops: Animation.Infinite
        running: button.spinning
        onRunningChanged: if (!running) canvas.rotation = 0
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: button.enabled
        onClicked: button.clicked()
    }
}
