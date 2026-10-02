import QtQuick 2.12
import QtSystemInfo 5.0

/* Spike: keeping the display on, as the stock Music app does. */
Item {
    property bool keepOn: false

    ScreenSaver {
        screenSaverEnabled: !keepOn
    }
}
