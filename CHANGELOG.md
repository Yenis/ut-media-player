# Changelog

## 0.0.2 - unreleased

The first build that is a player.

- A list of the videos on the phone, with thumbnails, length and a "seen"
  mark.
- Video player with VLC's gestures: tap for the controls, double tap to skip
  10 s or pause, swipe sideways to seek, swipe up and down for volume (right)
  and dimming (left), pinch to fill the screen.
- Timeline, play and pause, twelve picture sizes, lock with slide to unlock.
- The player follows the phone's orientation by itself, whatever the system's
  rotation lock says; a button holds it.
- **Play as audio**, and back to video, without a break in playback.
- Resumes each file where it was left.
- A video pauses when the app is left or the screen goes off; audio mode
  plays on.
- Opens files handed over by other apps.
- The package is now unconfined; see docs/STORE.md for why.

## 0.0.1 - unreleased

A diagnostics build, not a player.

- Project skeleton: QML-only click for Ubuntu Touch, app identity
  `gemplayer.yenis`, the GemsTech theme and shared components.
- Spike page that checks what the platform offers: playback, formats, seeking,
  the media library, thumbnails, file access, background audio, play as audio,
  network streams.
