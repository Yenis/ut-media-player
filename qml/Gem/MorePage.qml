import QtQuick 2.12
import Gem 1.0
import "../js/AppInfo.js" as AppInfo

/*
 * The More tab. In VLC it holds streams, history, settings and about; those
 * come with Phase 4, and an entry appears here when it exists.
 */
Item {
    id: page

    signal diagnosticsRequested()

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    PageHeader {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        title: "More"
        canGoBack: false
    }

    Flickable {
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
        contentHeight: content.height
        clip: true

        Column {
            id: content
            width: parent.width

            SectionLabel { text: "About" }
            SettingRow {
                title: "GemPlayer " + AppInfo.VERSION
                detail: "A media player modelled on VLC for Android. Free software, GPL-3.0 or later."
            }

            // Leaves with the spike, before 0.1.0.
            SectionLabel { text: "Development" }
            SettingRow {
                title: "Diagnostics"
                detail: "The checks that found out what the platform offers."
                trailing: Glyph {
                    width: Theme.u(2.2)
                    name: "forward"
                    color: Theme.textDim
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: page.diagnosticsRequested()
                }
            }
        }
    }
}
