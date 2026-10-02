import QtQuick 2.12
import Lomiri.Content 1.3

/*
 * Files that other apps hand over ("Open with"). Content Hub puts each one in
 * ~/.cache/gemplayer.yenis/HubIncoming/ as a hard link to the original.
 * Loaded by URL, since Lomiri.Content only exists on the device.
 */
Item {
    signal incoming(string url)

    Connections {
        target: ContentHub
        onImportRequested: {
            if (transfer.state !== ContentTransfer.Charged)
                return;
            // One file is played; a queue of several comes with Phase 2.
            if (transfer.items.length > 0)
                incoming(transfer.items[0].url.toString());
        }
    }
}
