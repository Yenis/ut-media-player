import QtQuick 2.12
import QMenuModel 1.0

/*
 * The screen's backlight, through the power indicator's own action: the same
 * thing its brightness slider changes. Loaded by URL, since QMenuModel only
 * exists on the device.
 *
 * Not offered while the phone sets its brightness automatically: the two
 * would fight.
 */
Item {
    readonly property bool available: _valid(brightnessAction) && !(_valid(autoAction) && autoAction.state === true)
    readonly property real level: _valid(brightnessAction) ? brightnessAction.state : 1

    property var brightnessAction: actions.action("brightness")
    property var autoAction: actions.action("auto-brightness")

    function _valid(action) {
        return action !== null && action !== undefined && action.valid;
    }

    function set(value) {
        if (_valid(brightnessAction))
            brightnessAction.updateState(Math.max(0, Math.min(1, value)));
    }

    QDBusActionGroup {
        id: actions
        busType: DBus.SessionBus
        busName: "org.ayatana.indicator.power"
        objectPath: "/org/ayatana/indicator/power"
        Component.onCompleted: start()
    }
}
