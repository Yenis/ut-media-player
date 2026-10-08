# Changelog

## 0.0.19 - 8 October 2026

- A filter for the music lists: the magnifying glass at the top of the
  Audio tab narrows the list you are in as you type. Artists, albums and
  genres are found by their name, files by their file name, tracks by
  title, artist or album.
- The audio player shows the cover, blurred and darkened, behind the whole
  page.

## 0.0.18 - 7 October 2026

- What was playing as audio is there again when the app is opened: the queue
  and the track, paused in the mini-player at the place it was left.
- In the audio player's queue, holding an item opens a menu with "Remove
  from queue" and "Stop after this track". Stopping after a track works with
  the screen off too. Only items still to come can be removed.
- Fixed: after the queue had moved on with the screen off or another app in
  front, opening GemPlayer started the current track again from its
  beginning. It now carries on where it was. In 0.0.13 to 0.0.17.
- Closing the app stops what it plays. Before, the music could play on with
  the app gone.

## 0.0.17 - 7 October 2026

- Volume and brightness by swipe in the audio player, as in the video
  player: swipe up or down on the right side of the cover for the volume, on
  the left side for the screen's brightness. VLC does not have these for
  audio.
- The brightness set there holds while the audio player is open. The phone
  gets its own brightness back when you leave the page or the app.

## 0.0.16 - 7 October 2026

- The audio player has a menu, behind the three dots at the top: Sleep
  timer, Jump to time, Bookmarks and A-B repeat, as in the video player.
  "Play as video" has moved into it from the top of the page.
- Bookmarks and the two ends of an A-B repeat are marked on the audio
  player's timeline. A running sleep timer and an A-B repeat show under the
  title bar; a tap on either goes to its setting.

## 0.0.15 - 7 October 2026

- Fixed: after music had played, or a queue played as audio, the next video
  could appear upside down and show the length of the last track. In 0.0.13
  and 0.0.14.
- Shuffle and repeat. In the audio player, a shuffle button on the left of
  the title and a repeat button on the right, which steps through off, all
  and one. In the video player they are in the menu. Both stay as they are
  set.
- Shuffle mixes what follows the current item and leaves what has played
  where it is; switching it off puts what is still to come back in order.
  A list started while shuffle is on begins with the item you tapped.
- Repeat all and repeat one keep going with the screen off and under other
  apps.
- Music starts at its beginning when it is tapped. Only videos carry on
  where they were left.

## 0.0.14 - 7 October 2026

- The Audio tab lists the music on the phone under Artists, Albums, Tracks,
  Genres and Files. An artist, album or genre opens to its tracks; an
  artist's and a genre's are set out album by album. "Files" is the plain
  list of audio files by file name, not sorted or grouped.
- A tap on a track plays the list it is in from that track on, and leaves
  you in the list with the mini-player. The track that plays is marked.
- Each row has a menu with Play, "Insert next" and "Add to play queue"; an
  open artist, album or genre has a play button at the top.
- An album is the tracks that share an album title and a folder, so a
  soundtrack whose tracks each name a different artist stays one album.
- Fixed: a queue started as audio from a track that was not the first one
  could begin with the first one all the same.
- A long title at the top of a page no longer runs under the buttons beside
  it.

## 0.0.13 - 7 October 2026

- A queue played as audio now moves on by itself with the screen off or
  another app in front. Before, it stopped at the end of the current item
  until GemPlayer was opened again.
- "Insert next" and "Add to play queue" in the menu of a video, folder or
  group, behind a new button in the selection bar, and as two more choices
  for "Playback action". They add to what plays as audio behind the lists;
  with nothing playing, they play.
- Switching a queue of several videos to audio, or back to the picture, now
  makes a break of about a second. One video on its own still switches
  without a break.
- The install instructions used a command that Ubuntu Touch 20.04 and later
  do not have.

## 0.0.12 - 7 October 2026

- An audio player. Music, and a video played as audio, show on a page with
  the cover, title and artist, the timeline, and buttons for previous,
  10 seconds back, play, 10 seconds forward and next.
- The video player's seek gestures work on the cover: a double tap on the
  left or right side goes 10 seconds back or forward, a double tap in the
  middle pauses, and a swipe to the side seeks further. VLC does not have
  these for audio.
- What plays as audio carries on when you go back to the lists, in a bar
  above the tabs. A tap on the bar opens the player; a swipe to the left goes
  to the next item, to the right to the previous. The cross on the bar stops
  playback.
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
