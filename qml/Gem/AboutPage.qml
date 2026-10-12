import QtQuick 2.12
import Gem 1.0
import "../js/AppInfo.js" as AppInfo

/*
 * About, behind the More tab: what the app is, its version and licence,
 * where it comes from, and what it does with the network. The credit to VLC
 * for Android is owed (docs/PLAN.md, D5). The addresses are text, not
 * links: the app opens nothing by itself (D13).
 */
Item {
    id: page

    signal closeRequested()

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    // Nothing behind the page takes a touch.
    MouseArea { anchors.fill: parent }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "About"
        onBack: page.closeRequested()
    }

    Flickable {
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
        contentHeight: content.height + Theme.u(3)
        clip: true

        Column {
            id: content
            width: parent.width

            Item {
                width: parent.width
                height: Theme.u(22)

                Image {
                    id: icon
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.u(3) }
                    width: Theme.u(11)
                    height: width
                    source: "../../assets/icon.png"
                    sourceSize: Qt.size(256, 256)
                }
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: icon.bottom; topMargin: Theme.u(1.5) }
                    text: "GemPlayer"
                    color: Theme.text
                    font.pixelSize: Theme.fontXL
                    font.bold: true
                }
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                    text: "Version " + AppInfo.VERSION
                    color: Theme.textDim
                    font.pixelSize: Theme.fontS
                }
            }

            SettingRow {
                title: "A media player for Ubuntu Touch"
                detail: "Plays the videos and music on the phone, and streams once you allow them, with the system's own media player."
            }
            SettingRow {
                title: "Modelled on VLC for Android"
                detail: "GemPlayer follows the behaviour and layout of VLC for Android by VideoLAN and the VLC authors. It is not VLC, is not affiliated with VideoLAN, and does not contain libVLC."
            }
            SettingRow {
                title: "Licence"
                detail: "Free software under the GNU General Public License, version 3 or later. It comes with no warranty."
            }
            SettingRow {
                title: "Source"
                detail: "github.com/Yenis/ut-media-player"
            }
            SettingRow {
                title: "Privacy"
                detail: "No accounts and no tracking. Nothing goes over the network except a stream you open, and streams are off until you allow them. What the app remembers stays on the phone."
            }
        }
    }
}
