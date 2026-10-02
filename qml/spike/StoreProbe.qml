import QtQuick 2.12
import Qt.labs.settings 1.0
import QtQuick.LocalStorage 2.0

/* Spike: do settings and the SQLite store persist under confinement? */
Item {
    readonly property bool autoRun: settings.autoRun

    Settings {
        id: settings
        category: "spike"
        property int launches: 0
        property bool autoRun: true
    }

    function setAutoRun(on) {
        settings.setValue("autoRun", on);
        settings.sync();
        settings.autoRun = on;
    }

    // Counts launches; a number above 1 proves the file survived a restart.
    function bumpLaunches() {
        var n = parseInt(settings.value("launches", 0)) + 1;
        settings.setValue("launches", n);
        settings.sync();
        return n;
    }

    // Adds a row per run; a count above 1 proves the database survived.
    function bumpDatabase() {
        var db = LocalStorage.openDatabaseSync("gemplayer-spike", "1.0", "Spike", 100000);
        var n = 0;
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS runs(at TEXT)");
            tx.executeSql("INSERT INTO runs VALUES(?)", [new Date().toISOString()]);
            n = tx.executeSql("SELECT COUNT(*) AS n FROM runs").rows.item(0).n;
        });
        return n;
    }
}
