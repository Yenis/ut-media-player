.pragma library

/*
 * The arithmetic of the video player's touch gestures.
 *
 * Zones, thresholds and the seek formula follow VLC for Android,
 * application/vlc-android/src/org/videolan/vlc/gui/video/VideoTouchDelegate.kt,
 * copyright VLC authors and VideoLAN, GPL-2.0-or-later. See docs/VLC-FEATURES.md,
 * "Values worth matching".
 */

// Gestures that start this close to a screen edge are ignored (24 dp).
var EDGE_MARGIN_MM = 3.8;

// A swipe is vertical when it is steeper than this, and only once it has
// covered this share of the screen height.
var VERTICAL_SLOPE = 2;
var VERTICAL_START = 0.05;

// A swipe over 80 % of the screen height covers the whole range.
var VERTICAL_GAIN = 1.25;

// No seek under 1 cm of travel.
var SEEK_DEAD_ZONE_CM = 1;

// Taps this close together are one multi-tap.
var MULTI_TAP_MS = 300;

/*
 * Length of a swipe seek, in milliseconds: 3 s plus a fourth-power curve that
 * reaches 10 minutes at 8 cm. Drifting vertically while swiping divides the
 * jump, for fine control; `divisor` is what the overlay shows as "x0.5".
 */
function seekJump(cm, verticalInches) {
    var divisor = Math.max(1, Math.round((Math.abs(verticalInches) + 0.5) * 2));
    var sign = cm >= 0 ? 1 : -1;
    var jump = sign * (600000 * Math.pow(cm / 8, 4) + 3000) / divisor;
    return { jump: Math.round(jump), divisor: divisor };
}

// Keeps a jump inside the file.
function clampJump(jump, position, duration) {
    if (jump > 0 && position + jump > duration)
        return duration - position;
    if (jump < 0 && position + jump < 0)
        return -position;
    return jump;
}

// Which vertical gesture a swipe at x belongs to: right of 4/7 of the width,
// left of 3/7, and nothing in between.
function verticalZone(x, width) {
    if (x > 4 * width / 7)
        return "right";
    if (x < 3 * width / 7)
        return "left";
    return "";
}

// What a double tap at x does: the outer quarters seek, the middle pauses.
function tapZone(x, width) {
    if (x < width / 4)
        return "back";
    if (x > width * 0.75)
        return "forward";
    return "centre";
}
