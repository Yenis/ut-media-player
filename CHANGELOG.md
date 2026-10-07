# Changelog

## 0.0.12 - unreleased

- An audio player. Music, and a video played as audio, show on a page with
  the cover, title and artist, the timeline, and buttons for previous,
  10 seconds back, play, 10 seconds forward and next. Holding the back or
  forward button goes 20 seconds.
- The video player's seek gestures work on the cover: a double tap on the
  left or right side goes 10 seconds back or forward, a double tap in the
  middle pauses, and a swipe to the side seeks further. VLC does not have
  these for audio.
- What plays as audio carries on when you go back to the lists, in a bar
  above the tabs. A tap on the bar opens the player; a swipe to the left goes
  to the next item, to the right to the previous. Holding the play button, on
  the bar or in the player, stops playback.
- A music file opened from another app now opens in the audio player, not in
  the video player with an empty picture.

## 0.0.11 - 3 October 2026

- "Information" in a video's menu opens a page about it: its picture and
  name, a button to play or resume it, its length, file size, resolution,
  format, file and folder, when it was last changed, and how far it was
  played. With one video selected, the bar at the top has a button for it
  too.
- The diagnostics page no longer plays test streams from the internet.
  Nothing in the app touches the network now.
- A video's menu is now in VLC's order: Information and the favourite switch
  come before the group entries, and "Mark as played" is last.

## 0.0.10 - 3 October 2026

- Groups of your own, under "Group by name". Select two or more videos and
  tap the folder in the bar at the top to put them into a new group, which
  you name, or into one of the groups there are. A single video's menu has
  "Add to video group" too.
- A group's menu gained "Rename video group" and "Ungroup". Inside a group,
  a video's menu has "Remove from video group".
- A video taken out of its group stays on its own; "Regroup automatically"
  in its menu lets it join videos with a similar name again.

## 0.0.9 - 3 October 2026

- Several videos at once: a long press on a video, folder or group selects
  it, and taps add more or take them out again. A bar at the top then plays
  the selection in order, plays it as audio, or adds it to the favourites or
  removes it from them. The cross and the back key end the selection.
- "Playback action" in the display settings: a tap on a video plays it, or
  plays everything shown from that video on.

## 0.0.8 - 3 October 2026

- A queue. "Play all" in a video's menu plays everything shown, from that
  video on; in a folder's or group's menu it plays what is inside. Each video
  follows the one before by itself.
- In the player, with more than one video queued: previous and next beside
  play, and a button at the top right that lists the queue. A tap on an entry
  goes to it. Previous goes back to the start of a video that is more than
  five seconds in, and to the video before otherwise, as in VLC.
- A video's menu gained Play from start, Play all, Play as audio, and Mark as
  played or not played. Folders and groups have a menu too: Play all, and
  Mark all as played or not played.
- Keyboard: N and P, and the media keys, for next and previous.
- **Fixed:** subtitles were drawn on top of the player's menus.

## 0.0.7 - 3 October 2026

- Videos can be grouped, from "Group videos" in the display settings: by
  name, by folder, or not at all.
- By name is the default, as in VLC: videos whose names begin alike, such as
  the episodes of a series, become one entry showing their thumbnails and
  how many they are.
- By folder shows one entry per folder that holds videos.
- A folder or group opens in place. The arrow in the header and the back key
  lead out again.

## 0.0.6 - 3 October 2026

- Display settings for the Video tab, behind the button at the top right:
  grid or list, "Show only favourites", and the order. Videos can be sorted
  by name, file name, length or how recently they were added; choosing the
  order in use turns it round. All of it is remembered.
- The videos are now in order of name by default.
- A filter: the magnifying glass opens a field that narrows the list as you
  type.
- Favourites: the three dots on a video open its menu, which adds it to the
  favourites or removes it. A favourite carries a star on its thumbnail.
- The keyboard goes away with its enter key, when the list is touched or
  moved, and when a menu, a video or another tab is opened.
- The grid and list switch moved from the top bar into the display settings,
  where VLC has it.

## 0.0.5 - 3 October 2026

- The Video tab shows the videos as a grid of cards, two across on a phone
  held upright. The button at the top right switches to a list and back, and
  the choice is remembered.
- Each thumbnail carries the video's resolution as VLC labels it (4K, 1080p,
  720p, SD), a tick when it was watched to the end, and a bar for how far it
  was played.

## 0.0.4 - 3 October 2026

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
