# Installing GemPlayer on Ubuntu Touch

GemPlayer is not in the OpenStore. Until it is, you install a build yourself.
This page is short while the app is in early development; it grows into a
full guide with the first real release.

## What you need

| | |
|---|---|
| A phone running Ubuntu Touch 20.04 or 24.04 | Tested only on a Pixel 3a with 24.04-1.x |
| A computer with `adb` | And a USB cable that carries data |
| Developer Mode on the phone | **Settings → About → Developer Mode**. It needs a passcode or PIN to be set first |

## Install a package

Download the `.click` file from the
[Releases page](https://github.com/Yenis/ut-media-player/releases) on GitHub,
then, with the phone connected:

```bash
adb push gemplayer.yenis_0.0.14_all.click /home/phablet/
adb shell "gdbus call --system --dest com.lomiri.click --object-path /com/lomiri/click --method com.lomiri.click.Install /home/phablet/gemplayer.yenis_0.0.14_all.click"
```

The second command asks the system's click service to install the file, as
Clickable does; it prints `()` when it has. Ubuntu Touch 20.04 and later have
no `pkcon`, which older instructions use (checked on the Pixel 3a, 7 October
2026).

The file name ends in `_all.click`: it contains no compiled code and fits
every device.

## Build and install from source

With [Clickable](https://clickable-ut.dev) 8.9 or newer:

```bash
clickable build
clickable install
clickable launch
```

`clickable build` ends with one `click-review` finding, `'unconfined' not
allowed`. It is expected; see [STORE.md](STORE.md).

## Remove it

```bash
adb shell "gdbus call --system --dest com.lomiri.click --object-path /com/lomiri/click --method com.lomiri.click.Remove gemplayer.yenis"
```

The app's own data is in `~/.config/gemplayer.yenis/`,
`~/.cache/gemplayer.yenis/` and `~/.local/share/gemplayer.yenis/` on the
phone. Your media files are never changed.
