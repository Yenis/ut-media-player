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

```bash
adb push gemplayer.yenis_0.0.2_all.click /home/phablet/
adb shell "pkcon install-local --allow-untrusted /home/phablet/gemplayer.yenis_0.0.2_all.click"
```

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
adb shell "pkcon remove gemplayer.yenis"
```

The app's own data is in `~/.config/gemplayer.yenis/`,
`~/.cache/gemplayer.yenis/` and `~/.local/share/gemplayer.yenis/` on the
phone. Your media files are never changed.
