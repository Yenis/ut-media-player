import QtQuick 2.12
import QtQuick.Window 2.12
import Gem 1.0
import "../js/Gestures.js" as Gestures

/*
 * The video player's touch gestures, as VLC for Android has them (see
 * Gestures.js for the numbers). This item only recognises; the page decides
 * what a gesture does.
 *
 *   single tap            tapped()
 *   double tap            doubleTapped("back" | "forward" | "centre")
 *   horizontal swipe      seekPreview(cm, inches) while moving, seekCommit on release
 *   vertical swipe        volumeMoved(delta) on the right, brightnessMoved(delta) on the left
 *   pinch                 pinched(grow)
 */
Item {
    id: layer

    property bool locked: false
    property bool seekable: true

    property bool volumeEnabled: true
    property bool brightnessEnabled: true
    property bool swipeSeekEnabled: true
    property bool doubleTapSeekEnabled: true
    property bool doubleTapPlayEnabled: true
    property bool pinchEnabled: true

    signal tapped()
    signal doubleTapped(string zone)
    signal seekPreview(real cm, real verticalInches)
    signal seekCommit(real cm, real verticalInches)
    signal volumeMoved(real delta)
    signal brightnessMoved(real delta)
    signal verticalEnded()
    signal pinched(bool grow)

    readonly property real pxPerMm: Screen.pixelDensity
    readonly property real edge: Gestures.EDGE_MARGIN_MM * pxPerMm
    readonly property real tapSlop: 1.3 * pxPerMm

    // "", "seek", "volume", "brightness" or "ignore"
    property string _action: ""
    property real _startX: 0
    property real _startY: 0
    property real _refX: 0
    property real _refY: 0
    property bool _startedInBounds: false
    property bool _verticalActive: false
    property int _taps: 0
    property real _lastTapAt: 0
    property real _lastTapX: 0

    function _inBounds(x, y) {
        return x >= edge && x <= width - edge && y >= edge && y <= height - edge;
    }

    function _vertical(x, dy) {
        var zone = Gestures.verticalZone(x, width);
        if (zone === "" || !_startedInBounds)
            return;
        if (!volumeEnabled && !brightnessEnabled)
            return;
        // Each side has its own gesture; if one is switched off, the other
        // takes both sides.
        var action = zone === "right" ? (volumeEnabled ? "volume" : "brightness")
                                      : (brightnessEnabled ? "brightness" : "volume");
        if (_action !== "" && _action !== action)
            return;
        _action = action;
        var delta = -(dy / height) * Gestures.VERTICAL_GAIN;
        if (action === "volume")
            volumeMoved(delta);
        else
            brightnessMoved(delta);
    }

    function _seekArguments(x, y) {
        return { cm: (x - _startX) / (pxPerMm * 10),
                 inches: Math.abs(_startY - y) / (pxPerMm * 25.4) };
    }

    Timer {
        id: singleTap
        interval: Gestures.MULTI_TAP_MS
        onTriggered: if (layer._taps === 1) layer.tapped()
    }

    PinchArea {
        anchors.fill: parent
        enabled: layer.pinchEnabled && !layer.locked
        onPinchStarted: layer._action = "ignore"
        onPinchFinished: layer.pinched(pinch.scale > 1.0)

        MouseArea {
            anchors.fill: parent

            onPressed: {
                layer._action = "";
                layer._verticalActive = false;
                layer._startX = layer._refX = mouse.x;
                layer._startY = layer._refY = mouse.y;
                layer._startedInBounds = layer._inBounds(mouse.x, mouse.y);
            }

            onPositionChanged: {
                if (layer.locked || layer._action === "ignore")
                    return;
                var dx = mouse.x - layer._refX;
                var dy = mouse.y - layer._refY;
                var slope = Math.abs(dy) / Math.max(Math.abs(dx), 0.001);

                if (layer._action !== "seek" && slope > Gestures.VERTICAL_SLOPE) {
                    if (!layer._verticalActive) {
                        if (Math.abs(dy) / layer.height >= Gestures.VERTICAL_START) {
                            layer._verticalActive = true;
                            layer._refX = mouse.x;
                            layer._refY = mouse.y;
                        }
                        return;
                    }
                    layer._refX = mouse.x;
                    layer._refY = mouse.y;
                    layer._vertical(mouse.x, dy);
                } else if (layer._startX < layer.width * 0.95) {
                    if (!layer.swipeSeekEnabled || !layer._startedInBounds || !layer.seekable)
                        return;
                    if (layer._action !== "" && layer._action !== "seek")
                        return;
                    var s = layer._seekArguments(mouse.x, mouse.y);
                    if (Math.abs(s.cm) < Gestures.SEEK_DEAD_ZONE_CM)
                        return;
                    layer._action = "seek";
                    layer.seekPreview(s.cm, s.inches);
                }
            }

            onReleased: {
                var action = layer._action;
                layer._action = "";

                if (action === "seek") {
                    var s = layer._seekArguments(mouse.x, mouse.y);
                    layer.seekCommit(s.cm, s.inches);
                    return;
                }
                if (action === "volume" || action === "brightness") {
                    layer.verticalEnded();
                    return;
                }
                if (action === "ignore")
                    return;

                var still = Math.abs(mouse.x - layer._startX) < layer.tapSlop
                            && Math.abs(mouse.y - layer._startY) < layer.tapSlop;
                if (!still)
                    return;

                if (layer.locked) {
                    layer.tapped();
                    return;
                }

                var now = Date.now();
                if (layer._taps > 0 && now - layer._lastTapAt < Gestures.MULTI_TAP_MS)
                    layer._taps += 1;
                else
                    layer._taps = 1;
                layer._lastTapAt = now;

                if (layer._taps > 1) {
                    singleTap.stop();
                    var zone = Gestures.tapZone(mouse.x, layer.width);
                    if (zone !== "centre" && layer.doubleTapSeekEnabled)
                        layer.doubleTapped(zone);
                    else if (layer.doubleTapPlayEnabled)
                        layer.doubleTapped("centre");
                } else if (layer.doubleTapSeekEnabled || layer.doubleTapPlayEnabled) {
                    singleTap.restart();
                } else {
                    layer.tapped();
                }
            }

            onCanceled: layer._action = "ignore"
        }
    }
}
