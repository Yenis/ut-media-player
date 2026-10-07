import QtQuick 2.12
import Gem 1.0

/*
 * One icon, drawn on a canvas: no dependency on any font or icon theme
 * shipping a symbol. Square; set `width`.
 */
Canvas {
    id: glyph

    property string name: "play"
    property color color: Theme.text

    height: width

    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var w = width, c = w / 2, lw = Math.max(1.4, w * 0.1);
        ctx.strokeStyle = glyph.color;
        ctx.fillStyle = glyph.color;
        ctx.lineWidth = lw;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        function line(points) {
            ctx.beginPath();
            ctx.moveTo(points[0] * w, points[1] * w);
            for (var i = 2; i < points.length; i += 2)
                ctx.lineTo(points[i] * w, points[i + 1] * w);
        }
        function stroke(points) { line(points); ctx.stroke(); }
        function fill(points) { line(points); ctx.closePath(); ctx.fill(); }
        function arc(x, y, r, from, to) {
            ctx.beginPath();
            ctx.arc(x * w, y * w, r * w, from * Math.PI, to * Math.PI);
            ctx.stroke();
        }
        function dot(x, y, r) {
            ctx.beginPath();
            ctx.arc(x * w, y * w, r * w, 0, Math.PI * 2);
            ctx.fill();
        }

        switch (glyph.name) {
        case "play":
            fill([0.26, 0.14, 0.26, 0.86, 0.88, 0.5]);
            break;
        case "pause":
            ctx.fillRect(w * 0.22, w * 0.16, w * 0.2, w * 0.68);
            ctx.fillRect(w * 0.58, w * 0.16, w * 0.2, w * 0.68);
            break;
        case "back":
            stroke([0.64, 0.16, 0.30, 0.5, 0.64, 0.84]);
            break;
        case "clear":
            stroke([0.27, 0.27, 0.73, 0.73]);
            stroke([0.73, 0.27, 0.27, 0.73]);
            break;
        case "more":
            dot(0.5, 0.2, 0.085); dot(0.5, 0.5, 0.085); dot(0.5, 0.8, 0.085);
            break;
        case "lock":
            ctx.strokeRect(w * 0.2, w * 0.46, w * 0.6, w * 0.42);
            arc(0.5, 0.46, 0.19, 1, 2);
            break;
        case "unlock":
            ctx.strokeRect(w * 0.2, w * 0.46, w * 0.6, w * 0.42);
            arc(0.5, 0.42, 0.19, 1, 1.8);
            break;
        case "aspect":
            stroke([0.14, 0.38, 0.14, 0.2, 0.34, 0.2]);
            stroke([0.66, 0.2, 0.86, 0.2, 0.86, 0.38]);
            stroke([0.86, 0.62, 0.86, 0.8, 0.66, 0.8]);
            stroke([0.34, 0.8, 0.14, 0.8, 0.14, 0.62]);
            break;
        case "rotate":
            arc(0.5, 0.5, 0.38, 0.45, 1.95);
            fill([0.32, 0.84, 0.62, 0.78, 0.5, 1.0]);
            ctx.strokeRect(w * 0.4, w * 0.32, w * 0.2, w * 0.36);
            break;
        case "audio":
            arc(0.5, 0.56, 0.34, 1, 2);
            ctx.fillRect(w * 0.1, w * 0.54, w * 0.16, w * 0.32);
            ctx.fillRect(w * 0.74, w * 0.54, w * 0.16, w * 0.32);
            break;
        case "video":
            ctx.strokeRect(w * 0.1, w * 0.22, w * 0.8, w * 0.56);
            fill([0.42, 0.37, 0.42, 0.63, 0.64, 0.5]);
            break;
        case "clock":
            arc(0.5, 0.5, 0.38, 0, 2);
            stroke([0.5, 0.28, 0.5, 0.5, 0.66, 0.6]);
            break;
        case "jump":
            stroke([0.12, 0.5, 0.68, 0.5]);
            stroke([0.5, 0.32, 0.68, 0.5, 0.5, 0.68]);
            stroke([0.86, 0.2, 0.86, 0.8]);
            break;
        case "volume":
            fill([0.12, 0.4, 0.28, 0.4, 0.48, 0.22, 0.48, 0.78, 0.28, 0.6, 0.12, 0.6]);
            arc(0.5, 0.5, 0.2, -0.25, 0.25);
            arc(0.5, 0.5, 0.36, -0.25, 0.25);
            break;
        case "brightness":
            dot(0.5, 0.5, 0.17);
            for (var i = 0; i < 8; i++) {
                var a = i * Math.PI / 4;
                stroke([0.5 + 0.3 * Math.cos(a), 0.5 + 0.3 * Math.sin(a),
                        0.5 + 0.42 * Math.cos(a), 0.5 + 0.42 * Math.sin(a)]);
            }
            break;
        case "settings":
            // Three sliders.
            var knobs = [0.30, 0.68, 0.45];
            for (var k = 0; k < 3; k++) {
                var y = 0.2 + 0.3 * k;
                stroke([0.08, y, 0.92, y]);
                ctx.fillStyle = Theme.bg;
                ctx.beginPath();
                ctx.arc(w * knobs[k], w * y, w * 0.11, 0, Math.PI * 2);
                ctx.fill();
                ctx.stroke();
                ctx.fillStyle = glyph.color;
            }
            break;
        case "erase":
            line([0.32, 0.22, 0.9, 0.22, 0.9, 0.78, 0.32, 0.78, 0.08, 0.5]);
            ctx.closePath();
            ctx.stroke();
            stroke([0.5, 0.38, 0.72, 0.62]);
            stroke([0.72, 0.38, 0.5, 0.62]);
            break;
        case "add":
            stroke([0.5, 0.18, 0.5, 0.82]);
            stroke([0.18, 0.5, 0.82, 0.5]);
            break;
        case "bookmark":
            line([0.26, 0.14, 0.74, 0.14, 0.74, 0.86, 0.5, 0.66, 0.26, 0.86]);
            ctx.closePath();
            ctx.stroke();
            break;
        case "info":
            arc(0.5, 0.5, 0.38, 0, 2);
            dot(0.5, 0.3, 0.06);
            stroke([0.5, 0.46, 0.5, 0.72]);
            break;
        case "subtitles":
            ctx.strokeRect(w * 0.1, w * 0.22, w * 0.8, w * 0.56);
            stroke([0.24, 0.5, 0.42, 0.5]);
            stroke([0.56, 0.5, 0.76, 0.5]);
            stroke([0.24, 0.64, 0.6, 0.64]);
            break;
        case "repeat":
            stroke([0.2, 0.44, 0.2, 0.3, 0.8, 0.3, 0.8, 0.46]);
            stroke([0.7, 0.38, 0.8, 0.48, 0.9, 0.38]);
            stroke([0.8, 0.56, 0.8, 0.7, 0.2, 0.7, 0.2, 0.54]);
            stroke([0.1, 0.62, 0.2, 0.52, 0.3, 0.62]);
            break;
        case "camera":
            ctx.strokeRect(w * 0.1, w * 0.3, w * 0.8, w * 0.52);
            arc(0.5, 0.56, 0.14, 0, 2);
            stroke([0.36, 0.3, 0.42, 0.18, 0.58, 0.18, 0.64, 0.3]);
            break;
        case "folder":
            line([0.1, 0.8, 0.1, 0.22, 0.4, 0.22, 0.5, 0.34, 0.9, 0.34, 0.9, 0.8]);
            ctx.closePath();
            ctx.stroke();
            break;
        case "playlist":
            stroke([0.12, 0.26, 0.88, 0.26]);
            stroke([0.12, 0.5, 0.88, 0.5]);
            stroke([0.12, 0.74, 0.5, 0.74]);
            fill([0.66, 0.62, 0.66, 0.9, 0.9, 0.76]);
            break;
        case "dots":
            dot(0.2, 0.5, 0.085); dot(0.5, 0.5, 0.085); dot(0.8, 0.5, 0.085);
            break;
        case "forward":
            stroke([0.36, 0.16, 0.70, 0.5, 0.36, 0.84]);
            break;
        case "grid":
            ctx.strokeRect(w * 0.14, w * 0.14, w * 0.28, w * 0.28);
            ctx.strokeRect(w * 0.58, w * 0.14, w * 0.28, w * 0.28);
            ctx.strokeRect(w * 0.14, w * 0.58, w * 0.28, w * 0.28);
            ctx.strokeRect(w * 0.58, w * 0.58, w * 0.28, w * 0.28);
            break;
        case "list":
            for (var r = 0; r < 3; r++) {
                dot(0.16, 0.24 + 0.26 * r, 0.06);
                stroke([0.34, 0.24 + 0.26 * r, 0.88, 0.24 + 0.26 * r]);
            }
            break;
        case "check":
            stroke([0.16, 0.54, 0.4, 0.78, 0.86, 0.24]);
            break;
        case "search":
            arc(0.42, 0.42, 0.28, 0, 2);
            stroke([0.63, 0.63, 0.88, 0.88]);
            break;
        case "star":
            var tips = [];
            for (var t = 0; t < 10; t++) {
                var reach = t % 2 === 0 ? 0.44 : 0.19;
                var turn = -Math.PI / 2 + t * Math.PI / 5;
                tips.push(0.5 + reach * Math.cos(turn), 0.52 + reach * Math.sin(turn));
            }
            fill(tips);
            break;
        case "next":
            fill([0.16, 0.18, 0.16, 0.82, 0.66, 0.5]);
            ctx.fillRect(w * 0.72, w * 0.18, w * 0.12, w * 0.64);
            break;
        case "previous":
            fill([0.84, 0.18, 0.84, 0.82, 0.34, 0.5]);
            ctx.fillRect(w * 0.16, w * 0.18, w * 0.12, w * 0.64);
            break;
        case "shuffle":
            stroke([0.1, 0.3, 0.3, 0.3, 0.62, 0.7, 0.88, 0.7]);
            stroke([0.1, 0.7, 0.3, 0.7, 0.4, 0.58]);
            stroke([0.52, 0.42, 0.62, 0.3, 0.88, 0.3]);
            stroke([0.78, 0.2, 0.88, 0.3, 0.78, 0.4]);
            stroke([0.78, 0.6, 0.88, 0.7, 0.78, 0.8]);
            break;
        case "rewind":
            stroke([0.48, 0.2, 0.2, 0.5, 0.48, 0.8]);
            stroke([0.82, 0.2, 0.54, 0.5, 0.82, 0.8]);
            break;
        case "fastforward":
            stroke([0.18, 0.2, 0.46, 0.5, 0.18, 0.8]);
            stroke([0.52, 0.2, 0.8, 0.5, 0.52, 0.8]);
            break;
        case "refresh":
            arc(0.5, 0.5, 0.38, 0.45, 1.95);
            fill([0.32, 0.84, 0.62, 0.78, 0.5, 1.0]);
            break;
        }
    }
}
