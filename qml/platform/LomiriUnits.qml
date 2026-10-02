import QtQuick 2.12
import Lomiri.Components 1.3

// Ubuntu Touch's grid unit (GRID_UNIT_PX), exposed without pulling Lomiri into
// the portable Gem module. Loaded through a Loader in Main.qml.
Item {
    readonly property real gu: units.gu(1)
}
