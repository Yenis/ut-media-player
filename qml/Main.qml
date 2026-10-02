import QtQuick 2.12
import QtQuick.Window 2.12
import Gem 1.0

/*
 * GemPlayer - a VLC-style media player for Ubuntu Touch.
 *
 * This file only bootstraps. It fixes the app identity and the grid unit, then
 * loads the shell. Everything that stores data is created after the identity
 * is set, so its files land in the folders AppArmor allows.
 *
 * Phase 0: the shell is the spike's diagnostics page (qml/spike/). The player
 * replaces it in Phase 1.
 */
Window {
    id: root

    visible: true
    width: Theme.u(50)
    height: Theme.u(90)
    title: "GemPlayer"
    color: Theme.bg

    Component.onCompleted: {
        // qmlscene starts the app, so the identity is set here. Both names
        // must be the click app id: Ubuntu Touch's launcher pre-sets the
        // application name but leaves the organization empty, and AppArmor
        // only allows writing under folders named after the app id.
        Qt.application.organization = "gemplayer.yenis";
        Qt.application.name = "gemplayer.yenis";

        Theme.gu = platformGu();

        shell.active = true;
    }

    // The platform's own grid unit where it exists (25 px on a Pixel 3a),
    // otherwise a Screen estimate.
    function platformGu() {
        if (lomiriUnits.status === Loader.Ready)
            return lomiriUnits.item.gu;
        if (ubuntuUnits.status === Loader.Ready)
            return ubuntuUnits.item.gu;
        return Math.max(8, Screen.pixelDensity * 1.27);
    }

    // Loaded by URL, not through the Gem module: these toolkits only exist on
    // Ubuntu Touch, and anywhere else the Loader fails quietly and the Screen
    // estimate is used. Ubuntu.Components covers devices from before the
    // Lomiri rename.
    Loader {
        id: lomiriUnits
        source: "platform/LomiriUnits.qml"
    }
    Loader {
        id: ubuntuUnits
        active: lomiriUnits.status === Loader.Error
        source: "platform/UbuntuUnits.qml"
    }

    Loader {
        id: shell
        anchors.fill: parent
        active: false
        focus: true
        source: "spike/SpikeShell.qml"
        onLoaded: item.appWindow = root
    }
}
