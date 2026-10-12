import QtQuick 2.12
import GSettings 1.0

/*
 * Whether the app is frozen when it is left. Ubuntu Touch freezes an app a
 * few seconds after it leaves the foreground, unless its name is in the
 * system setting `com.canonical.qtmir lifecycle-exempt-appids`, which is
 * how the stock Music app keeps running. An unconfined app can put itself
 * there (docs/PLAN.md, Phase 1, "Discuss"); this does, when asked, and
 * takes itself out again.
 *
 * The list is the system's, so it is also the one record of the choice:
 * nothing is kept in the app's own settings. Loaded by URL, since the
 * module only exists on the device.
 */
Item {
    id: background

    readonly property string appId: "gemplayer.yenis"

    // The app is on the list.
    property bool exempt: false

    GSettings {
        id: lifecycle
        schema.id: "com.canonical.qtmir"
        onChanged: if (key === "lifecycleExemptAppids") background._read()
    }

    function _list() {
        var kept = lifecycle.lifecycleExemptAppids;
        var list = [];
        for (var i = 0; kept && i < kept.length; i++)
            list.push("" + kept[i]);
        return list;
    }

    function _read() {
        exempt = _list().indexOf(appId) >= 0;
    }

    // Adds the app to the list, or takes it out. The other names stay.
    function setExempt(on) {
        var list = _list().filter(function(name) { return name !== background.appId; });
        if (on)
            list.push(appId);
        lifecycle.lifecycleExemptAppids = list;
        _read();
    }

    Component.onCompleted: _read()
}
