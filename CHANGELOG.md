# Changelog

## 0.0.4 - unreleased

- A bar along the bottom with VLC's five tabs: Video, Audio, Browse,
  Playlists and More. Video holds the list of videos; Audio, Browse and
  Playlists say what is to come.
- The More tab shows the version, and the diagnostics page is opened from
  there.

## 0.0.3 - 3 October 2026

The first build published for testers.

- **Fixed:** the volume swipe showed a level but changed nothing. It now sets
  the phone's media volume, as the volume keys do.
- The brightness swipe sets the real backlight. The phone's own brightness
  comes back when the player is left.
- Player menu: sleep timer, jump to time, video information, bookmarks,
  A-B repeat, screenshot.
- External subtitles: a `.srt` file beside the video is shown automatically,
  with a button to hide it and a delay control.
- Small labels under the title show what is switched on: sleep timer, A-B
  repeat, subtitle delay.
- Marks on the timeline for bookmarks and the two ends of an A-B repeat.
- Keyboard: space, arrows, A or Z for picture size, G and H for subtitle
  delay, S to close.
- "Loading" while a file starts; a message if it never does.

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
