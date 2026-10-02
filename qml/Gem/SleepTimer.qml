import QtQuick 2.12

/*
 * Stops playback after a while, as VLC's sleep timer does.
 *
 * It can only act while the app is running. Ubuntu Touch freezes an app a few
 * seconds after it leaves the foreground or the screen goes off, so a timer
 * set for audio playing behind the lock screen fires late: when the app is
 * next opened. It works as expected for a video, which keeps the screen on.
 */
Item {
    id: sleep

    property real endsAt: 0             // clock time in ms; 0 is off
    property int interval: 0            // ms, for "reset on interaction"
    property bool waitForEnd: false
    property bool resetOnInteraction: false

    readonly property bool active: endsAt > 0
    property int remaining: 0           // ms

    // Time is up and the file may be stopped now.
    signal expired()

    function start(ms, wait, reset) {
        if (ms <= 0) {
            cancel();
            return;
        }
        interval = ms;
        waitForEnd = wait;
        resetOnInteraction = reset;
        endsAt = Date.now() + ms;
        remaining = ms;
    }

    function cancel() {
        endsAt = 0;
        remaining = 0;
    }

    // Any touch on the player.
    function interaction() {
        if (active && resetOnInteraction) {
            endsAt = Date.now() + interval;
            remaining = interval;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: sleep.active
        triggeredOnStart: true
        onTriggered: {
            sleep.remaining = Math.max(0, sleep.endsAt - Date.now());
            if (sleep.remaining > 0)
                return;
            var wait = sleep.waitForEnd;
            sleep.cancel();
            // "Wait for the current item to finish": with one file and no
            // queue, that is simply letting it play out.
            if (!wait)
                sleep.expired();
        }
    }
}
