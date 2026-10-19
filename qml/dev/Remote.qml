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
        else if (name === "bopen") { if (argument) shell.browser.enter(argument); else shell.browser.path = ""; }
        else if (name === "btap") shell.browser.activate(shell.browser.shown[parseInt(argument)]);
        else if (name === "baction") shell.browser.itemAction(shell.browser.shown[parseInt(argument.split(" ")[0])], argument.split(" ")[1]);
        else if (name === "bfav") shell.browser.setFavourite(shell.browser.path, !shell.browser.isFavourite);
        else if (name === "bplay") shell.browser.playHere(null);
        else if (name === "tipsagain") shell.settingsPage.showTipsAgain();
        else if (name === "resume") p.answerResume(argument.split(" ")[0] === "yes", argument.split(" ")[1] === "all");
        else if (name === "landscape") landscape(argument === "1");
        else if (name === "tips") {
            var tp = shell.page === "audio" ? shell.audioPage : shell.videoPage;
            if (argument === "show") tp.showTips();
            else if (argument === "next") tp.tipsNext();
            else tp.tipsClose();
        }
        else if (name === "incoming") shell.openIncoming(argument.split(" "));
        else if (name === "share") { if (argument) shell.shareMedia([shell.fileMedia("file://" + argument)]); else if (shell.sharing) shell.back(); }
        else if (name === "find") { shell.openSearch(); shell.searchPage.setQuery(argument); }
        else if (name === "ftap") shell.searchPage.activate(parseInt(argument));
        else if (name === "fmenu") shell.searchPage.openMenu(parseInt(argument));
        else if (name === "faction") shell.searchPage.itemAction(parseInt(argument.split(" ")[0]), argument.split(" ")[1]);
        else if (name === "exempt") { if (shell.backgroundRunning) shell.backgroundRunning.setExempt(argument === "1"); }
        else if (name === "sscroll") shell.settingsPage.scrollTo(parseInt(argument));
        else if (name === "pref") shell.prefs.setFromText(argument.split(" ")[0], argument.split(" ")[1]);
        else if (name === "sclear") { if (argument.split(" ")[1] === "now") shell.settingsPage.clear(argument.split(" ")[0]); else shell.settingsPage.askClear(argument); }
        else if (name === "history" || name === "about" || name === "settings") { shell.page = "home"; shell.tab = "more"; shell.moreView = name; }
        else if (name === "hkeep") p.setKeepHistory(argument === "1");
        else if (name === "hmenu") shell.historyPage.openMenu(parseInt(argument));
        else if (name === "haction") shell.historyPage.itemAction(parseInt(argument.split(" ")[0]), argument.split(" ")[1]);
        else if (name === "hclear") { if (argument === "now") shell.historyPage.store.clearHistory(); else shell.historyPage.askClear(); }
        else if (name === "streams") { shell.page = "home"; shell.tab = "more"; shell.moreView = "streams"; }
        else if (name === "sallow") shell.setStreamsAllowed(argument === "1");
        else if (name === "sopen") shell.openStream(argument, "");
        else if (name === "smenu") shell.streamsPage.openMenu(parseInt(argument));
        else if (name === "saction") shell.streamsPage.itemAction(parseInt(argument.split(" ")[0]), argument.split(" ")[1], argument.split(" ").slice(2).join(" "));
        else if (name === "gate") { if (argument === "allow") shell.streamGate.allow(); else shell.streamGate.close(); }
        else if (name === "pnew") shell.playlistsPage.create(argument);
        else if (name === "ptap") shell.playlistsPage.activate(parseInt(argument));
        else if (name === "pmenu") shell.playlistsPage.openMenu(parseInt(argument));
        else if (name === "paction") {
            var pl = shell.playlistsPage, at = parseInt(argument.split(" ")[0]), what = argument.split(" ")[1];
            if (pl.current) pl.itemAction(at, what);
            else pl.playlistAction(pl.playlists[at], what, argument.split(" ").slice(2).join(" "));
        }
        else if (name === "pick") shell.playlistPicker.addTo(shell.playlistsPage.playlists[parseInt(argument)]);
        else if (name === "picknew") shell.playlistPicker.addToNew(argument);
        else if (shell.audioPage && name === "savequeue") shell.audioPage.savePlaylist();
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
        else if (shell.audioPage && name === "qfilter") shell.audioPage.setQueueFilter(argument);
        else if (shell.audioPage && name === "qrows") console.log("REMOTE QROWS " + JSON.stringify(shell.audioPage.queueRows().slice(0, 8)));
        else if (name === "queuemove") p.moveItem(parseInt(argument.split(" ")[0]), parseInt(argument.split(" ")[1]));
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
        else if (name === "closesheets") { shell.videoLibrary.closeSheets(); shell.audioLibrary.closeSheets(); shell.browser.closeSheets(); shell.playlistsPage.closeSheets(); shell.playlistPicker.close(); shell.streamsPage.closeSheets(); shell.historyPage.closeSheets(); shell.settingsPage.closeSheets(); shell.searchPage.closeSheets(); }
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
            page: shell.page, tab: shell.tab, title: p.title, queue: (p.queueIndex + 1) + "/" + p.queue.length, repeat: p.repeat, shuffle: p.shuffle, stopAfter: p.stopAfter, upcoming: p.queue.slice(p.queueIndex + 1, p.queueIndex + 6).map(function(m) { return m.title; }), grid: shell.videoLibrary.grid, selected: shell.tab === "audio" ? shell.audioLibrary.selectionCount : shell.videoLibrary.selectionCount, shown: shell.tab === "audio" ? shell.audioLibrary.shownTitles() : shell.tab === "browse" ? shell.browser.shownTitles() : shell.tab === "playlists" ? shell.playlistsPage.shownTitles() : shell.tab === "more" ? (shell.moreView === "search" ? shell.searchPage.shownTitles() : shell.moreView === "history" ? shell.historyPage.shownTitles() : shell.streamsPage.shownTitles()) : shell.videoLibrary.shownTitles(), playlist: shell.playlistsPage.current ? shell.playlistsPage.current.name : "", picking: shell.playlistPicker.open ? shell.playlistPicker.items.length : 0, streams: p.streamsAllowed, keepHistory: p.keepHistory, prefs: shell.prefs.summary(), tips: shell.page === "audio" && shell.audioPage ? shell.audioPage.tipsState() : shell.videoPage.tipsState(), sharing: shell.sharing, exempt: shell.backgroundRunning ? shell.backgroundRunning.exempt : null, win: shell.appWindow ? [shell.appWindow.visibility, shell.appWindow.active, shell.appWindow.visible] : null, gate: shell.streamGate.open ? shell.streamGate.address : "", more: shell.moreView, hasVideo: p.player.hasVideo, browsing: shell.browser.path, keyboard: shell.keyboardHeight, url: p.url, artist: p.artist, art: p.art, mini: shell.audioActive, playing: p.playing, position: p.position,
            raw: p.player.position, duration: p.duration, audioMode: p.audioMode,
            hasPicture: p.hasPicture, seekable: p.seekable, status: p.player.status,
            error: p.error, starting: p.starting, ab: [p.abStart, p.abEnd], asking: p.asking ? p.askingFrom : null,
            sleep: shell.sleepTimer.remaining,
            angle: v ? v.contentAngle : null, window: shell.width + "x" + shell.height,
            sensor: v ? v.Screen.orientation : null, app: Qt.application.state, wall: Date.now()
        }));
    }

    // Lays the app out as if its window were turned on its side: the shell
    // is given the window's height as its width and turned a quarter. For
    // looking at the landscape layout without turning the phone, which adb
    // cannot do. `shot` then photographs it the right way up.
    function landscape(on) {
        var holder = shell.parent;
        var win = holder.parent;
        if (on) {
            holder.anchors.fill = undefined;
            holder.width = win.height;
            holder.height = win.width;
            holder.x = (win.width - win.height) / 2;
            holder.y = (win.height - win.width) / 2;
            holder.rotation = 90;
        } else {
            holder.rotation = 0;
            holder.anchors.fill = win;
        }
        console.log("REMOTE landscape " + holder.width + "x" + holder.height);
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
