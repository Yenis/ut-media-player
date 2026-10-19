import QtQuick 2.12
import Gem 1.0
import "../js/Format.js" as Format

/*
 * VLC's question before a video resumes, when "Resume played videos" is set
 * to "Ask" (VLC's `dialog_video_resume.xml`): the video's title, where it
 * was left, "From the start" and "Resume". With more of the queue to come,
 * a switch makes the answer hold for the rest of it, VLC's "Apply for all
 * the play queue".
 *
 * Nothing is loaded while it asks. It cannot be tapped away, as in VLC;
 * back closes the player. The video player puts it on its turned stage.
 */
Item {
    id: question

    property var playback: null         // Playback, which asks and is answered

    readonly property bool open: playback ? playback.asking : false
    property bool _forQueue: false

    visible: open
    onOpenChanged: _forQueue = false

    function answer(resume) {
        if (playback)
            playback.answerResume(resume, _forQueue && _queueFollows);
    }

    readonly property bool _queueFollows: playback ? playback.queueIndex < playback.queue.length - 1 : false

    // Whatever was on screen before stays out of sight.
    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Nothing behind it takes a touch.
    MouseArea { anchors.fill: parent }

    Rectangle {
        width: Math.min(parent.width - Theme.u(4), Theme.u(44))
        height: column.height + Theme.u(4)
        anchors.centerIn: parent
        radius: Theme.u(1.6)
        color: Theme.surface
        border.width: 1
        border.color: Theme.line

        Column {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.u(2) }
            spacing: Theme.u(1.6)

            Text {
                width: parent.width
                text: question.playback ? question.playback.title : ""
                color: Theme.text
                font.pixelSize: Theme.fontL
                font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: "Resume from " + Format.clock(question.playback ? question.playback.askingFrom : 0) + "?"
                color: Theme.text
                font.pixelSize: Theme.fontM
                wrapMode: Text.WordWrap
            }

            Item {
                visible: question._queueFollows
                width: parent.width
                height: Math.max(queueLabel.height, queueSwitch.height)

                Text {
                    id: queueLabel
                    anchors { left: parent.left; right: queueSwitch.left; rightMargin: Theme.u(1.5); verticalCenter: parent.verticalCenter }
                    text: "The same for the rest of the queue"
                    color: Theme.textDim
                    font.pixelSize: Theme.fontS
                    wrapMode: Text.WordWrap
                }
                Toggle {
                    id: queueSwitch
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    checked: question._forQueue
                    onToggled: question._forQueue = checked
                }
            }

            Row {
                anchors.right: parent.right
                spacing: Theme.u(1.5)

                TextButton {
                    text: "From the start"
                    tone: Theme.textDim
                    onClicked: question.answer(false)
                }
                TextButton {
                    text: "Resume"
                    onClicked: question.answer(true)
                }
            }
        }
    }
}
