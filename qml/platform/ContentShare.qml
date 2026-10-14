import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Content 1.3

/*
 * "Share": hands files to another app through Content Hub, with the
 * system's own list of the apps that take them. The other app gets a copy;
 * nothing goes anywhere else. Loaded by URL, and only when first asked for,
 * since Lomiri.Content and Lomiri.Components only exist on the device.
 */
Item {
    id: share

    property var urls: []
    property bool open: false

    signal closed()

    visible: open

    // `urls` are file addresses; `videos` says which kind they are, for the
    // apps the system offers.
    function ask(fileUrls, videos) {
        urls = fileUrls;
        picker.contentType = videos ? ContentType.Videos : ContentType.Music;
        open = true;
    }

    function close() {
        open = false;
        closed();
    }

    Rectangle {
        anchors.fill: parent
        color: "#07070C"
    }

    // Swallows touches meant for what is behind.
    MouseArea { anchors.fill: parent }

    ContentPeerPicker {
        id: picker
        anchors.fill: parent
        visible: share.open
        showTitle: true
        handler: ContentHandler.Share
        contentType: ContentType.Videos

        onPeerSelected: {
            var transfer = peer.request();
            var items = [];
            for (var i = 0; i < share.urls.length; i++)
                items.push(itemMaker.createObject(share, { url: share.urls[i] }));
            transfer.items = items;
            transfer.state = ContentTransfer.Charged;
            share.close();
        }
        onCancelPressed: share.close()
    }

    Component {
        id: itemMaker
        ContentItem {}
    }
}
