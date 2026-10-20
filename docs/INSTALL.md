# Installing GemPlayer on Ubuntu Touch

GemPlayer is not in the OpenStore. You install it yourself, which takes about
five minutes. There are two routes:

- **[Route A: install a ready-made package](#route-a-install-a-ready-made-package)** -
  copy one file to the phone. Nothing to build.
- **[Route B: build it yourself](#route-b-build-it-yourself)** - from source,
  if you would rather compile what you run, or want to change it.

Both end with the same app. If anything goes wrong, see
[Troubleshooting](#troubleshooting).

---

## What you need

| | |
|---|---|
| A phone running **Ubuntu Touch 20.04 or 24.04** | Any device, any architecture: GemPlayer contains no compiled code, so one package fits all of them. Tried on a Pixel 3a with 24.04-1.x; 20.04 and tablets not yet |
| **About 5 MB free space** | The package is about 330 KB; the app's database, settings and Qt's compiled-QML cache stay small |
| Your videos and music **on the phone** | In `Videos` and `Music`, or on a card, where the system's media library finds them. Files elsewhere are reached through the Browse tab |

For Route A you also need a computer with `adb`, unless you use the
[on-phone method](#a2-without-a-computer).

GemPlayer needs no network: it is offline until you allow streams. It has no
accounts and no tracking. It runs **unconfined**, outside Ubuntu Touch's
sandbox, because the system does not let a sandboxed third-party player open
the files in Music and Videos; the [README](../README.md#privacy) says what
that means and what the app writes.

---

## Route A: install a ready-made package

### A1. With a computer (recommended)

**Step 1 - get the package.**

Download `gemplayer.yenis_<version>_all.click` from the
[Releases page](https://github.com/Yenis/ut-media-player/releases). The file
name ends in `_all.click`, meaning it works on every device.

**Step 2 - check the download (optional but quick).**

```bash
sha256sum gemplayer.yenis_0.1.0_all.click
```

The line printed should match the SHA-256 in that release's notes.

**Step 3 - turn on Developer Mode on the phone.**

1. Open **Settings → About → Developer Mode**.
2. If the switch is greyed out, set a **passcode or PIN first**, under
   **Settings → Security & Privacy → Lock security**. Ubuntu Touch refuses
   Developer Mode without one.
3. Turn **Developer Mode** on.

> **Keep the passcode.** Removing it later switches Developer Mode off again,
> and the phone stops answering `adb`.

**Step 4 - connect the phone by USB.**

Use a cable that carries data; many charging cables do not. Unlock the phone
and leave the screen on. Then, on the computer:

```bash
adb devices
```

You want a line like:

```
986AY133SY      device
```

If you see `offline`, `unauthorized`, or nothing at all, see
[Troubleshooting](#the-phone-does-not-show-up-in-adb-devices).

**Step 5 - copy the package to the phone and install it.**

```bash
adb push gemplayer.yenis_0.1.0_all.click /home/phablet/
adb shell "gdbus call --system --dest com.lomiri.click --object-path /com/lomiri/click --method com.lomiri.click.Install /home/phablet/gemplayer.yenis_0.1.0_all.click"
```

The second command asks the system's click service to install the file, as
Clickable does; it prints `()` when it has. Older instructions use `pkcon
install-local`, which Ubuntu Touch 20.04 and later no longer have (checked on
the Pixel 3a, 7 October 2026). Then tidy up:

```bash
adb shell "rm /home/phablet/gemplayer.yenis_0.1.0_all.click"
```

**Step 6 - open it.**

GemPlayer appears in the app drawer. The Video and Audio tabs list what the
system's media library has found; the first video you play brings a short
tour of the gestures.

### A2. Without a computer

The same command works on the phone itself. Not tried this way yet.

1. Download the `.click` file in the browser; it lands in `~/Downloads`.
2. Install the **Terminal** app from the OpenStore if you do not have it.
3. In Terminal, with your file name:

```bash
gdbus call --system --dest com.lomiri.click --object-path /com/lomiri/click --method com.lomiri.click.Install ~/Downloads/gemplayer.yenis_0.1.0_all.click
```

4. Find GemPlayer in the app drawer.

---

## Route B: build it yourself

Building uses **Clickable**, which runs the whole toolchain inside Docker, so
nothing but Docker and Clickable is installed on your computer.

**Step 1 - install Docker and Clickable** (Ubuntu, Debian or Linux Mint
shown; see [clickable-ut.dev](https://clickable-ut.dev/) for other systems):

```bash
sudo apt install docker.io adb git pipx
sudo usermod -aG docker $USER
pipx ensurepath
pipx install clickable-ut
```

**Step 2 - log out and back in**, so that your user may use Docker and
`~/.local/bin` is on your path. Then check:

```bash
docker run --rm hello-world       # must work without sudo
clickable --version
```

**Step 3 - get the source and build:**

```bash
git clone https://github.com/Yenis/ut-media-player.git
cd ut-media-player
clickable build
```

The first build downloads a build image of about 6 GB. Later builds take
seconds. The finished package is printed at the end, under `build/`.

`clickable build` ends with one `click-review` finding, `'unconfined' not
allowed`, and the word `FAIL`. That is expected: an unconfined app needs a
store's manual review, and the package is built all the same. See
[STORE.md](STORE.md).

**Step 4 - install it on the phone.** With Developer Mode on (Route A, step 3)
and the phone connected:

```bash
clickable install
clickable launch
```

**Useful while developing:**

```bash
clickable logs         # watch the app's log output from the phone
clickable review       # run the same package checks a store would
tools/dev.sh deploy    # build with the development aids, install, restart
```

[DEVELOPING.md](DEVELOPING.md) has the rest.

---

## Checking it worked

Over `adb shell`, or in Terminal on the phone:

```bash
click list | grep gemplayer        # shows: gemplayer.yenis  0.1.0
```

The app keeps everything in four places:

| What | Where |
|---|---|
| Settings | `~/.config/gemplayer.yenis/` |
| Resume points, bookmarks, favourites, groups, playlists, the playback and stream histories, subtitle choices | `~/.local/share/gemplayer.yenis/` |
| Qt's compiled-QML cache | `~/.cache/gemplayer.yenis/` |
| The app itself | `/opt/click.ubuntu.com/gemplayer.yenis/` |

Your media files are never changed. Under **More → Settings → Advanced**
the playback history, the stream history and the resume points can be
cleared from inside the app.

## Updating

Install the newer package exactly as before; it replaces the old one and keeps
everything the app has stored. If the app is open, close it first, or it keeps
running the old version until you do.

## Uninstalling

If you switched on **Keep running in the background**, switch it off first:
that takes the app's name out of the system's list of apps that are not
frozen. Then:

```bash
adb shell "gdbus call --system --dest com.lomiri.click --object-path /com/lomiri/click --method com.lomiri.click.Remove gemplayer.yenis"
```

That leaves the app's data behind. To remove that too:

```bash
adb shell "rm -rf ~/.config/gemplayer.yenis ~/.cache/gemplayer.yenis ~/.local/share/gemplayer.yenis"
```

---

## Troubleshooting

### The phone does not show up in `adb devices`

Work through these in order:

| Symptom | Cause and fix |
|---|---|
| No devices listed at all | The computer is not seeing the phone. Try another cable - many are charge-only - and another USB port |
| Listed as `unauthorized` | Unlock the phone and accept the prompt asking whether to allow the connection |
| Listed as `offline` | Most often a computer the phone has not seen before, and a prompt waiting on the phone: unlock it and accept. Otherwise unplug and plug in again, or run `adb kill-server` and `adb devices` |
| Was working, now nothing | Check **Settings → About → Developer Mode** is still on. It switches off by itself if you remove your passcode |

### Installing fails with `com.lomiri.click.OperationFailed`

Almost always a framework the phone does not have. Check what it does have:

```bash
adb shell "ls /usr/share/click/frameworks/ | grep qml"
```

GemPlayer needs `ubuntu-sdk-20.04-qml`, which both 20.04 and 24.04 ship.

### `clickable launch` hangs

The launcher command hangs when driven over `adb`; the app may well have
started. Open it from the app drawer instead.

### After an update the app looks the same

It was open, and is still running the old version. Close it from the app
switcher and open it again.

### My videos or music are missing from the Video and Audio tabs

Those tabs show what the system's media library has found, which is the
`Videos` and `Music` folders and their counterparts on a card. A file
copied in a moment ago can take a little while to appear. Anything else on
the phone is reached through the **Browse** tab.

### A USB stick or a card does not show in Browse

It shows under **Storages** a few seconds after the system mounts it, as
`/media/phablet/<its name>`. Ubuntu Touch does not mount drives formatted
**NTFS** at all, so no app sees them; FAT32 or exFAT works. GemPlayer 0.0.37
and earlier never showed one; update.

### A stream asks whether to allow streams

That is the app being offline, as it arrives. **Allow streams** under
**More → Streams** switches them on; the same switch turns them off again.

### A video pauses when I leave the app

By design, as in VLC. **Play on as audio when the app is left**, under
**More → Settings**, lets the sound carry on instead.

### The sleep timer fires late with the screen off

Ubuntu Touch freezes an app a few seconds after it is left, and a frozen app
cannot count. Music plays on, but the timer waits. **Keep running in the
background**, under **More → Settings → Advanced**, keeps the app awake, at
some cost in battery.

### I removed the app with "Keep running in the background" on

Its name is left in the system's list, where it does nothing. To take it
out, look at the list and set it again without `gemplayer.yenis`:

```bash
adb shell "gsettings get com.canonical.qtmir lifecycle-exempt-appids"
adb shell "gsettings set com.canonical.qtmir lifecycle-exempt-appids \"['music.ubports']\""
```

The second line is an example: keep whatever else the first one listed.

---

## Privacy

- No accounts, no analytics, no crash reporting, no advertising, no
  third-party code.
- No network unless you allow streams, and then only the stream addresses
  you open, fetched by the system's player.
- Stored on the phone: your settings, what the player remembers about your
  files, your playlists and the histories. Nothing leaves the phone.
