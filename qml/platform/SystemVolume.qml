import QtQuick 2.12
import QMenuModel 1.0

/*
 * The phone's media volume, through the sound indicator's own action: the
 * same thing the volume keys and the indicator's slider change.
 *
 * The backend's own volume cannot be used: `MediaPlayer.volume` is accepted
 * and ignored (qtubuntu-media's setVolume is an empty function). Loaded by
 * URL, since QMenuModel only exists on the device.
 */
Item {
    readonly property bool available: volumeAction !== null && volumeAction !== undefined && volumeAction.valid
    readonly property real level: available ? volumeAction.state : 1

    property var volumeAction: actions.action("volume")

    function set(value) {
        if (available)
            volumeAction.updateState(Math.max(0, Math.min(1, value)));
    }

    QDBusActionGroup {
        id: actions
        busType: DBus.SessionBus
        busName: "org.ayatana.indicator.sound"
        objectPath: "/org/ayatana/indicator/sound"
        Component.onCompleted: start()
    }
}
