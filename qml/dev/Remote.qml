import QtQuick 2.12
import QtQuick.Window 2.12
import Qt.labs.platform 1.0

/*
 * Development only: lets the app be driven and photographed over adb, so a
 * change can be checked on the phone without hands on it. To be removed before
 * the 0.1.0 release (docs/PLAN.md, Phase 5).
 *
 * It does nothing unless ~/.cache/gemplayer.yenis/dev-remote.txt exists when
 * the app starts. A line in that file is "<number> <command> [argument]"; a
 * new number runs the command once:
 *
 *   adb shell "echo '7 open /home/phablet/Videos/x.mp4' > ~/.cache/gemplayer.yenis/dev-remote.txt"
 *
 * "shot <name>" saves the app's own window to ~/.cache/gemplayer.yenis/shots/<name>.png.
 * tools/dev.sh wraps all of this; docs/DEVELOPING.md lists the commands.
 */
Item {
    id: remote

    property var shell: null

    readonly property string cacheDir: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
                                           .toString().replace("file://", "") + "/gemplayer.yenis"
    property int lastCommand: -1

    Timer {
        id: poll
        interval: 400
        repeat: true
        onTriggered: remote.read(false)
    }

    Component.onCompleted: read(true)

    function read(first) {
        var request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            var parts = (request.responseText || "").trim().split(" ");
            var number = parseInt(parts[0]);
            if (isNaN(number))
                return;
            if (first) {
                // The file is there: stay on. Its present content is old.
                lastCommand = number;
                poll.start();
                console.log("REMOTE on");
                return;
            }
            if (number === lastCommand)
                return;
            lastCommand = number;
            if (parts.length > 1)
                run(parts[1], parts.slice(2).join(" "));
        };
        try {
            request.open("GET", "file://" + cacheDir + "/dev-remote.txt");
            request.send();
        } catch (e) {
            // No command file: the remote stays off.
        }
    }

    function run(name, argument) {
        var p = shell.playback;
        var v = shell.videoPage;
        console.log("REMOTE " + name + (argument ? " " + argument : ""));
        if (name === "open") shell.openPath(argument);
        else if (name === "play") p.play();
        else if (name === "pause") p.pause();
        else if (name === "next") p.next();
        else if (name === "previous") p.previous();
        else if (name === "queuejump") p.jumpTo(parseInt(argument));
        else if (name === "seek") p.seekTo(parseInt(argument));
        else if (name === "seekby") p.seekBy(parseInt(argument));
        else if (name === "audio") shell.toAudio();
        else if (name === "video") shell.toVideo();
        else if (name === "back") shell.back();
        else if (name === "home") shell.page = "home";
        else if (name === "atab") shell.audioLibrary.setTab(argument);
        else if (name === "aalbumgrid") shell.audioLibrary.setAlbumGrid(argument === "1");
        else if (name === "aselect") shell.audioLibrary.toggleSelected(shell.audioLibrary.shown[parseInt(argument)]);
        else if (name === "aselaction") shell.audioLibrary.selectionAction(argument);
        else if (name === "asort") shell.audioLibrary.setSort(argument.split(" ")[0], argument.split(" ")[1] === "desc");
        else if (name === "afavonly") shell.audioLibrary.setOnlyFavourites(argument === "1");
        else if (name === "adisplay") shell.audioLibrary.openDisplaySheet();
        else if (name === "afilter") { if (argument) shell.audioLibrary.setFilter(argument); else shell.audioLibrary.closeFilter(); }
        else if (name === "atap") shell.audioLibrary.activate(shell.audioLibrary.shown[parseInt(argument)]);
        else if (name === "aaction") shell.audioLibrary.itemAction(shell.audioLibrary.shown[parseInt(argument.split(" ")[0])], argument.split(" ")[1]);
        else if (name === "amenu") shell.audioLibrary.openItemMenu(parseInt(argument));
        else if (name === "queueremove") p.removeAt(parseInt(argument));
        else if (name === "stopafter") p.setStopAfter(parseInt(argument));
        else if (name === "repeat") p.setRepeat(argument);
        else if (name === "shuffle") p.setShuffle(argument === "1");
        else if (name === "expand") shell.page = "audio";
        else if (name === "stop") shell.closePlayer();
        else if (shell.audioPage && name === "sheet") shell.audioPage.openSheet(argument);
        else if (shell.audioPage && name === "tapseek") shell.audioPage.tapSeek(argument);
        else if (shell.audioPage && name === "info") shell.audioPage.showInfo(argument, 5000);
        else if (shell.audioPage && name === "volume") shell.audioPage.changeVolume(parseFloat(argument));
        else if (shell.audioPage && name === "brightness") shell.audioPage.changeBrightness(parseFloat(argument));
        else if (shell.audioPage && name === "level") shell.audioPage.showLevel(argument, 0.62, 5000);
        else if (shell.audioPage && name === "bookmark") shell.audioPage.addBookmark();
        else if (shell.audioPage && name === "ab") shell.audioPage.markAB();
        else if (name === "tab") { shell.page = "home"; shell.tab = argument; }
        else if (name === "view") shell.videoLibrary.setGrid(argument === "grid");
        else if (name === "sort") shell.videoLibrary.setSort(argument.split(" ")[0], argument.split(" ")[1] === "desc");
        else if (name === "group") shell.videoLibrary.setGrouping(argument);
        else if (name === "opengroup") shell.videoLibrary.activate(shell.videoLibrary.shown[parseInt(argument)]);
        else if (name === "select") shell.videoLibrary.toggleSelected(shell.videoLibrary.shown[parseInt(argument)]);
        else if (name === "selaction") shell.videoLibrary.selectionAction(argument);
        else if (name === "tapaction") shell.videoLibrary.setTapAction(argument);
        else if (name === "tap") shell.videoLibrary.activate(shell.videoLibrary.shown[parseInt(argument)]);
        else if (name === "newgroup") shell.videoLibrary.addToNewGroup(shell.videoLibrary.selectedVideos(), argument);
        else if (name === "joingroup") shell.videoLibrary.addToExistingGroup(shell.videoLibrary.selectedVideos(), shell.videoLibrary.shown[parseInt(argument)].key);
        else if (name === "renamegroup") shell.videoLibrary.renameGroup(shell.videoLibrary.shown[parseInt(argument.split(" ")[0])], argument.split(" ").slice(1).join(" "));
        else if (name === "clearselection") shell.videoLibrary.clearSelection();
        else if (name === "favonly") shell.videoLibrary.setOnlyFavourites(argument === "1");
        else if (name === "filter") shell.videoLibrary.setFilter(argument);
        else if (name === "fav") shell.videoLibrary.toggleFavourite("file://" + argument);
        else if (name === "focusfilter") shell.videoLibrary.openFilter();
        else if (name === "hidekeyboard") shell.videoLibrary.dismissKeyboard();
        else if (name === "display") shell.videoLibrary.openDisplaySheet();
        else if (name === "closesheets") { shell.videoLibrary.closeSheets(); shell.audioLibrary.closeSheets(); }
        else if (name === "itemaction") shell.videoLibrary.itemAction(shell.videoLibrary.shown[parseInt(argument.split(" ")[0])], argument.split(" ")[1]);
        else if (name === "itemmenu") shell.videoLibrary.openItemMenu(parseInt(argument));
        else if (name === "diagnostics") shell.page = "diagnostics";
        else if (v && name === "controls") { if (argument === "1") v.showControls(); else v.controlsShown = false; }
        else if (v && name === "angle") { v.orientationLocked = true; v.contentAngle = parseInt(argument); }
        else if (v && name === "aspect") v.setAspect(parseInt(argument));
        else if (v && name === "lock") v.locked = argument === "1";
        else if (v && name === "sheet") v.openSheet(argument);
        else if (v && name === "info") v.showInfo(argument, 5000);
        else if (v && name === "level") v.showLevel(argument, 0.62, 5000);
        else if (v && name === "volume") v.changeVolume(parseFloat(argument));
        else if (v && name === "bookmark") v.addBookmark();
        else if (v && name === "ab") v.markAB();
        else if (v && name === "screenshot") v.takeScreenshot();
        else if (v && name === "subdelay") v.changeSubtitleDelay(parseInt(argument));
        else if (name === "sleep") shell.sleepTimer.start(parseInt(argument), false, false);
        else if (v && name === "tapseek") v.tapSeek(argument);
        else if (v && name === "follow") { v.orientationLocked = false; v.followSensor(); }
        else if (v && name === "brightness") v.changeBrightness(parseFloat(argument));
        else if (name === "shot") shot(argument || "shot");
        else if (name === "state") state();
    }

    function state() {
        var p = shell.playback;
        var v = shell.videoPage;
        console.log("REMOTE STATE " + JSON.stringify({
            page: shell.page, tab: shell.tab, title: p.title, queue: (p.queueIndex + 1) + "/" + p.queue.length, repeat: p.repeat, shuffle: p.shuffle, stopAfter: p.stopAfter, upcoming: p.queue.slice(p.queueIndex + 1, p.queueIndex + 6).map(function(m) { return m.title; }), grid: shell.videoLibrary.grid, selected: shell.tab === "audio" ? shell.audioLibrary.selectionCount : shell.videoLibrary.selectionCount, shown: shell.tab === "audio" ? shell.audioLibrary.shownTitles() : shell.videoLibrary.shownTitles(), keyboard: shell.keyboardHeight, url: p.url, artist: p.artist, art: p.art, mini: shell.audioActive, playing: p.playing, position: p.position,
            raw: p.player.position, duration: p.duration, audioMode: p.audioMode,
            hasPicture: p.hasPicture, seekable: p.seekable, status: p.player.status,
            error: p.error, starting: p.starting, ab: [p.abStart, p.abEnd],
            sleep: shell.sleepTimer.remaining,
            angle: v ? v.contentAngle : null, window: shell.width + "x" + shell.height,
            sensor: v ? v.Screen.orientation : null, app: Qt.application.state, wall: Date.now()
        }));
    }

    function shot(name) {
        var target = cacheDir + "/shots/" + name + ".png";
        var ok = shell.grabToImage(function(grab) {
            console.log("REMOTE SHOT " + (grab.saveToFile(target) ? "saved " : "FAILED ") + target);
        });
        if (!ok)
            console.log("REMOTE SHOT refused");
    }
}
