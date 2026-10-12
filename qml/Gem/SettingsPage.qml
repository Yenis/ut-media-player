import QtQuick 2.12
import Gem 1.0

/*
 * Settings, behind the More tab, in VLC's grouping as far as there is
 * something to set (docs/VLC-FEATURES.md, "Settings"): video, gestures,
 * subtitles, audio, history, and under "Advanced" what clears stored data.
 *
 * The values are in Prefs.qml; this page shows them and asks for changes.
 * The two switches that live with the player, the playback history and the
 * streams, are shown here too and changed through the shell.
 */
Item {
    id: page

    property var prefs: null            // Prefs
    property var store: null            // PlayerStore: what "Advanced" clears
    property var overlay: page          // what the sheets cover; the shell passes all of "home"
    property var background: null       // platform/BackgroundRunning.qml, or null off the device
    property bool keepingHistory: true
    property bool streamsAllowed: false

    property string _clearing: ""       // what the question is about

    signal closeRequested()
    signal keepHistoryRequested(bool on)
    signal streamsRequested()

    readonly property var clearings: ({
        history: { title: "Clear the playback history?", label: "Clear history" },
        streams: { title: "Clear the stream history?", label: "Clear stream history" },
        progress: { title: "Forget all progress and played marks?", label: "Forget progress" }
    })

    function askClear(what) {
        if (!clearings[what])
            return;
        _clearing = what;
        clearSheet.show();
    }

    function clear(what) {
        if (what === "history")
            store.clearHistory();
        else if (what === "streams")
            store.clearStreams();
        else if (what === "progress")
            store.clearProgress();
    }

    function closeSheets() {
        clearSheet.close();
    }

    // For the development remote: how far down the page is shown.
    function scrollTo(y) {
        flick.contentY = Math.max(0, Math.min(y, flick.contentHeight - flick.height));
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    // Nothing behind the page takes a touch.
    MouseArea { anchors.fill: parent }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "Settings"
        onBack: page.closeRequested()
    }

    Flickable {
        id: flick
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
        contentHeight: content.height + Theme.u(3)
        clip: true

        Column {
            id: content
            width: parent.width

            // ---- video ------------------------------------------------------------------

            SectionLabel { text: "Video" }
            SettingRow {
                title: "Resume where a video was left"
                detail: page.prefs && page.prefs.resumeVideos ? "A video carries on from where it was stopped."
                                                              : "Every video starts from its beginning."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.resumeVideos : true
                    onToggled: page.prefs.set("resumeVideos", checked)
                }
            }
            SettingRow {
                title: "Play on as audio when the app is left"
                detail: page.prefs && page.prefs.videoPlaysOnAsAudio
                        ? "A video that is playing carries on without its picture, under other apps and with the screen off."
                        : "A video is paused when the app is left or the screen goes off."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.videoPlaysOnAsAudio : false
                    onToggled: page.prefs.set("videoPlaysOnAsAudio", checked)
                }
            }

            // ---- gestures ---------------------------------------------------------------

            SectionLabel { text: "Gestures in the players" }
            SettingRow {
                title: "Volume"
                detail: "Swipe up and down on the right half."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.gestureVolume : true
                    onToggled: page.prefs.set("gestureVolume", checked)
                }
            }
            SettingRow {
                title: "Brightness"
                detail: "Swipe up and down on the left half."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.gestureBrightness : true
                    onToggled: page.prefs.set("gestureBrightness", checked)
                }
            }
            SettingRow {
                title: "Swipe to seek"
                detail: "Swipe sideways to move through what plays."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.gestureSwipeSeek : true
                    onToggled: page.prefs.set("gestureSwipeSeek", checked)
                }
            }
            SettingRow {
                title: "Double tap to seek"
                detail: "Double tap on the left or right to skip back or forward. A double tap in the middle still pauses."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.gestureDoubleTap : true
                    onToggled: page.prefs.set("gestureDoubleTap", checked)
                }
            }
            SettingRow {
                title: "Pinch to fill the screen"
                detail: "In the video player."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.gesturePinch : true
                    onToggled: page.prefs.set("gesturePinch", checked)
                }
            }
            SettingRow {
                title: "Skip length"
                detail: "How far a double tap, the rewind and forward buttons and the arrow keys go."
                below: SegmentedChoice {
                    width: parent.width
                    options: page.prefs ? page.prefs.skipChoices.map(function(s) { return s + " s"; }) : []
                    currentIndex: page.prefs ? page.prefs.skipChoices.indexOf(page.prefs.skipSeconds) : 0
                    onChosen: page.prefs.set("skipSeconds", page.prefs.skipChoices[index])
                }
            }

            // ---- subtitles --------------------------------------------------------------

            SectionLabel { text: "Subtitles" }
            SettingRow {
                title: "Size"
                below: SegmentedChoice {
                    width: parent.width
                    options: page.prefs ? page.prefs.subtitleScaleNames : []
                    currentIndex: page.prefs ? page.prefs.subtitleScales.indexOf(page.prefs.subtitleScale) : 0
                    onChosen: page.prefs.set("subtitleScale", page.prefs.subtitleScales[index])
                }
            }
            SettingRow {
                title: "Colour"
                below: SegmentedChoice {
                    width: parent.width
                    options: page.prefs ? page.prefs.subtitleColourNames : []
                    currentIndex: page.prefs ? page.prefs.subtitleColours.indexOf(page.prefs.subtitleColour) : 0
                    onChosen: page.prefs.set("subtitleColour", page.prefs.subtitleColours[index])
                }
            }
            SettingRow {
                title: "Dark background"
                detail: "A dark box behind the text, for bright pictures."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.subtitleBackground : false
                    onToggled: page.prefs.set("subtitleBackground", checked)
                }
            }
            // How it will look.
            Item {
                width: parent.width
                height: Theme.u(9)

                Rectangle {
                    anchors { fill: parent; leftMargin: Theme.u(2); rightMargin: Theme.u(2); topMargin: Theme.u(1); bottomMargin: Theme.u(1) }
                    radius: Theme.u(0.9)
                    color: "#3A5A78"

                    Rectangle {
                        visible: page.prefs ? page.prefs.subtitleBackground : false
                        anchors.centerIn: sample
                        width: sample.contentWidth + Theme.u(1.6)
                        height: sample.contentHeight + Theme.u(0.6)
                        radius: Theme.u(0.4)
                        color: Qt.rgba(0, 0, 0, 0.65)
                    }
                    Text {
                        id: sample
                        anchors.centerIn: parent
                        text: "A line of subtitles"
                        color: page.prefs ? page.prefs.subtitleColour : "white"
                        style: Text.Outline
                        styleColor: "black"
                        font.pixelSize: Theme.fontM * (page.prefs ? page.prefs.subtitleScale : 1)
                    }
                }
            }

            // ---- audio ------------------------------------------------------------------

            SectionLabel { text: "Audio" }
            SettingRow {
                title: "Bring back the queue at the start"
                detail: page.prefs && page.prefs.restoreQueue
                        ? "What played as audio is there again when the app is opened, paused."
                        : "The app starts with nothing in the mini-player."
                trailing: Toggle {
                    checked: page.prefs ? page.prefs.restoreQueue : true
                    onToggled: page.prefs.set("restoreQueue", checked)
                }
            }

            // ---- history and network ----------------------------------------------------

            SectionLabel { text: "History" }
            SettingRow {
                title: "Keep a playback history"
                detail: page.keepingHistory ? "What you play is listed under More, History."
                                            : "Nothing new is listed."
                trailing: Toggle {
                    checked: page.keepingHistory
                    onToggled: page.keepHistoryRequested(checked)
                }
            }
            SettingRow {
                title: "Streams"
                detail: page.streamsAllowed ? "Allowed. The switch is under More, Streams."
                                            : "Off. GemPlayer is offline. The switch is under More, Streams."
                trailing: Glyph {
                    width: Theme.u(2.2)
                    name: "forward"
                    color: Theme.textDim
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: page.streamsRequested()
                }
            }

            // ---- advanced ---------------------------------------------------------------

            SectionLabel { text: "Advanced" }
            SettingRow {
                // Only where the system has such a list.
                visible: page.background !== null
                title: "Keep running in the background"
                detail: page.background && page.background.exempt
                        ? "On. The app is not frozen when it is left, so the sleep timer and A-B repeat also work with the screen off and under other apps. It uses more battery. GemPlayer is on the system's list of apps that are not frozen; switching this off takes it out again."
                        : "Off. The system freezes the app a few seconds after it is left. Music plays on, but the sleep timer and A-B repeat wait until the app is opened again. Switching this on adds GemPlayer to the system's list of apps that are not frozen."
                trailing: Toggle {
                    checked: page.background ? page.background.exempt : false
                    onToggled: page.background.setExempt(checked)
                }
            }
            SettingRow {
                title: "Clear the playback history"
                detail: "The list under More, History."

                MouseArea {
                    anchors.fill: parent
                    onClicked: page.askClear("history")
                }
            }
            SettingRow {
                title: "Clear the stream history"
                detail: "The addresses under More, Streams."

                MouseArea {
                    anchors.fill: parent
                    onClicked: page.askClear("streams")
                }
            }
            SettingRow {
                title: "Forget progress"
                detail: "Where each video was left, and the marks on those played to the end. Bookmarks, favourites, groups and playlists stay."

                MouseArea {
                    anchors.fill: parent
                    onClicked: page.askClear("progress")
                }
            }
        }
    }

    OptionSheet {
        id: clearSheet
        parent: page.overlay
        anchors.fill: parent
        title: page.clearings[page._clearing] ? page.clearings[page._clearing].title : ""
        options: [
            { key: "clear", label: page.clearings[page._clearing] ? page.clearings[page._clearing].label : "", glyph: "clear" },
            { key: "keep", label: "Cancel", glyph: "back" }
        ]
        onChosen: if (key === "clear") page.clear(page._clearing)
    }
}
