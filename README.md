# GemPlayer

A media player for Ubuntu Touch, modelled on VLC for Android: its gestures, its
player menu, its library and its queue, built in QML on the media stack Ubuntu
Touch already ships.

**Status: early development.** Version 0.0.19 plays the videos on the phone
with VLC's gestures, resume, "play as audio", external subtitles, bookmarks,
A-B repeat and a sleep timer, and has the five tabs of the finished app, with
the videos in a grid or a list that can be sorted, filtered, grouped and
played one after another. It lists the music on the phone by artist, album,
track, genre and file, and plays it in an audio player with a mini-player
that stays above the tabs and a queue that plays on in the background,
with shuffle and repeat. Folder browsing, playlists and settings are still
to come. The plan and its progress are in
[docs/PLAN.md](docs/PLAN.md).

Test builds are published on the
[Releases page](https://github.com/Yenis/ut-media-player/releases);
[docs/INSTALL.md](docs/INSTALL.md) says how to put one on a phone.

GemPlayer is not VLC and is not affiliated with VideoLAN. It does not contain
libVLC. See [Credits](#credits).

## Contents

- [What it will do](#what-it-will-do)
- [Privacy](#privacy)
- [Building](#building)
- [Documents](#documents)
- [Credits](#credits)
- [License](#license)

## What it will do

The goal is every feature of VLC for Android that Ubuntu Touch can support.
[docs/VLC-FEATURES.md](docs/VLC-FEATURES.md) lists them all, with the state of
each. The core:

- Video player with VLC's gestures: swipe to seek, double-tap to skip, swipe
  for volume and brightness, pinch to fit.
- **Play as audio**: carry on listening to a video with the screen off.
- Resume where you left off, bookmarks, A-B repeat, sleep timer.
- External subtitles.
- Video and audio library, playlists, favourites, history.
- Play queue with shuffle and repeat.

## Privacy

GemPlayer has no accounts and no tracking, and it does nothing over the
network except play a stream whose address you give it. That address goes to
the system's player, which fetches the stream; the app itself opens no
connection. It has no network shares, no casting, no remote control, and
looks nothing up online.

The app runs unconfined, outside Ubuntu Touch's sandbox, because the system
does not let a sandboxed third-party player open your music and videos. It
reads media files and writes only its own settings.

## Building

You need [Clickable](https://clickable-ut.dev) 8.9 or newer and a phone with
Developer Mode on.

```bash
clickable build      # produce the .click and run click-review on it
clickable install    # copy it to the connected phone and install it
clickable launch
clickable logs       # follow the app's log output
```

`tools/dev.sh deploy` does the first three in one go and restarts the app;
[docs/DEVELOPING.md](docs/DEVELOPING.md) explains why that is needed.

The click is QML-only: `qmlscene` runs `qml/Main.qml`, there is no compiled
code, and one package serves every architecture.

`click-review` reports one finding on this build, which is expected: the app
is unconfined, and that needs a manual review in the OpenStore.
[docs/STORE.md](docs/STORE.md) explains why: on Ubuntu Touch today, a confined
third-party app is not allowed to play files from `~/Music` or `~/Videos`.

The `vlc-android/` folder, if you have one, is a reference copy of VLC's
source. It is ignored by git and never enters the package.

## Documents

| File | What it is |
|---|---|
| [docs/PLAN.md](docs/PLAN.md) | Decisions, phases, and what is done |
| [docs/VLC-FEATURES.md](docs/VLC-FEATURES.md) | What VLC for Android does, and the state of each feature here |
| [docs/DEVELOPING.md](docs/DEVELOPING.md) | Build loop, checking changes on the phone, platform rules |
| [docs/TESTING.md](docs/TESTING.md) | Device checks and their results |
| [docs/INSTALL.md](docs/INSTALL.md) | Installing a build on your phone |
| [docs/STORE.md](docs/STORE.md) | Notes for the OpenStore submission |
| [CHANGELOG.md](CHANGELOG.md) | What changed in each version |

## Credits

GemPlayer follows the behaviour and layout of
[VLC for Android](https://code.videolan.org/videolan/vlc-android) by VideoLAN
and the VLC authors, which is licensed under the GNU General Public License,
version 2 or later. Text or artwork adapted from it is marked as such in the
file that carries it. "VLC" and the cone logo are trademarks of VideoLAN and
are not used by this app.

The theme and several interface components come from
[GemTicker](https://github.com/Yenis/gemticker).

## License

GemPlayer is free software, licensed under the
**[GNU General Public License v3.0 or later](LICENSE)**.
