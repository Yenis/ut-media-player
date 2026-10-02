pragma Singleton
import QtQuick 2.12

/*
 * One place for the gemstech palette and for grid-unit scaling.
 *
 * Main.qml sets `gu` from Ubuntu Touch's own grid unit before anything is
 * shown; a singleton cannot read it itself.
 */
QtObject {
    id: theme

    property real gu: 8

    function u(n) { return n * gu; }

    // Surfaces - the near-black of the gem discs.
    readonly property color bg:         "#07070C"
    readonly property color surface:    "#101017"
    readonly property color surfaceAlt: "#16161F"
    readonly property color line:       "#23232E"

    // Type.
    readonly property color text:    "#ECECF2"
    readonly property color textDim: "#8A8A9C"
    readonly property color textFaint: "#5A5A6B"

    // The gemstech palette. Topaz is the app's accent.
    readonly property color topaz:    "#E8A317"
    readonly property color ruby:     "#FF4257"
    readonly property color emerald:  "#2BD47D"
    readonly property color sapphire: "#4E9BFF"
    readonly property color diamond:  "#BFD8EE"
    readonly property color amethyst: "#C06BFF"

    // Semantic.
    readonly property color accent: topaz
    readonly property color good:   emerald
    readonly property color bad:    ruby

    // Type scale, in grid units.
    readonly property int fontXS: Math.round(u(1.15))
    readonly property int fontS:  Math.round(u(1.35))
    readonly property int fontM:  Math.round(u(1.6))
    readonly property int fontL:  Math.round(u(2.0))
    readonly property int fontXL: Math.round(u(2.6))
}
