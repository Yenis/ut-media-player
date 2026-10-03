# Developing GemPlayer

How to build, run and check the app, and what the platform taught us the hard
way. Read this before changing the player; read [PLAN.md](PLAN.md) for what to
build next.

## Contents

- [Layout](#layout)
- [Build and run](#build-and-run)
- [Driving the app from the computer](#driving-the-app-from-the-computer)
- [Test media](#test-media)
- [Rules the backend imposes](#rules-the-backend-imposes)
- [Reaching the system from QML](#reaching-the-system-from-qml)
- [Reference sources](#reference-sources)

## Layout

| Path | What is there |
|---|---|
| `qml/Main.qml` | Bootstrap: app identity, grid unit, then the shell |
| `qml/Gem/` | The app: shell, pages, components, the `Theme` singleton |
| `qml/js/` | Plain logic with no QML in it: gesture arithmetic, subtitle parsing, formatting |
| `qml/platform/` | Everything that exists only on Ubuntu Touch, each file loaded by URL through a `Loader` so the rest starts without it |
| `qml/dev/`, `qml/spike/` | Development remote and the Phase 0 diagnostics page. Both leave before 0.1.0 |
| `tools/` | Scripts for the phone: `dev.sh`, `make-test-media.sh` |
| `docs/` | Plan, feature survey, test records, store notes |
| `vlc-android/` | Reference clone of VLC for Android. Ignored by git, read only |

The click is QML-only and unconfined (decisions D7 and D12 in
[PLAN.md](PLAN.md)).

## Build and run

Needs [Clickable](https://clickable-ut.dev) 8.9 or newer, `adb`, and a phone
with Developer Mode on.

```bash
tools/dev.sh deploy     # build, install, restart the app on the phone
tools/dev.sh log 30     # the app's last 30 seconds of log
```

`clickable build` ends with one `click-review` finding, `'unconfined' not
allowed`. That is expected; see [STORE.md](STORE.md).

Two things `clickable` does not do for you, which `tools/dev.sh` does:

- After an install the old process keeps running the old QML. It has to be
  stopped; the script finds it by its working directory.
- `lomiri-app-launch` hangs when called over adb. The script starts the app
  through the URL dispatcher instead.

The version number lives in three places that must agree: `manifest.json`,
`CMakeLists.txt` and `qml/js/AppInfo.js`.

## Driving the app from the computer

`qml/dev/Remote.qml` lets the app be steered and photographed over adb, so a
change can be checked on the phone without touching it. It is off unless the
file `~/.cache/gemplayer.yenis/dev-remote.txt` exists when the app starts;
`tools/dev.sh restart` creates it.

```bash
tools/dev.sh cmd open /home/phablet/Videos/gemplayer-test/sidecar.mp4
tools/dev.sh cmd angle 270          # turn the player on its side
tools/dev.sh cmd sheet menu
tools/dev.sh shot menu              # build/shots/menu.png
tools/dev.sh cmd state              # then: tools/dev.sh log 5
```

| Command | Does |
|---|---|
| `open <path>` | Opens a file in the player |
| `play`, `pause`, `seek <ms>`, `seekby <ms>` | Playback |
| `audio`, `video`, `back`, `home`, `diagnostics` | Pages |
| `tab <video\|audio\|browse\|playlists\|more>` | Shows a tab |
| `view <grid\|list>` | How the Video tab shows its videos |
| `sort <name\|filename\|length\|modified> [desc]`, `favonly <0\|1>`, `filter <text>` | Order and narrowing of the Video tab |
| `fav <path>` | Switches a video's favourite mark |
| `focusfilter`, `hidekeyboard` | Opens the filter with the keyboard, and puts the keyboard away. `state` reports the keyboard's height |
| `display`, `itemmenu <index>`, `closesheets` | The Video tab's display settings, the menu of the video at that place in the list, and closing both |
| `controls <0\|1>`, `lock <0\|1>`, `aspect <index>` | Player state |
| `angle <0\|90\|270>`, `follow` | Force the content's rotation, or follow the sensor again |
| `sheet <menu\|aspects\|subtitles\|bookmarks\|info\|jump\|sleep>` | Opens a sheet |
| `volume <delta>`, `brightness <delta>`, `subdelay <ms>` | What the swipes and keys do |
| `bookmark`, `ab`, `screenshot`, `sleep <ms>`, `tapseek <back\|forward>` | Menu actions |
| `info <text>`, `level <volume\|brightness>` | Shows an overlay for five seconds |
| `shot <name>` | The app saves a picture of its own window |
| `state` | Logs a line `REMOTE STATE {...}` with position, page, errors |

What it cannot do: touch gestures, the orientation sensor, the power button.
Those are checked by hand; [TESTING.md](TESTING.md) lists them.

To see what the system thinks is playing while the app is frozen, ask
media-hub directly:

```bash
adb shell 'export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus;
  gdbus call --session --dest org.mpris.MediaPlayer2.MediaHub \
  --object-path /org/mpris/MediaPlayer2 --method org.freedesktop.DBus.Properties.Get \
  org.mpris.MediaPlayer2.Player PlaybackStatus'
```

## Test media

```bash
tools/make-test-media.sh push
```

generates the synthetic test set (about 200 MB, into `build/test-media/`) and
copies it to `~/Videos/gemplayer-test` and `~/Music/gemplayer-test` on the
phone. [TESTING.md](TESTING.md) says what each file is for.

## Rules the backend imposes

Playback goes through QtMultimedia to media-hub, a system service. All of
these were found on the device; the evidence is in [TESTING.md](TESTING.md).

| Rule | Why |
|---|---|
| One `MediaPlayer` for the whole app (`qml/Gem/Playback.qml`) | A second one fails to start, or starts by itself |
| The `VideoOutput` exists before a file is opened, and is never destroyed, only hidden | A video will not start without somewhere to put its picture |
| Never `stop()`; pause instead | After `stop()`, `play()` on the same source does nothing |
| Do not clear `source` | It raises an error |
| Do not bind to `seekable`, and do not read `duration` inside a binding | The first changes without a signal; the second emits when read, which looks like a binding loop |
| Treat a negative `position` as zero | It is a large negative number while nothing is loaded |
| Expect a seek to land early and late | It goes to the keyframe before the target and takes 0.4 to 1.5 s; a seek before playback has started is ignored |
| Do not trust `hasAudio`, `metaData` or `volume` | Wrong, empty, and ignored |
| Set your own time limit when opening a stream | A dead address raises no error |
| Pause a video yourself when the app is suspended | media-hub plays on behind the lock screen and other apps |
| Nothing in the app runs while it is in the background | The app is frozen a few seconds after it leaves the foreground; playback continues without it |

## Reaching the system from QML

| Need | How | File |
|---|---|---|
| Media library, thumbnails | `MediaScanner 0.1`, `Lomiri.Thumbnailer 0.1` | `qml/platform/MediaLibrary.qml` |
| Files from other apps | `Lomiri.Content 1.3` | `qml/platform/ContentImport.qml` |
| System volume, screen brightness | The sound and power indicators publish their sliders as actions on the session bus; `QMenuModel 1.0`'s `QDBusActionGroup` reads and sets them | `qml/platform/SystemVolume.qml`, `SystemBrightness.qml` |
| User folders | `Qt.labs.platform` `StandardPaths` | `qml/platform/Folders.qml` |
| Listing a folder | `Qt.labs.folderlistmodel` | `qml/Gem/SubtitleTrack.qml` |
| On-screen keyboard height | `Qt.inputMethod`, as GemTicker does; a plain Window does not make room for the keyboard itself | `qml/Gem/AppShell.qml` |
| Reading a text file | `XMLHttpRequest` on a `file://` address. Qt warns that this will be off by default one day | `qml/Gem/SubtitleTrack.qml` |

QML cannot delete or rename a file, call an arbitrary D-Bus method, or open a
socket. Anything needing those needs compiled code, which the package does not
have (D7).

## Reference sources

Behaviour is taken from VLC for Android, and platform facts from the UBports
sources. None of them is in this repository.

| Source | Where | Used for |
|---|---|---|
| VLC for Android | `vlc-android/` here, from `https://github.com/videolan/vlc-android` | How every feature behaves; [VLC-FEATURES.md](VLC-FEATURES.md) names the file for each |
| media-hub | `https://gitlab.com/ubports/development/core/media-hub` | Who may play what (`src/service/apparmor/lomiri.cpp`), power locks, MPRIS |
| qtubuntu-media | `https://gitlab.com/ubports/development/core/qtubuntu-media` | What the QtMultimedia backend really implements |
| mediascanner2 | `https://gitlab.com/ubports/development/core/mediascanner2` | The library's QML types and its access check |
| lomiri-content-hub | `https://gitlab.com/ubports/development/core/lomiri-content-hub` | How files are handed over |
| Stock Music and Media Player apps | `.../apps/lomiri-music-app`, `.../core/lomiri-mediaplayer-app` | How the platform's own apps use all of the above |
