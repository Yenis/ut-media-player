import QtQuick 2.12
import Lomiri.Content 1.3

/*
 * What other apps hand over: files through "Open with", and files or links
 * through "Share". Content Hub puts a file in
 * ~/.cache/gemplayer.yenis/HubIncoming/ as a hard link to the original; a
 * link arrives as its address. The two ways in are two signals of the hub,
 * taken alike here. Loaded by URL, since Lomiri.Content only exists on the
 * device.
 */
Item {
    // The addresses handed over, in the order given.
    signal incoming(var urls)

    function _take(transfer) {
        if (transfer.state !== ContentTransfer.Charged)
            return;
        var urls = [];
        for (var i = 0; i < transfer.items.length; i++) {
            var item = transfer.items[i];
            var address = item.url ? item.url.toString() : "";
            // A link can come as text instead of an address.
            if (!address && item.text)
                address = item.text.toString().trim();
            if (address)
                urls.push(address);
        }
        if (urls.length > 0)
            incoming(urls);
    }

    Connections {
        target: ContentHub
        onImportRequested: _take(transfer)
        onShareRequested: _take(transfer)
    }
}
