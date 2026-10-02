import QtQuick 2.12
import MediaScanner 0.1
import Lomiri.Thumbnailer 0.1

/*
 * Spike: the system media library, as the stock Music app reads it.
 * Importing Lomiri.Thumbnailer registers the image://thumbnailer/ and
 * image://albumart/ providers.
 */
Item {
    readonly property bool ready: songs.status === SongsModel.Ready

    MediaStore { id: store }
    SongsModel { id: songs; store: store }
    AlbumsModel { id: albums; store: store }
    ArtistsModel { id: artists; store: store }
    GenresModel { id: genres; store: store }

    function counts() {
        return { songs: songs.rowCount, albums: albums.rowCount,
                 artists: artists.rowCount, genres: genres.rowCount };
    }

    function plain(file) {
        return { filename: file.filename, title: file.title, author: file.author,
                 album: file.album, duration: file.duration, width: file.width,
                 height: file.height, art: file.art, contentType: file.contentType };
    }

    function videos(text) {
        var found = store.query(text, MediaStore.VideoMedia);
        var out = [];
        for (var i = 0; i < found.length; i++)
            out.push(plain(found[i]));
        return out;
    }

    function firstSongs(n) {
        var out = [];
        for (var i = 0; i < Math.min(n, songs.rowCount); i++)
            out.push(plain(songs.get(i, SongsModel.RoleModelData)));
        return out;
    }

    function firstAlbum() {
        if (albums.rowCount === 0)
            return null;
        return { title: albums.get(0, AlbumsModel.RoleTitle),
                 artist: albums.get(0, AlbumsModel.RoleArtist),
                 art: albums.get(0, AlbumsModel.RoleArt) };
    }
}
