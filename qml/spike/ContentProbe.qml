import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Content 1.3

/* Spike: files handed over by other apps, as the stock Media Player takes them. */
Item {
    signal incoming(string how, string url)

    Connections {
        target: ContentHub
        onImportRequested: {
            if (transfer.state !== ContentTransfer.Charged)
                return;
            for (var i = 0; i < transfer.items.length; i++)
                incoming("content-hub", transfer.items[i].url.toString());
        }
    }

    Connections {
        target: UriHandler
        onOpened: {
            for (var i = 0; i < uris.length; i++)
                incoming("url", uris[i]);
        }
    }
}
