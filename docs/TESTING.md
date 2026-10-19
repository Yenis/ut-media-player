# Testing GemPlayer on a device

This page records what has been checked on a device, and how. The first part
is the skip lengths and seek buttons (version 0.0.35), landscape (version 0.0.34), the gesture tips (version 0.0.33), what happens when a file cannot be played (version 0.0.32), Content Hub (version 0.0.31), the library search (version 0.0.30), the settings (version 0.0.29), the playback history and About (version 0.0.28), the streams (version 0.0.27), the playlists (version 0.0.26), the Browse tab (version 0.0.25), the queue's page, search and moving (version 0.0.24), album cards and an artist's albums (version 0.0.23), multiple selection for music (version 0.0.22), a track's information and "go to" (version 0.0.21), sorting and favourites for music (version 0.0.20), the music filter and blurred cover (version 0.0.19), the kept queue (version 0.0.18), the audio player's volume and brightness swipes (version 0.0.17), its menu (version 0.0.16), shuffle and repeat (version 0.0.15), the music library (version 0.0.14), the queue in the background (version 0.0.13), the audio player and mini-player (version 0.0.12), the information page (version 0.0.11), groups made by hand (version 0.0.10), multiple selection (version 0.0.9), the queue and item menu (version 0.0.8), the video library (versions 0.0.5
to 0.0.7), the app shell (version 0.0.4) and the player (versions 0.0.2 and 0.0.3);
the rest is the Phase 0 spike from
[PLAN.md](PLAN.md), a diagnostics page that found out what Ubuntu Touch offers
a QML-only media player. The spike is still in the app, under More →
Diagnostics.

## Open checks

Everything that is not confirmed by a test, in one place (started 9 October
2026). Yenis has no time for checks by hand at present and will come back to
them; until then nothing here counts as confirmed, and nothing is to be
dropped from this list without a result.

What counts as what:

- **Pass over adb** means the logic works when driven through the
  development remote. It says nothing about touch, the back gesture, the
  keyboard, how it feels, or anything the remote cannot press.
- **Pass by hand** is the only thing that closes a row under "By hand".
- When a check is done, its row in the section below is given its result and
  the count here is lowered. A new layer adds its "By hand" rows to this
  table in the same change.

### By hand, per layer

127 checks are open. The rows themselves are in each section's "By hand"
table, marked "Still to do" or "Not reported".

| Layer | Open | Needs more than the phone |
|---|---|---|
| [Skip lengths and seek buttons, 0.0.35](#skip-lengths-and-seek-buttons-version-0035) | 3 | Turning the phone for one |
| [Landscape, 0.0.34](#landscape-version-0034) | 3 | Turning the phone |
| [Gesture tips, 0.0.33](#gesture-tips-version-0033) | 4 | |
| [Files that cannot be played, 0.0.32](#files-that-cannot-be-played-version-0032) | 4 | A file deleted in the file manager for one |
| [Content Hub, 0.0.31](#content-hub-version-0031) | 5 | Another app for each: the file manager, the browser, Messaging |
| [Library search, 0.0.30](#library-search-version-0030) | 6 | |
| [Settings, 0.0.29](#settings-version-0029) | 10 | Subtitles on a bright picture for one |
| [History and About, 0.0.28](#playback-history-and-about-version-0028) | 5 | |
| [Streams, 0.0.27](#streams-version-0027) | 8 | Wi-Fi, and an address to open |
| [Playlists, 0.0.26](#playlists-version-0026) | 8 | |
| [Browse tab, 0.0.25](#browse-tab-version-0025) | 4 | An SD card or USB stick for one |
| [Queue page, 0.0.24](#queue-page-search-and-moving-version-0024) | 4 | A headset or Bluetooth buttons for one |
| [Album cards, 0.0.23](#album-cards-and-an-artists-albums-version-0023) | 3 | |
| [Multiple selection for music, 0.0.22](#multiple-selection-for-music-version-0022) | 3 | |
| [Track information and "go to", 0.0.21](#a-tracks-information-go-to-album-and-go-to-artist-version-0021) | 3 | |
| [Sorting and favourites for music, 0.0.20](#sorting-and-favourites-for-music-version-0020) | 3 | |
| [Music filter and blurred cover, 0.0.19](#music-filter-and-blurred-cover-version-0019) | 3 | |
| [Kept queue, 0.0.18](#kept-queue-remove-and-stop-after-version-0018) | 0 | |
| [Volume and brightness in the audio player, 0.0.17](#volume-and-brightness-in-the-audio-player-version-0017) | 3 | |
| [Audio player's menu, 0.0.16](#audio-players-menu-version-0016) | 4 | |
| [Shuffle and repeat, 0.0.15](#shuffle-and-repeat-version-0015) | 5 | The screen off across an album's end for one |
| [Music library, 0.0.14](#music-library-version-0014) | 6 | One of them failed by hand before its fix: a tap plays the track tapped |
| [Queue in the background, 0.0.13](#queue-in-the-background-version-0013) | 4 | The cable unplugged for one |
| [Audio player and mini-player, 0.0.12](#audio-player-and-mini-player-version-0012) | 3 | |
| [Information page, 0.0.11](#information-page-version-0011) | 3 | |
| [Groups made by hand, 0.0.10](#groups-made-by-hand-version-0010) | 4 | |
| [Multiple selection, 0.0.9](#multiple-selection-version-009) | 4 | |
| [Queue and item menu, 0.0.8](#queue-and-item-menu-version-008) | 2 | Both "Not reported" |
| [Video library, 0.0.7](#video-library-version-007) | 0 | |
| [Video library, 0.0.6](#video-library-version-006) | 1 | Putting the keyboard away, failed by hand before its fix |
| [Video library, 0.0.5](#video-library-version-005) | 4 | |
| [App shell, 0.0.4](#app-shell-version-004) | 2 | |
| [Player, 0.0.3](#player-version-003) | 3 | A real film with its own `.srt`; a hardware keyboard |
| [Player, 0.0.2](#player-version-002) | 0 | |

### Not in any table above

| Check | Where it comes from | State |
|---|---|---|
| A video played as audio, 30 minutes in a pocket with the screen off | S6; run 5 reached 10 minutes | Open; part of the battle test |
| Removable storage: `/media` lists, and its files play | S2, and the Browse tab | Open; no card has been in the phone |
| Playback under other apps and behind the lock screen as one check of the audio side, with the sound indicator and headset buttons | [PLAN.md](PLAN.md), Phase 3, the one unticked box | Open; its parts are rows of 0.0.12, 0.0.13 and 0.0.24 |
| The sleep timer and A-B repeat for music behind the lock screen | [PLAN.md](PLAN.md), Phase 1, platform limits | Known to fire late; not measured |
| A confined build without the `networking` group still plays a stream | D13; read in media-hub's source on 9 October 2026 | **[source]** only. Needs a confined test build on the phone |
| "Group by name" follows VLC's rule of six characters | [PLAN.md](PLAN.md), Phase 2: written down from memory | Not checked against VLC's native library, which is not in the clone |
| The system's album-art lookup reaches a server | 0.0.24 | **Not to be tried**: trying it is making the connection (D13) |
| Screenshot appears in the Gallery | 0.0.3 | Not reported |

## Skip lengths and seek buttons, version 0.0.35

### Checked over adb, 19 October 2026

| Check | Result |
|---|---|
| Settings: "Skip length in the video player", "Skip length in the audio player" and "Rewind and forward buttons" | Pass. After the update the audio length showed 10 s, the one length there was |
| Set over the remote to 5 s, 30 s and on: shown on the page and kept | Pass |
| The video tips name 5 s, the audio tips 30 s | Pass |
| One video, buttons on: rewind, play, forward in the middle | Pass |
| A queue of two videos on the upright phone: previous, play, next, no rewind or forward | Pass |
| The same queue turned with `angle 90`: previous, rewind, play, forward, next | Pass |
| A skip in the video player by its length | Pass, told by keyframes: from 16.67 s in `h264-1080p30.mp4`, whose keyframes are 8.33 s apart, 5 s landed on 16.67 and 10 s asked for 26.67 and landed on 25. In `long-35min.mp4`, a keyframe every 10 s, a 5 s skip forward does not move at all |
| A skip in the audio player by its length | Pass: 1:00 to 1:30 with 30 s |
| No QML warnings in the log | Pass |

The settings were put back as they were afterwards, the tips marked as not
seen.

### By hand

| Check | Result |
|---|---|
| Tap rewind and forward: each skips by the video length, and "−10 s" or "+10 s" shows on its side; taps in a row add up | Still to do |
| Turn the phone with a queue and the buttons on: five buttons, none over another; turn back: three | Still to do |
| Change each skip length: a double tap in that player follows it, the other player's does not | Still to do |

## Landscape, version 0.0.34

### Checked over adb, 14 October 2026

Laid out with the remote's `landscape`, which gives the app a window of
2145 by 1080 turned a quarter, and photographed.

| Check | Result |
|---|---|
| Video tab: four cards to a row; as a list, rows the width of the screen | Pass (layout) |
| Audio tab: four album cards to a row; the track list | Pass (layout) |
| Browse, Playlists, More, Settings, About, the display sheet, the stream question | Pass (layout) |
| The mini-player above the tabs | Pass (layout) |
| The video player, held level with `angle 0`: controls along the bottom, the tips fit | Pass (layout). Without it the player turns its content to the real phone, which stood upright |
| The audio player | **Failed at first:** the cover shrank to a small square above the title, timeline and buttons, and the area for its gestures with it. Now the cover is on the left and the controls beside it |
| The audio player turned to landscape and back, twice | **Failed at first:** back upright, the cover was gone and the controls stood under the header; the layout was switched by bindings. With a state the pictures are the same each time, byte for byte |
| No QML warnings in the log | Pass, after a fix: the first side-by-side layout placed the controls from the cover, which in the upright layout is placed from them, and Qt warned of an anchor loop |

### By hand

| Check | Result |
|---|---|
| Turn the phone with each tab in front: nothing is cut off, and turning back restores it | Still to do |
| The audio player on its side: the cover's gestures, and the buttons | Still to do |
| A tablet, if one is at hand | Still to do |

## Gesture tips, version 0.0.33

### Checked over adb, 14 October 2026

| Check | Result |
|---|---|
| The first video after the update: it starts, is paused, and the tips come, "1 of 8 Controls", the whole picture lit with one dot | Pass; media-hub reads "Paused" |
| The steps in order: Controls, Brightness (left half, up and down), Volume (right half), Pause (middle, two dots), Skip (both sides, two dots, "10 seconds"), Seek (left and right), Picture size (pinch), "Yours to change" | Pass (layout) |
| "Done" on the last: the video plays, and the setting says the tips were seen | Pass |
| A second video: no tips | Pass |
| The audio player opened for the first time on a playing track: its tips, "1 of 7 Pause", over the cover, the music playing on | Pass |
| `back` closes the tips; they count as seen | Pass |
| No QML warnings in the log | Pass |

The first build drew the up-and-down sign as the text ↕, which the phone
drew as a coloured emoji in a box; the signs are the app's own icons now,
and "Skip" on the card, which read like the "Skip" step, is "Close". Both
tips were set to come again afterwards, for Yenis to see as a new user
would.

Checked again on 14 October 2026, as Yenis asked, with the phone unlocked:
the row's own function, `tipsagain`, sets both tips to come again and
shows "The tips will come with the next video"; the next video brings
them. The tips laid out as landscape fit, the card below the signs. And
the system's link-sending tool, tried again for the Content Hub checks of
0.0.31, still ends without sending anything.

### By hand

| Check | Result |
|---|---|
| The first video: the tips by touch, "Next" and a tap anywhere lead on, "Close" ends them, the video plays after | Still to do |
| Turned on its side: the tips turn with the picture and fit | Still to do |
| The audio player's tips, and then the gestures they describe | Still to do |
| "Show the gesture tips again" in Settings, then a video | Still to do by touch; its function passed over adb |

## Files that cannot be played, version 0.0.32

### Before: what 0.0.31 did, 14 October 2026

| Check | Result |
|---|---|
| A missing song, then a real one, handed over as a queue | The audio player, "Loading…" for 20 s, then "This file could not be played."; the queue stays on the missing song. media-hub reads "Stopped" and raised no error |
| A missing video, then a real one | At once the backend's text: "Warning: Failed to open uri file:///…/gone.mp4 because it can't be found."; the queue stays there |
| A text file named `broken.mp4`, and one named `broken.mp3` | 20 s of "Loading…" each, then "This file could not be played." |

### Checked over adb, 14 October 2026

| Check | Result |
|---|---|
| The missing song, then a real one: after 8 s "This file could not be played. It may have been moved or deleted, be damaged, or be in a format the phone cannot play."; 2.5 s later the real song plays, "2 of 2", media-hub reads it | Pass |
| The missing video, then a real one: at once "This file is not there any more. It may have been moved or deleted."; then the real video plays with its picture | Pass |
| `broken.mp4` alone: after 8 s the message, and it stays, there being nothing to move on to | Pass |
| Two that fail, with "repeat all" on: both are tried once, the second's message stays, nothing goes round | Pass |
| After a failure the play button shows "play"; the audio player's message has a dark box behind it, readable over the headphones | Pass |
| A failed item is not put into the playback history | Pass |
| Ordinary playing is undisturbed: a video resumes at its place, a track list plays from its fourth item and `next` moves on, with no message | Pass |
| No QML warnings from the app | Pass. The thumbnailer complained about `broken.mp4` while it was in the library |

The broken test files were deleted from the phone afterwards, and the test
plays removed from the history.

### By hand

| Check | Result |
|---|---|
| A song deleted in the file manager, then played from a playlist: the message, then the next song | Still to do |
| The same for a video in the playback history | Still to do |
| A real file the phone cannot play, if one is at hand: the message after 8 s | Still to do |
| A large video on a card or a slow stick: does it start within 8 s, or is it called failed? | Still to do |

## Content Hub, version 0.0.31

### Checked over adb, 14 October 2026

| Check | Result |
|---|---|
| After the install, the hub's registry: GemPlayer is a destination for links, music and videos, and a share target for the same three | Pass, read from `com.lomiri.content.hub.destination` and `.share` |
| A link sent with the system's `lomiri-content-hub-send` | **Could not be done.** Run over adb it ends at once and sends nothing; through the URL dispatcher it is refused, being hidden from the launcher. It sends no files at all |
| Three songs handed to the app the way the hub hands them, as addresses: the audio player, "1 of 3", the other two next; media-hub plays the first | Pass |
| Two videos: the video player, "1 of 2"; `next` plays the second with its picture | Pass |
| A video and a song together: they play as audio, "1 of 2" | Pass |
| A link while streams are off: the question, with the link in it; nothing plays | Pass |
| "Share" on a video: the system's picker, "Share to", with File Manager and Messaging; `back` closes it | Pass (layout). Nothing was sent: that takes a tap on an app |
| "Share" on a song: the picker again | Pass (layout) |
| QML warnings in the log | One, from inside the system's picker: `ResponsiveGridView.qml:59: Cannot assign [undefined] to bool`. None from the app |

The test plays were removed from the playback history afterwards.

### By hand

| Check | Result |
|---|---|
| The file manager: several songs, and several videos, "Open with" GemPlayer: they play as a queue | Still to do |
| The browser: "Share" on a link to a stream, GemPlayer: the question, then the stream | Still to do |
| The gallery or the file manager: "Share" a video with GemPlayer | Still to do |
| "Share" in a video's menu, then Messaging: the video is attached; then File Manager: it is saved there | Still to do |
| "Share" on a song, then File Manager | Still to do |

## Library search, version 0.0.30

### Checked over adb, 12 October 2026

On the phone's own 188 tracks and 12 videos, and a playlist made for it.

| Check | Result |
|---|---|
| The page with nothing typed: the field, and what it looks through | Pass (layout) |
| "souls": 7 albums, 18 tracks and the playlist "Souls mix", under "Albums • 7", "Tracks • 18", "Playlists • 1"; albums with their covers | Pass |
| "720": the three videos with it in their name | Pass |
| "zzzz": "Nothing in the library matches “zzzz”." | Pass |
| "a": four videos; "Artists • 24" with 20 listed and "4 more. Type more to narrow it down."; "Albums • 33" with "13 more"; "Tracks • 133" with "113 more"; six genres | Pass |
| A tap on an album: the Audio tab, that album open on its two tracks; `back` and More: the search is as it was left | Pass |
| A tap on the second track found: it plays, "2 of 18", the queue being the tracks found; media-hub reads that track | Pass |
| An album's menu, "Add to playlist": its 17 tracks are in the playlist | Pass |
| A track's menu, "Insert next": the queue grows by one | Pass |
| A tap on the playlist: the Playlists tab, that playlist open | Pass |
| A tap on a video: the video player | Pass |
| A result's menu: Open, Play all, Insert next, Add to play queue, Add to playlist | Pass (layout) |
| No QML warnings in the log | Pass |

All of it was run twice, the second time after Yenis said the screen had
been off, with the lock screen asked before and after: not showing, and the
app answering as the active one. Both runs gave the same results. The
playlist and the history entries the tests left were removed from the phone
afterwards.

### By hand

| Check | Result |
|---|---|
| More → Search: the keyboard comes up with it; typing narrows the results as it goes | Still to do |
| Scrolling the results puts the keyboard away; the cross empties the field | Still to do |
| A tap on each kind of result; the three dots on one | Still to do |
| Back from an opened album to the search: is the way back clear enough, being two taps? | Still to do |
| The header arrow and the back gesture leave the search | Still to do |
| Is under More the right place for it, or should it be reachable from every tab? | Still to do |

## Settings, version 0.0.29

### Checked over adb, 12 October 2026

Each setting was changed through the same function the page's switches
call, and what it does was then looked at.

| Check | Result |
|---|---|
| The page: Video, Gestures in the players, Subtitles with a sample, Audio, History, Advanced; every value at its default | Pass (layout) |
| Skip length 30 s, `tapseek forward` in the audio player: from 0:02 to 0:34 | Pass. In the video player the same step landed 13 s short on `long-35min`, a seek there going to the keyframe before its target |
| Resume off: a video left at 5:00 starts at 0:03, opened fresh and opened again while still loaded | Pass, after a fix: still loaded, it played on from 5:04. It is now sent to its start as "Play from start" is |
| Resume on again: the same video carries on at 5:02 | Pass |
| "Play on as audio" on, a video playing, the calculator brought to the front: media-hub reads "Playing" 12 s later; back in the app, the audio player with the mini-player behind it, 25 s further on | Pass |
| The same with the setting off, as before: media-hub reads "Paused"; back in the app the video is paused | Pass |
| Subtitles huge and yellow on `sidecar` | Pass. The dark box cannot be told from the black under this picture; it shows in the page's sample |
| "Bring back the queue" off, music playing, the app restarted: nothing in the mini-player | Pass |
| The settings are kept across a restart | Pass |
| "Forget progress" asks first; done, no video has a tick or a bar | Pass |
| "Clear the playback history" and "Clear the stream history": both lists empty | Pass |
| `back` leaves Settings for More | Pass |
| "Keep running in the background" on: the system's list reads `['music.ubports', 'gemplayer.yenis']`; off again: `['music.ubports']` | Pass |
| With it on, music and a sleep timer of 20 s, the calculator in front: media-hub reads "Paused" 28 s later, and the app answers the remote from behind the calculator | Pass, at once, without a restart of the app |
| With it on, a video playing, the calculator in front | **Failed at first: the video played on.** The app's state behind the calculator is "inactive", never "suspended"; its window says nothing more. Fixed: with the switch on, three seconds of "inactive" count as the app being left. media-hub then reads "Paused" |
| With it off, the same: paused, as before | Pass |
| No QML warnings in the log | Pass |

The restart in the queue check was the remote's, which kills the process:
the music played on in media-hub, as a killed app's does (0.0.18), and was
stopped by playing something else. And "Forget progress" was run for real
on the phone: every resume point and played mark there is gone, the test
files' and those of the one video that is not a test file.

### By hand

| Check | Result |
|---|---|
| More → Settings; the page scrolls; the header arrow and the back gesture lead back | Still to do |
| Each gesture switched off is gone from the video player, and from the audio player | Still to do: no gesture can be made over adb |
| With volume off, the brightness swipe takes both halves, and the other way round | Still to do |
| Double tap to seek off: a double tap on a side does nothing, in the middle it pauses | Still to do |
| The skip length by double tap and by the buttons, at 5 s and at 30 s | Still to do |
| Subtitles: each size and colour, and the dark box, on a bright picture | Still to do |
| "Play on as audio" with the power button, not another app | Still to do |
| The three questions under Advanced: "Cancel" leaves things as they are | Still to do |
| "Keep running in the background" on: a sleep timer of a few minutes on music with the screen off; A-B repeat with the screen off | Still to do |
| With it on: a video pauses when the phone is locked; pulling the system's panel down for a moment does not pause it, holding it open does; and a day's battery beside a day with it off | Still to do |

## Playback history and About, version 0.0.28

### Checked over adb, 12 October 2026

| Check | Result |
|---|---|
| The History page with nothing played: the switch, on, and "Nothing has been played yet." | Pass |
| A music file, a video, then the fourth track of the track list and `next`: four entries, the latest first, each with "Today" and the time, the video with its picture, the one that plays in the accent colour | Pass |
| A tap on the video's entry: the video player; on a track's: it plays behind the list, alone, "1 of 1", media-hub reads that track | Pass |
| An entry played again moves to the top | Pass |
| "Add to play queue" from an entry while music plays: the queue reads 2; "Remove from history": the entry is gone | Pass |
| The switch off, then `next`: the next item plays and the history is as it was; More says "Off. Nothing new is listed." | Pass |
| "Clear": "Clear the playback history?" with "Clear history" and "Cancel"; cleared, the list is empty | Pass |
| Six 30 s tracks played with the calculator in front for 75 s: back in the app the history has the three that started, the third on top | Pass |
| The About page: icon, "Version 0.0.28", five entries | Pass (layout) |
| `back` leaves History and About for More | Pass |
| No QML warnings in the log | Pass |

The first build had a cross in the header for clearing, which beside the
mini-player's cross read as "close"; it is the word "Clear" now. The test
entries were cleared from the phone afterwards.

### By hand

| Check | Result |
|---|---|
| More → History and More → About; the header arrow and the back gesture lead back | Still to do |
| A tap on an entry plays it; the three dots open its menu | Still to do |
| The switch by touch; "Clear", and "Cancel" in its question | Still to do |
| After a day of use: is "the latest 200, each item once" what a history should be? | Still to do |
| The About page scrolls, and reads right | Still to do |

## Streams, version 0.0.27

### Checked over adb, 12 October 2026

With Wi-Fi on. What plays was read from media-hub beside the app's own
state. The addresses used: an HLS test stream with a picture
(`test-streams.mux.dev/x36xhzz/x36xhzz.m3u8`), an MP3 file on a web server
(`www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3`), a live radio
station whose address has no file ending (`ice1.somafm.com/groovesalad-128-mp3`)
and an address that does not exist. All were removed from the phone's
history afterwards, and the switch left off.

| Check | Result |
|---|---|
| A new install's state: "Allow streams" off; More says "Off. GemPlayer is offline." | Pass |
| An address opened while streams are off: the question, with the address in it; nothing plays, nothing is in the history | Pass |
| "Cancel": the question goes, the switch stays off, media-hub was given nothing | Pass |
| "Allow streams": the switch is on, the HLS stream plays in the video player with its picture, length 10:34; the address is in the history | Pass |
| A seek to 2:00 in the stream | Pass |
| `back` from the stream: paused, the Streams page again | Pass |
| The MP3 on a web server: the audio player, length 6:12, media-hub reads "Playing" with that file | Pass, after the fix below: opened after a video, it showed its title over the video's sound |
| The live radio station: starts in the video player, moves to the audio player by itself, mini-player behind the lists | Pass, after two fixes. With no length it never counted as started, so it stayed "starting" and would have been called dead after 20 s; and nothing moved it out of the video player |
| The address that does not exist: after 20 s "The stream did not start. Check the address and the connection." | Pass |
| The switch turned off while the radio plays: it stops, the mini-player goes, media-hub reads "Paused" | Pass, after a fix. A first attempt also made media-hub let go of the stream, by handing the player an empty address, and the radio **played on with the switch off**: the backend calls play by itself when its video sink is reset. That step was taken out; the stream stays loaded, paused |
| With the switch off, a tap in the history: the question again | Pass |
| History: rename, delete, "Add to playlist" into a new playlist | Pass. "Copy address" was called and raised nothing; what the clipboard then held was not read |
| With the switch off, "Play" on a playlist that holds a stream, and "Add to play queue" of it while music plays: the question each time; cancelled, the queue is as it was | Pass |
| The switch is kept across a restart, on and off | Pass |
| `back`: closes the question first; leaves the Streams page for More | Pass |
| No QML warnings in the log | Pass |

### A video, then the first track of a list: the video's sound. Found and fixed

| Check | Result |
|---|---|
| A local video played and left with `back`, then a single music file opened | **Fail**, and from the code most likely since 0.0.13, though earlier builds were not tried: the audio player shows "MP3 440 Hz", media-hub plays `hevc-1080p.mp4`, 0:20 long, as sound. The backend's log has no `setMedia` for the track: the list stood at index 0 already, and asking for index 0 was dropped before it reached the backend |
| The same with the list stepped to -1 and back to 0 in one go | Fail: only the -1 arrived |
| The same with 0 asked for once the list has reported -1 | Pass: `setMedia` with the track, media-hub plays it, length 0:30 |
| A list started at its first item with nothing played before; at its sixth item; `next`; and at its first item after a video | Pass, each read from media-hub |

### By hand

| Check | Result |
|---|---|
| More → Streams; the header arrow and the back gesture lead back | Still to do |
| The address field: the keyboard comes with it, the enter key and the play button both open the address, a touch beside it puts the keyboard away | Still to do |
| The question: "Cancel", a tap beside it, and "Allow streams" | Still to do |
| The switch by touch, on and off; off while a stream plays | Still to do |
| A stream with a picture: gestures, turning the phone, "Play as audio" and back | Still to do |
| A radio station for half an hour with the screen off | Still to do |
| History: a tap plays; the three dots: Rename by typing, Copy address and paste it elsewhere, Add to playlist, Delete | Still to do |
| A stream when the phone has no connection: what is said, and after how long | Still to do |

## Playlists, version 0.0.26

Built with no phone connected and checked on the computer first; run on
the phone three days later, which found three faults the computer could
not show. By hand is still to do.

### Checked on the computer, 9 October 2026

The whole app started in the Clickable build image, drawn in software
([DEVELOPING.md](DEVELOPING.md), "Without a phone"), and driven through the
shell's and the pages' own functions with made-up tracks and videos. The
database is the real one, SQLite through LocalStorage.

| Check | Result |
|---|---|
| The app loads with the new pages: no QML error or warning from them | Pass |
| The tab with no playlists: the note that says how to make one, the plus in the header | Pass (layout) |
| "Add to playlist" for three tracks, then "New playlist" named "Road trip": one playlist of 3, and "3 items added to the new playlist “Road trip”" | Pass |
| Three more to the same playlist, one of them in it already: 5 items, "2 items added to “Road trip”, 1 already there" | Pass |
| One that is in it, to a new playlist named "road TRIP": no second playlist, "Already in “Road trip”" | Pass |
| The plus twice with the same name, in other capitals: one empty playlist | Pass |
| The list: three playlists by name, "Empty", "2 videos • 15:10", "5 items • 15:25" | Pass (layout) |
| Inside one: each item with its place, artist and length, "Video" on a video, headphones or a screen for its picture | Pass (layout) |
| "Move down" on the first, "Move up" on the last: the order changes, and is kept | Pass |
| "Remove from playlist" on the second: gone, the others close up | Pass |
| A tap on the third item of a mixed playlist asks for all four from there, as audio behind the lists | Pass, at the page's signal. Nothing was played: there is no playback in the image |
| "Play" on a playlist of videos only asks for it with its pictures | Pass, likewise |
| "Insert next" on an item hands on that item; "Add to play queue" on a playlist all of it | Pass, likewise |
| Rename; "Delete" asks "Delete “Films”?" with "Delete playlist" and "Cancel"; deleted, it is gone from the list | Pass |
| The sheets: "Add to playlist" with "New playlist" and each playlist with its count; an item's menu; a playlist's menu | Pass (layout) |
| The rename dialog, with the name selected, in the upper part of the page | Pass (layout) |
| `back`: closes "Add to playlist" first; leaves an open playlist; does nothing in the list of playlists | Pass |
| The "Add to playlist" signal of the Audio tab reaches the picker | Pass. The Video tab's, the Browse tab's and the audio player's are wired the same way and were not fired: the libraries are empty in the image |

### Checked over adb, 12 October 2026

On the phone's own 188 tracks and the test files. What plays was read from
media-hub beside the app's own state.

| Check | Result |
|---|---|
| The app starts after the update from 0.0.25, with its earlier data, and the log has no QML warnings | Pass, after a fix: with playlists that hold videos, the Playlists tab asked for their pictures before the media library had loaded, and the log had "Invalid image provider: image://thumbnailer/…". The pictures now wait for the library |
| "Add to playlist" on a track, then a new playlist: it holds the track with its title and length | Pass |
| The same for an album of two tracks, for two selected tracks of which one was in it already, for a video, for a video group of two and for two selected videos | Pass: 2 added, 1 added with "1 item added to “Phone test”, 1 already there" above the tabs, 1, 2 and 2 |
| "Add to playlist" on a folder of the Browse tab that is not open, then on another: each gives its own files, 6 tracks and 11 videos | Pass |
| The list: each playlist with a picture from its first video or cover, "4 videos • 1:40", "6 tracks • 3:00", "5 items • 13:19" | Pass |
| A tap on the third item of a playlist of music: it plays, "3 of 6", media-hub reads "Playing" with that title, the mini-player shows, the item turns to the accent colour | Pass |
| "Insert next" on an item and "Add to play queue" on a playlist of five while that plays: the queue reads 12, the inserted item first; `next` plays it | Pass |
| "Save playlist" in the audio player with "repeat all" on, the queue holding one track twice: a playlist of 11 | Pass, after two fixes. The message said 12, the number handed over and not the number that went in; and it was wider than the screen, cut off at both ends. It now counts what the database took, and the audio player's message breaks into a second line |
| A playlist of four tracks and a video, from its fourth item: the track plays, `next` plays the video as audio, "5 of 5" | Pass |
| "Play" on a playlist of videos only: the video player, "1 of 4"; `next` shows the second with its picture | Pass |
| The playlists are there after a restart, with their pictures; the queue that played is back in the mini-player | Pass |

The six playlists made for this were deleted again from the phone.

### By hand

| Check | Result |
|---|---|
| The plus, a name typed, Create; the playlist appears | Still to do |
| "Add to playlist" from a track's and a video's menu: choose a playlist, and "New playlist" with a name typed | Still to do |
| The Audio tab's selection bar: the plus now asks "Add to play queue" or "Add to playlist" | Still to do |
| The Video tab's selection bar: "Add to playlist" behind the queue button | Still to do |
| Inside a playlist: a tap plays, the three dots open the menu, "Move up" and "Move down" keep the menu open | Still to do |
| Rename by typing; Delete, and Cancel in its question | Still to do |
| "Save playlist" in the audio player's menu | Still to do |
| The back gesture: out of a playlist, and out of "Add to playlist" | Still to do |

## Browse tab, version 0.0.25

### Checked over adb, 8 October 2026

| Check | Result |
|---|---|
| The overview: "Storages" with Internal storage, "Favourites" with a note that there are none | Pass, after a fix: with no card mounted it listed "assets" and "qml" as storages. The model, given `/media/phablet`, which is not there, listed the app's own folder |
| Internal storage: Documents, Downloads, Music, Pictures, Videos; Music: its folder, then 182 files | Pass |
| A folder inside: files with length and size, the path "Internal storage › Music › gemplayer-test" above, the last part plain and the others to tap | Pass |
| A tap on the third music file: it plays as "3 of 6", the list stays with the mini-player, the file's name turns to the accent colour | Pass |
| A tap on the fourth video: the video player, "4 of 11" | Pass |
| "Play all" on a folder that is not open | **Failed at first:** nothing played, and the next "Play all" played the folder asked for before. The listing was read before it had arrived. Fixed; a folder of eleven videos, a folder of one, the first again, and a folder of music each play their own |
| The star on an open folder puts it under Favourites; entered from there, `back` leads to the overview | Pass |
| The star on the overview | It stored an empty favourite. Fixed: the overview cannot be one |
| `back` steps up folder by folder to the overview | Pass |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| Folders, files and the path bar by touch; the back gesture steps up | Still to do |
| A folder's menu: Open, Play all, favourite | Still to do |
| A long path: the bar scrolls and shows its end | Still to do |
| An SD card or USB stick: it shows under Storages, and plays | Still to do |

## Queue page, search and moving, version 0.0.24

### Checked over adb, 8 October 2026

The album is the six test tracks; what plays next was read from media-hub.

| Check | Result |
|---|---|
| The fifth item moved to play next: it leads what is to come, the others follow in their order | Pass |
| An item with "stop after this track" moved to the end: the stop is on the last item now | Pass |
| A move to before the playing item lands right behind it instead | Pass |
| `next` after the moves: media-hub plays what the app lists as next | Pass |
| The queue page: "Queue – 2 of 6", each item with its place, artist and length, the playing one tinted, "Stops after this track" under the item that has it | Pass |
| Filtered by "hz": the five tracks with "Hz" in their title, with their places in the queue | Pass |
| A filter with no match: "Nothing in the queue matches “zz”." | Pass |
| `back` closes the filter, then the queue, and leaves the player open | Pass |
| No QML warnings in the log | Pass |

### The system's album art, 8 October 2026

| Check | Result |
|---|---|
| Is the thumbnailer made to fetch covers online? | **Yes.** `gsettings list-recursively com.lomiri.Thumbnailer` has `dash-ubuntu-com-key` and `max-downloads 8`, and `thumbnailer-service` links `libQt5Network`. `image://albumart/` stays unused (D13) |

### By hand

| Check | Result |
|---|---|
| The queue opens at the playing item in a long queue | Still to do |
| Hold an item still to come: Play next, Move up, Move down; the menu stays open for up and down | Still to do |
| The filter by typing; a tap on a result goes to that item | Still to do |
| Headset and Bluetooth buttons, and the sound indicator's play, previous and next, while music plays from a queue | Still to do. The last open check of the audio phase; adb cannot press them |

## Album cards and an artist's albums, version 0.0.23

### Checked over adb, 8 October 2026

| Check | Result |
|---|---|
| Albums: two cards to a row, each with its cover or the headphones, title, artist and number of tracks, and a menu button on the cover | Pass |
| An artist opens to their albums as cards; the header names the artist and has the play button | Pass |
| An album there opens to its tracks; a tap plays from that track on within the album ("2 of 17") | Pass |
| `back` leads from the album to the artist, and from the artist to the Artists list | Pass |
| "Go to artist" from a track opens the artist on their albums | Pass |
| "Display albums in list": rows again, with small covers | Pass |
| A genre still opens to its tracks under headings | Pass |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| Scrolling the album cards is smooth, and the covers appear without a long wait | Still to do |
| Artist, album, track and back again by touch and by the back gesture | Still to do |
| A long press on a card selects the album; the card's menu button opens its menu | Still to do |

## Multiple selection for music, version 0.0.22

### Checked over adb, 8 October 2026

| Check | Result |
|---|---|
| Three tracks of an open artist selected: "3 selected" in the bar with play, insert next, add and star; the rows tinted; the row menus gone | Pass |
| Play: the three as a queue, in the order shown, the selection ended | Pass |
| Two more selected and inserted next: the queue reads the playing track, the two, then the rest | Pass |
| Two albums selected and added to the queue: their seven tracks follow at the end | Pass |
| Two tracks selected and starred: "only favourites" then lists the two; selected again and starred, they are unmarked | Pass |
| `back` ends a selection; so does switching to another list | Pass |
| A heading cannot be selected | Pass: a row number that fell on one selected nothing |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| A long press selects, taps add and take out, in each of the five lists | Still to do |
| The four buttons of the bar | Still to do |
| The cross and the back gesture end the selection | Still to do |

## A track's information, "Go to album" and "Go to artist", version 0.0.21

### Checked over adb, 8 October 2026

| Check | Result |
|---|---|
| Information for a track with a cover: the cover square, title, Play, then Artist, Album, Track, Released, Length, File size, Format and on | Pass |
| Information for a test track: the headphones for a cover, Genre "Test", 0:30, 241 KB | Pass |
| "Go to album" from a filtered track list: the filter closes, Albums opens on that track's album | Pass |
| Inside an album the menu offers "Go to artist" and not "Go to album" | Pass |
| "Go to artist" from there: the artist's tracks under the album's heading; `back` leads to the Artists list | Pass |
| A video's information page is as it was: wide picture, "Resume", Length, File size, Resolution, Format and on | Pass |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| Information from a track's menu by touch; the arrow and the back gesture close it; Play plays | Still to do |
| "Go to album" and "Go to artist" from each list | Still to do |
| A video's Information page is as it was | Still to do |

## Sorting and favourites for music, version 0.0.20

### Checked on the computer, 8 October 2026

The orders in `qml/js/AudioLibrary.js`, run under node with made-up tracks.

| Check | Result |
|---|---|
| Tracks by name, album, artist, length and date changed, each way round | Pass |
| Albums by name, artist and release date | Pass |
| "Files" is left as it comes whatever is asked | Pass |
| Only favourites: the albums that the favourite tracks belong to, with those tracks | Pass |
| An order a list does not have falls back to its first | Pass |

### Checked over adb, 8 October 2026

On the phone's own 188 tracks.

| Check | Result |
|---|---|
| Tracks, longest first: the 20-minute "King's Field IV" track leads | Pass |
| Tracks, recently added: the six test files, pushed last, lead | Pass |
| Albums, newest first, and by artist | Pass |
| Two tracks marked from their menus: a star on each; "only favourites" leaves Tracks with the two and Artists with their two artists | Pass |
| Unmarking them one by one empties the list: "No favourites yet." | Pass |
| The display sheet: the favourites switch, then the orders of the list in view, the chosen one marked with its direction | Pass (layout) |
| After a restart Albums is by name again, as it was left | Pass |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| The sliders open the sheet; a tap chooses an order, a second tap turns it round | Still to do |
| A track's menu adds it to the favourites; the star appears | Still to do |
| "Show only favourites" in each of the five lists | Still to do |

## Music filter and blurred cover, version 0.0.19

### Checked over adb, 7 October 2026

On the phone's own 188 tracks.

| Check | Result |
|---|---|
| Artists filtered by "kita": the five artists with Kitamura in their name, each with all its tracks | Pass |
| Albums by "remix": "Bloodborne Remixes" and "Demon's and Dark Souls Remixes" | Pass |
| Tracks by "gwyn": five tracks, found by title | Pass |
| Genres by "zzz": nothing, and "Nothing matches “zzz”." | Pass |
| Files by ".flac": `test-2.flac` | Pass |
| A filtered album opens, and a tap plays its track; `back` leaves the album, then the filter | Pass |
| The audio player on a track with a cover: the cover blurred and darkened behind the page, text and buttons readable | Pass |
| A track without a cover: the plain background | Pass |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| Type into the filter; the list follows; scrolling puts the keyboard away | Still to do |
| The cross in the field empties it; the magnifying glass closes the filter | Still to do |
| The blurred background changes with the track, and playback stays smooth | Still to do |

## Kept queue, remove and stop after, version 0.0.18

### Checked over adb, 7 October 2026

The album is the six 30 s test tracks; what plays was read from media-hub's
MPRIS interface beside the app's own state.

| Check | Result |
|---|---|
| Second of six playing at 0:16, the app restarted: the mini-player shows the track, "2 of 6", paused at 0:13 | Pass |
| `play` then: it carries on from 0:13, and the queue behind it is the same | Pass |
| `queueremove 4`: "2 of 5", the item gone from what is to come | Pass |
| "Stop after" on the playing track: at its end playback stops and the mini-player goes | Pass, after a fix: emptying the kept queue stored an empty text, which the database refused, and the error left the mini-player standing |
| "Stop after" on the next track, the calculator in front: media-hub reads "Stopped" at that track's end; back in the app the queue is closed | Pass |
| Restart after a queue was stopped: nothing is brought back | Pass |

### Coming back after a freeze: the track started again. Found and fixed

| Check | Result |
|---|---|
| A track change with the calculator in front, then back to the app | **Fail, and so since 0.0.13:** media-hub read 0:29 in the second track while the app was frozen and 0:03 four seconds after it woke. The log shows `setMedia` and `play` from Qt's player for each index change that arrived on waking |
| The same with the catching up: 0:14 while frozen, 0:19 five seconds after waking | Pass |
| Twelve seconds in the background with no track change: 0:20 before, 0:24 four seconds after waking | Pass, nothing sought |
| The app's process killed while it plays | **media-hub plays on**, to the end of its list; the log has only "Cannot queue arguments of type 'Player::Client'". A restarted app shows its kept queue paused while the old one still sounds, until something is played |

### By hand

| Check | Result |
|---|---|
| Play music, close the app from the app switcher: the music stops | Pass (Yenis, 7 October 2026: "it works", said of the layer as a whole) |
| Open the app again: the mini-player has the track, and play carries on | Pass (Yenis, likewise) |
| Hold an item in the queue: "Remove from queue", "Stop after this track" | Pass (Yenis, likewise) |
| Screen off across a track change or two, then unlock and open the app: the track carries on, with at most a short break | Pass (Yenis, likewise) |

## Volume and brightness in the audio player, version 0.0.17

### Checked over adb, 7 October 2026

The levels were read from the sound and power indicators themselves.

| Check | Result |
|---|---|
| `brightness -0.4` in the audio player: the backlight goes from 1.0 to 0.6 | Pass |
| Leaving the page gives the phone its 1.0 back; opening the page again starts from 1.0 | Pass |
| `volume -0.2` and `volume 0.2`: the media volume goes from 0.37 to 0.17 and back | Pass. The indicator read 0.73 before anything played: it reports the volume of what is sounding, and music has its own |
| The overlay: speaker, bar and "62%" over the cover | Pass |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| Swipe up and down on the right of the cover: volume; on the left: brightness | Still to do |
| A sideways swipe still seeks, and a double tap still seeks or pauses | Still to do |
| The phone's brightness returns on going back to the lists, and with the screen locked and unlocked | Still to do |

## Audio player's menu, version 0.0.16

### Checked over adb, 7 October 2026

| Check | Result |
|---|---|
| The menu: Sleep timer, Jump to time, Bookmarks, A-B repeat; "Play as video" is not offered for music | Pass (layout) |
| A video played as audio: "Play as video" is the menu's third entry, and `video` returns to the picture | Pass |
| `bookmark` at 0:07 adds "Bookmark at 0:07", listed under Bookmarks and marked on the timeline | Pass |
| `ab` at 0:09 and again at 0:15: both ends marked on the timeline, playback stays between them | Pass: at 0:14 nine seconds after the second mark |
| `sleep 600000`: "Sleep 9:58" under the title bar beside "A-B repeat"; the picker opens with "Remove current" | Pass |
| `ab` a third time and `sleep 0` clear both | Pass |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| The menu by touch; Jump to time with the number pad | Still to do |
| A bookmark: add, tap to go there, hold to remove | Still to do |
| "Play as video" in the menu for a video played as audio | Still to do |
| The sleep timer pauses music while the app is in front | Still to do |

## Shuffle and repeat, version 0.0.15

### Checked over adb, 7 October 2026

What plays was read from media-hub's MPRIS interface beside the app's own
state. The album is the six 30 s test tracks.

| Check | Result |
|---|---|
| The list's own `Loop` mode at the end of the album | **Fail:** the hub wraps to the first track, then Qt calls `next()` on top, and the second track plays. Not used |
| The list's own `Random` mode | **Fail:** of seven moves, two tracks came twice before the sixth came once; the mode reads back as `Loop`. Not used |
| The list's own `CurrentItemInLoop` | Pass: the track starts again, the list reports its index again. Used for "repeat one" |
| `removeItems` behind the playing item, `addItems` after | Pass, playback undisturbed: 178 removed in 0.5 s, 150 added in 23 ms |
| `removeItems` and `insertItem` before the playing item | **Fail:** `currentIndex` then names another file than the one playing. Never done |
| Repeat all: the last track ends, the first follows, the app shows "1 of 6" | Pass |
| Repeat all: `next` six times goes round once | Pass |
| Repeat all with the calculator in front for 50 s over the album's end | Pass: the hub went round to the second track; back in the app, "2 of 7" and the right title |
| "Insert next" while repeat all is on, then `next` | Pass: the inserted item plays |
| Repeat one: the track starts again at its end | Pass, music and a video on screen. The video failed at first: the restart came before the player had settled into "stopped". It now waits 50 ms |
| Shuffle on: the items behind the current one are mixed, the hub plays them in that order | Pass |
| Shuffle off: what is still to come is back in album order | Pass |
| Repeat off: the queue ends at its end, the mini-player goes | Pass |
| The buttons: shuffle left of the title, repeat right, a "1" in it for repeat one; Repeat and Shuffle in the video menu | Pass (layout) |

### A video after audio: upside down. Found and fixed, 7 October 2026

| Check | Result |
|---|---|
| Music, stopped with the cross or played to its end, then a video | **Fail, and so in 0.0.13 and 0.0.14:** the video is drawn upside down and its length reads 0:30, the last track's. Every video after it too, until the app is restarted. A queue switched to audio and back to the same video did not show it, the file being the same; that is why it went unseen |
| The same with the hub's list emptied before the address is set | Pass: right way up, right length. Checked after the cross, after the end of the music, over playing music, and for a video queue switched to audio, moved on, and switched back |
| Then: a video played to its end, and `back` | **Fail: media-hub aborted** ("munmap_chunk(): invalid pointer") when the stopped player was paused, its list being empty. Every app's playback goes with it; systemd starts it again |
| The same with no pause sent to a stopped player | Pass. Seven runs across ends of videos and music, among them a video opened again after its end, opened and left at once, a video queue going round, and a session with video only: no abort |

### By hand

| Check | Result |
|---|---|
| A video after music is the right way up | Still to do |
| Shuffle and repeat by touch in the audio player; the message on the cover | Still to do |
| Repeat and Shuffle in the video player's menu | Still to do |
| Repeat all on an album with the screen off, across its end | Still to do |
| A tapped song starts at its beginning | Still to do |

## Music library, version 0.0.14

### Checked on the computer, 7 October 2026

The grouping in `qml/js/AudioLibrary.js`, run under node with made-up tracks.

| Check | Result |
|---|---|
| Artists go by album artist where there is one, so a compilation is one "Various" and not one artist per track | Pass |
| A track with no artist, album or genre is listed under "Unknown artist", "Unknown album", "Unknown genre" | Pass |
| An album's tracks are in order of disc, then track number, then title | Pass |
| An artist's rows: a heading per album, its tracks under it; a genre's headings name artist and album | Pass |
| Lists are in alphabetical order whatever the case of the first letter | Pass |

### Checked over adb, 7 October 2026

On the phone's own music, 188 tracks, and the six test files.

| Check | Result |
|---|---|
| The four lists: 32 artists, 11 genres, 188 tracks; rows with name and counts, a round picture for an artist | Pass |
| Albums keyed by title and artist | **Fail on real files:** "Bloodborne Original Soundtrack - Disc 2" appeared four times, once per composer. Keyed by title and album artist: the same, the files naming each composer as album artist. Keyed by title and folder: one album of five tracks. Kept |
| An artist opens to its tracks under album headings, with the covers found in the files; `back` returns to the list | Pass |
| A tap on a track in "Tracks" plays all 188 from there, as one list handed to media-hub; the page stays, the mini-player shows, the track's title turns to the accent colour | **Failed by hand (Yenis): whichever track was tapped, the first of the list played.** Filling the hub's list reported "index 0" at once, before the app had noted which item it was waiting for, and that was read as the hub having moved to the first item. The first adb run showed it too, as "1 of 188" after a tap on the third row, and it was not noticed. Fixed, and checked against media-hub's own track number: rows 6, 121 and 1 of 188 and row 8 of an album of 11 each play the row tapped, and `next` moves on from there |
| "Files": 188 rows by file name, with folder and length, in the library's order; a tap plays from that file on | Pass |
| "Insert next" from a row's menu while something plays: the queue grows by one and a message says so | Pass |
| "Add to play queue" with nothing playing plays the track and leaves the list in front | Pass, after a fix: it opened the full player at first |
| A long album title in the header stops short of the play button | Pass, after a fix to `PageHeader.qml` |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| The four tabs by touch; scrolling 188 tracks is smooth | Still to do |
| Open an artist, an album, a genre; the header arrow and the back gesture return | Still to do |
| A tap on a track plays that track, in every list, and the next one follows by itself | Still to do, again |
| "Files" lists the audio files as expected | Still to do |
| A row's menu: Play, Insert next, Add to play queue | Still to do |
| Do the albums look right for your collection, grouped by title and folder? | Still to do |

## Queue in the background, version 0.0.13

### Checked over adb, 7 October 2026

"In the background" here is the calculator brought to the front; the app's
log shows it inactive from then on, and what plays is read from media-hub's
MPRIS interface.

| Check | Result |
|---|---|
| Everything played from a `Playlist`, videos included | **Fail, and the reason for two ways of playing.** A video's picture was black on the first file and on some later ones, and once showed a frame of the file before. The surface was set up with the size of the previous item, or 0 x 0. Attaching the `VideoOutput` again changed nothing |
| A queue of three played as audio, calculator in front for a minute | Pass: media-hub went from track 3 to 4 to 5 by itself. Back in the app, the title and "6 of 12" were right |
| Music with two items added while it played, calculator in front | Pass: tracks 0, 1, 2, then "Stopped". Back in the app the mini-player was gone |
| The queue ends with the app in front | Pass: playback stops and the mini-player goes |
| A video queue on screen moves on, with its picture | Pass |
| One video to audio and back to its picture | Pass, without loading again |
| A queue of several to audio at 5:02 of `long-35min` | Pass: carries on at 5:03 after loading again; `next` moves on; back to video shows the picture |
| Resume point, "Play from start", a file opened again after it ended | Pass |
| `insertItems` on the list | Fail: "Not yet implemented" in the backend, and the hub's list stays as it was |
| `insertItem` at the end of the list | Fail: "index is out of valid range". `addItems` is used there |
| "Add to play queue", then "Insert next" for two selected videos, on one video playing as audio | Pass: the queue reads current, the two, the one added; media-hub plays them in that order. A message above the mini-player says what was added |
| The item menu has "Insert next" and "Add to play queue" after "Play as audio"; the selection bar has a queue button | Pass (layout) |

### By hand

| Check | Result |
|---|---|
| A queue played as audio moves on with the screen off, cable unplugged | Still to do |
| "Insert next" and "Add to play queue" by touch, from the menu and from a selection | Still to do |
| "Playback action" steps through its four choices, and a tap then adds to the queue | Still to do |
| The break when a queue of several goes to audio and back: how long, and is it acceptable | Still to do |

## Audio player and mini-player, version 0.0.12

### Checked over adb, 7 October 2026

| Check | Result |
|---|---|
| `open` on `~/Music/gemplayer-test/test-1.mp3` opens the audio player, not the video player: title "MP3 440 Hz", artist "GemPlayer", the headphones in place of a cover | Pass. The library offers `image://albumart/...` for this file, which is not used (D13) |
| `tapseek forward` moves 10 s on and shows "+10 s" on the right of the cover | Pass |
| `back` leaves it playing, with the bar above the tabs: cover, title, artist, pause, progress along the top | Pass |
| "Play all" on a video, then `audio`: the video's picture as the cover, the video and queue buttons in the header, the queue's list | Pass |
| The queue moves on by itself behind the library, and `next` does; the bar shows the new title and picture | Pass |
| `expand` opens the full player; `video` returns to the picture | Pass |
| `stop` ends playback, empties the queue and takes the bar away | Pass |
| No QML warnings in the log | Pass |

### By hand

| Check | Result |
|---|---|
| Double tap on the left and right quarter of the cover area: 10 s back and forward, adding up; in the middle: pause and play | Pass (Yenis, 7 October 2026) |
| Swipe sideways on the cover: the overlay shows the jump and the target, the seek happens on release | Pass (Yenis) |
| Rewind and forward buttons: 10 s on a tap, 20 s when held | The tap works. Held, it moved about 15 s and felt uneven: the hold was removed |
| Mini-player: a tap opens the player; swipe left is next, swipe right previous (or back to the start, 5 s in); the bar follows the finger | Pass (Yenis) |
| Holding play stops, on the bar and in the player | Fail: holding did nothing. The hold was removed; a cross on the mini-player stops instead |
| The cross on the mini-player stops playback and takes the bar away | Still to do |
| A music file opened from the file manager | Still to do |
| Audio carries on with the screen off, from the mini-player state | Pass (Yenis, 7 October 2026) |
| Audio carries on under another app, from the mini-player state | Still to do |

## Information page, version 0.0.11

### Checked over adb, 3 October 2026

| Check | Result |
|---|---|
| "Information" in a video's menu, between "Play as audio" and the favourite switch | Pass (layout) |
| The page for `long-35min`: picture with its progress bar, "Resume", length 35:00, SD, MP4, file, folder, changed 2 October 2026 09:34, played up to 2:00 | Pass |
| File size against `ls -l`: 73.8 MB for the camera video of 73 807 820 bytes | Pass. The row was missing at first: the folder to list was worked out from a value that had not updated yet. Fixed |
| A video watched to the end shows a tick on its picture and "Play" | Pass |
| `back` closes the page | Pass |
| One video selected: an information button joins the bar, and opens the page | Pass |

### By hand

| Check | Result |
|---|---|
| Information from the menu by touch; the header arrow and the back gesture close it | Still to do |
| Play or Resume on the page starts the video | Still to do |
| A long folder path or file name wraps and stays readable | Still to do |

## Groups made by hand, version 0.0.10

### Checked on the computer, 3 October 2026

The grouping rules in `qml/js/Library.js`, run under node with made-up names.

| Check | Result |
|---|---|
| Two videos put into a group by hand show as that group, under its name; the groups by name around them are unchanged | Pass |
| A video kept on its own leaves its group by name; the others stay grouped | Pass |
| The only video of a group shows as a video | Pass |
| A video pointing at a group that no longer exists falls back to grouping by name | Pass |

### Checked over adb, 3 October 2026

| Check | Result |
|---|---|
| New group "Codecs" from two selected videos: one entry, 2 videos, both thumbnails | Pass |
| Adding a video to `series-episode`, a group that formed by name: 3 videos | Pass |
| Renaming it to "My series" | Pass |
| A group's menu: Play all, Mark all as played, Rename video group, Ungroup | Pass (layout) |
| A video's menu inside a group has "Remove from video group"; on its own after ungrouping, "Regroup automatically" | Pass (layout) |
| Removing a video from a group of three leaves the group open with two; removing another returns to the top, the group being gone | Pass. At first the page stayed on the emptied group; fixed |
| Ungroup: the three videos stand alone and do not fall back into a group by name | Pass |
| Regroup automatically: `series-episode` forms again | Pass |
| The rename dialog, with its text selected, sits above the keyboard | Pass (layout) |
| "Add to video group" from a selection lists "New group" and the groups there are | Pass (layout) |

### By hand

| Check | Result |
|---|---|
| Select two videos → folder button → New group → type a name → Create | Still to do |
| Rename a group by typing; Cancel and a tap beside the dialog leave it unchanged | Still to do |
| Add one video to an existing group from its menu | Still to do |
| Ungroup, then Regroup automatically, from the menus | Still to do |

## Multiple selection, version 0.0.9

### Checked over adb, 3 October 2026

Selecting was driven through the function a long press calls.

| Check | Result |
|---|---|
| Two videos and a group selected: "3 selected" in the header's place, each marked, in grid and list; the three dots are gone | Pass |
| A tap on a selected entry takes it out | Pass |
| The star adds the selection to the favourites, the group's two videos included; with all of them favourites it removes them | Pass |
| Play: the queue is the four selected videos, in the order shown | Pass |
| Play as audio: the audio page, with a queue of the selection | Pass |
| Back ends a selection | Pass |
| Playback action "Play all": a tap on a video plays everything shown from it on; back on "Play", a tap plays that one | Pass |

### By hand

| Check | Result |
|---|---|
| A long press selects, and does not also open the video | Still to do |
| The cross, the three buttons of the bar, and the back gesture | Still to do |
| A long press while the list is being scrolled does nothing | Still to do |
| Display settings → Playback action switches between Play and Play all | Still to do |

## Queue and item menu, version 0.0.8

### Checked over adb, 3 October 2026

| Check | Result |
|---|---|
| A video's menu: Play, Play from start (only with a resume point), Play all, Play as audio, Mark as played, Add to favourites | Pass (layout) |
| A folder's menu: Play all, Mark all as played | Pass (layout) |
| Play all from `series-episode-1`: the queue is all 12 videos, at 8 of 12 | Pass |
| The next video starts by itself when one ends | Pass: `series-episode-2` followed after the 10 s clip |
| Next; previous within 5 s goes to the video before; previous later restarts the video | Pass |
| The queue's list over the video, the playing one marked; jumping to the last entry | Pass |
| The last video ends: back to the library, queue empty | Pass |
| Play as audio from the menu opens the audio page | Pass |
| Play resumes (`long-35min` at 2:00); Play from start begins at 0, with the file still loaded and after another file | Pass. It failed at first: a file still loaded played on from where it was paused. Fixed by seeking to 0 once it has started |
| Mark as played puts the tick on; Mark as not played takes it off | Pass |
| Play all on a folder plays its videos | Pass |
| Subtitles are no longer drawn over an open menu | Pass |

### By hand, 3 October 2026

Tried by Yenis on the phone and reported as working; the rows are what was
set out to be tried, not a record of each one.

| Check | Result |
|---|---|
| Previous, next and the queue button by touch; a tap in the queue's list | Pass |
| The three dots on a folder and a group | Pass |
| Play all, then turn the phone: the next video keeps the rotation and picture size | Not reported |
| A queue played as audio with the screen off stops after the current video (the known limit) | Not reported |

## Video library, version 0.0.7

### Checked on the computer, 3 October 2026

The grouping rules in `qml/js/Library.js`, run under node with made-up names.

| Check | Result |
|---|---|
| "The Office S01E01" and "office s01e02" form one group; a leading "the" and case are ignored | Pass |
| "Holiday - 01" and "Holiday - 02" form the group "Holiday" | Pass |
| A name on its own stays a video | Pass |
| By folder: one entry per folder, in order of name, with the right counts | Pass |

### Checked over adb, 3 October 2026

| Check | Result |
|---|---|
| By name (the default): `series-episode-1` and `-2` show as "series-episode", 2 videos, with both thumbnails; everything else stays a video | Pass, in grid and list |
| Opening the group shows its two videos, with its name and a back arrow in the header; `back` returns | Pass |
| By folder: `camera.ubports` (1 video) and `gemplayer-test` (11 videos), each with a folder picture; the first carries a tick, its one video being seen | Pass |
| Opening a folder lists its videos in the chosen order | Pass |
| Do not group: all twelve videos | Pass |
| The grouping is kept across a restart; the app starts at the top level | Pass |

### By hand, 3 October 2026

Tried by Yenis on the phone and reported as working; the rows are what was
set out to be tried, not a record of each one.

| Check | Result |
|---|---|
| Display settings → Group videos → each of the three choices | Pass |
| Tapping a group and a folder opens it; the header arrow and the back gesture lead out | Pass |
| Filter and "only favourites" while grouped, and inside a group | Pass |

## Video library, version 0.0.6

### Checked over adb, 3 October 2026

| Check | Result |
|---|---|
| Default order: by name, A to Z, ignoring case | Pass |
| Length, longest first; recently added, oldest first; file name, Z to A | Pass: each list read back in the right order |
| Filter "720" leaves the three files with it in their name; "zzz" leaves none and says so | Pass |
| A favourite gets a star on its thumbnail, in grid and list | Pass |
| "Show only favourites" leaves the two favourites | Pass |
| Display settings sheet and a video's menu open over the whole screen, tab bar included | Pass (layout) |
| The order is kept across a restart | Pass |
| Keyboard: opens with the filter (883 px high); gone after `hidekeyboard`, after opening the display settings, and after switching tab | Pass |

### By hand, 3 October 2026

| Check | Result |
|---|---|
| The magnifying glass opens the filter and the keyboard; typing narrows the list | Pass |
| Display settings, the three dots, favourites | Pass |
| Putting the keyboard away | **Failed**: once open, it stayed until the filter was closed. Fixed in the same version: the enter key, a touch on the list, a menu, a video or another tab now put it away. To be tried by hand again |

## Video library, version 0.0.5

### Checked over adb, 3 October 2026

| Check | Result |
|---|---|
| Grid: two columns upright, each card with thumbnail, title and length | Pass |
| Resolution labels: 4K, 1080p, 720p and SD on the right files; the portrait file reads 1080p | Pass |
| Tick on files watched to the end; bar on files left part-way (`sidecar`, `long-35min`) | Pass |
| List: small thumbnail, title, "length • resolution", the same tick and bar | Pass |
| The choice of grid or list is kept across a restart | Pass |
| A card updates when its video was just played | Pass: `hevc-1080p` gained its tick on returning from the player |

A 20 s file never shows a bar: the store counts the first 10 s as not started
and the last 10 s as finished. That is Phase 1's rule, not the library's.

### By hand

| Check | Result |
|---|---|
| The button at the top right switches between grid and list (from 0.0.6: "Display in list" in the display settings) | Still to do |
| Tapping a card and a row opens the video | Still to do |
| Scrolling both views | Still to do |
| The grid with the phone on its side (expected: four columns, if the system rotates the app) | Still to do |

## App shell, version 0.0.4

### Checked over adb, 3 October 2026

| Check | Result |
|---|---|
| Each of the five tabs shows its page, and the bar marks the one shown | Pass |
| The Video tab lists the videos as before | Pass |
| A video opens over the tabs, plays, and "back" returns to the tab it was opened from | Pass |
| More → Diagnostics opens the spike page; closing it returns to More | Pass |

### By hand

| Check | Result |
|---|---|
| Tapping each tab in the bar | Still to do |
| Tapping a video in the list, and More → Diagnostics | Still to do |

## Player, version 0.0.3

### Checked over adb, 2 October 2026

| Check | Result |
|---|---|
| Volume swipe (driven through the same function) | Pass: the system volume went 0.54 → 0.44 → 0.54 |
| Brightness swipe | Pass: the backlight went 1.0 → 0.6; back to 1.0 on leaving the player, 0.6 again on return |
| Subtitles: `sidecar.srt` found and shown, in time, above the controls | Pass |
| Menu with all entries; keypad for "Jump to time"; sleep picker upright and on its side | Pass (layout) |
| Sleep timer: set to 5 s, playback paused when it ran out | Pass |
| A-B repeat: playback returned to the start mark after passing the end mark | Pass; the loop begins at the keyframe before A |
| Bookmarks: two added, listed, marked on the timeline | Pass |
| Video information | Pass |
| Screenshot: `GemPlayer sidecar 0-16.png` in Pictures | Pass |
| Labels for sleep timer, A-B repeat and subtitle delay | Pass |

### Checked by hand, 2 October 2026

| Check | Result |
|---|---|
| Volume swipe on a video with real sound | Pass |
| Brightness swipe: the screen itself dims, and recovers on leaving the player | Pass |
| Jump to time: `1`, `:30`, OK | Pass |
| Sleep timer: `1`, OK; paused after a minute | Pass |
| Bookmarks: add, tap, hold to remove | Pass |
| A-B repeat | Pass |
| Subtitles of `sidecar`, and the subtitles button | Pass |
| Screenshot appears in the Gallery | Not reported |
| A real film with its own `.srt` | Still to do |
| A hardware keyboard | Still to do |

## Player, version 0.0.2

### Checked over adb, 2 October 2026

Driven through `qml/dev/Remote.qml`, with screenshots the app takes of itself
and the system's media interface as the witness.

| Check | Result |
|---|---|
| The list shows every video with thumbnail, length and size | Pass |
| A video opens and plays, fullscreen | Pass |
| Layout in portrait and turned to landscape | Pass |
| Menu, list of picture sizes, "Fit screen", 4:3 | Pass |
| Seek from the timeline | Pass; lands on the keyframe before, as the backend does |
| Play as audio: page changes, playback uninterrupted, continues behind another app | Pass |
| Play as video: picture is back, playback uninterrupted | Pass |
| A video pauses when another app comes to the front | Pass |
| End of file: back to the list, file marked "seen" | Pass |
| Opening the same file again after it ended | Pass |
| Resume: left at 0:30, reopened, continues from there | Pass (from the keyframe before) |

### Checked by hand

Gestures and the orientation sensor cannot be driven remotely. All of these
passed on 2 October 2026, except the volume swipe as noted.

| Check | Look for |
|---|---|
| Tap | Controls appear and go; they leave by themselves after 4 s while playing |
| Double tap, left and right quarter | Skips 10 s; repeated taps add up and the total shows on that side |
| Double tap, middle | Pauses and plays |
| Swipe sideways | A message like `+0:42 (12:10)` follows the finger; the jump happens on release |
| Swipe up and down, right half | Volume bar. **Failed in 0.0.2**: the level showed but the sound did not change; fixed in 0.0.3 |
| Swipe up and down, left half | The picture dims and brightens |
| Pinch out, pinch in | "Fit screen", then back |
| Turn the phone on its side, both ways | The player turns with it, the right way up both times |
| Rotate button | Holds the orientation; again releases it |
| Menu → Lock | Controls gone; a tap shows "Slide to unlock"; sliding unlocks |
| Power button during a video | It is paused when the phone is unlocked again |
| Menu → Play as audio, then power button | It keeps playing |

## Spike, version 0.0.1

## Test device

| Device | OS | Date |
|---|---|---|
| Google Pixel 3a (`sargo`, arm64) | 24.04-1.x stable, tag `24.04-1.4` | 2 October 2026 |

## Test set

Synthetic files: a test pattern with a running timestamp, and quiet tones.
They live on the phone in `~/Videos/gemplayer-test/` and
`~/Music/gemplayer-test/`, and can be deleted when the spike is over.

| File | What it is for |
|---|---|
| `h264-1080p30.mp4` | 60 s, 1080p, H.264 + AAC. The smoothness reference (S1) |
| `h264-opus-720p.mkv`, `hevc-1080p.mp4`, `vp9-720p.webm`, `av1-720p.mp4` | Codecs and containers (S14) |
| `portrait-1080x1920.mp4` | A portrait video, for aspect handling |
| `series-episode-1.mp4`, `series-episode-2.mp4` | Two names that begin alike, for "Group by name" |
| `sidecar.mp4` + `sidecar.srt` | A subtitle file beside a video (S10); also used for the seek and speed checks |
| `multi-track.mkv` | Two audio tracks (English 440 Hz, German 880 Hz), two subtitle tracks, three chapters (S16) |
| `long-35min.mp4` | 35 minutes with a short beep every 10 s, for the pocket test (S6) |
| `test-1.mp3` ... `test-5.m4a` | MP3, FLAC, Opus, Vorbis, AAC, tagged as one album (S14) |

## Running the spike

### Automatic part

From version 0.0.11 the automatic run no longer includes S13, the network
streams: the question was answered in run 2, and the app is to hold no
network address of its own (D13 in [PLAN.md](PLAN.md)).

1. Unlock the phone and keep the screen on.
2. Launch **GemPlayer**. After two seconds it starts the automatic run, which
   takes about two minutes and plays short stretches of every file. The header
   shows the step it is on; the **Auto** tab shows the log.
3. Leave the app in the foreground until the log says `AUTO done`.

Every finding is also written to the app log as a line starting with `SPIKE`:

```bash
adb shell "journalctl --user --no-pager | grep SPIKE"
```

The switch beside "Run automatic tests" turns the run on launch off, for the
manual checks below.

### Manual part

These need hands and eyes. The **Player** tab plays any file of the test set;
the **Library** tab plays a queue of songs from the phone's own library.

| # | Do this | Look for |
|---|---|---|
| S1 | Player → `h264-1080p30.mp4` | Is the motion smooth, with no stutter or tearing? Do the volume keys change the loudness? |
| S16 | Player → `multi-track.mkv` | Is the tone low (English track) or high (German track)? Do subtitles appear on the picture? |
| S9 | Turn the phone sideways. System → the orientation buttons | Does the page rotate? Do the buttons lock or change it? |
| S8 | Player → `long-35min.mp4`, do not touch the phone past the screen timeout | Does the screen stay on? |
| S6 | **Unplug the USB cable** (a phone on a cable does not suspend). Player → `long-35min.mp4`, press the power button, listen for two minutes | Does the beep, every 10 s, carry on? |
| S6 | If it stopped: unlock, tap "Keep-alive" so it reads "on", play again, press the power button, listen for two minutes | Does it carry on now? If so, repeat for 30 minutes in a pocket |
| S5, S11 | Library → "Play a queue of 4 library songs", press the power button | Does music continue? Does the lock screen show the song with working controls? And the sound indicator in the top panel? Headset buttons, if one is at hand |
| S12 | File manager → a video → open with GemPlayer | Does GemPlayer open, and does the log show a `RESULT S12` line? |

The spike logs its state every two seconds, so the timings can be read from
the journal after the cable is plugged in again.

## Results

### Run 1: confined, 2 October 2026

Version 0.0.1 with the policy groups `audio`, `video`, `content_exchange`,
`keep-display-on`, `networking`, `music_files_read`, `video_files_read`.
Automatic part only, run three times (the third with Wi-Fi on, for S13); the manual part waits for the confinement decision (D12
in [PLAN.md](PLAN.md)), because the confined app cannot play the test set.

| # | Question | Result |
|---|---|---|
| S1 | Plays a local file under confinement? | **Only from the app's own folders.** A file in `~/.cache/gemplayer.yenis/` plays: started in 1.6 s, normal speed, seekable. Every file in `~/Videos` and `~/Music` is refused, see below |
| S2 | Reading media folders directly | **Listing works, playing does not.** `~/Videos` and `~/Music` list with all their files. Home, Documents, Downloads and `/media` list nothing. `click-review` flags `music_files_read` and `video_files_read` as reserved |
| S3 | Media library | **Fail.** All four music models are empty and the video query returns nothing, although the phone has 183 songs |
| S4 | Thumbnails and album art | **Video thumbnail: pass** (256x145 for a file in `~/Videos`). Album art not tested: no album could be read |
| S7 | Playback speed | Asked for 2.0, the property read back 1 and the measured speed was 1.00. To be repeated in a clean run |
| S8 | Fullscreen | **Pass.** The window grows from 1080x2145 to 1080x2220 and covers the top panel. Keeping the display on is not yet checked by eye |
| S10 | Reading a `.srt` beside the video | **Pass.** 664 characters read from `~/Videos/gemplayer-test/sidecar.srt` |
| S13 | Network streams | **HLS: pass**, confined too: started in 3.8 s, seekable. Plain MP4: see run 2 |
| S15 | QML modules | **Pass**, 14 of 15 present. Missing: `org.nemomobile.mpris 1.0` |
| - | Settings and database | **Pass.** Launch counter and SQLite rows both went 1 → 2 across launches |
| - | Audio role | Music and video roles can both be set and read back |
| S5, S6, S6b, S9, S11, S12, S14, S16 | | Not answered yet: they need files that play |

### Why playback and the library fail

Neither failure is an AppArmor denial, and no policy group changes it. Two
system services decide for themselves who may use them, by package name
**[source]**, confirmed by the error text on the device:

| Service | Rule in its source | Effect on GemPlayer |
|---|---|---|
| media-hub, `src/service/apparmor/lomiri.cpp` | A confined app may open: files under its own `~/.local/share/<package>/` and `~/.cache/<package>/`, files in its own install folder, and network streams. Files under `Music/`, `Videos/` and `/media` only if the package is `music.ubports` or `gallery.ubports` | `Client is not allowed to access: file:///home/phablet/Videos/...` for every file of the test set |
| mediascanner, `src/ms-dbus/service-skeleton.cc` | A confined app may query the library only if it is `music.ubports`, and then only audio. Nobody confined may query video | Empty models, empty video query |

An unconfined app passes both checks. Both pieces of code carry a note that
the list of names is a stand-in until a permission store exists.

### Run 2: unconfined, 2 October 2026

The same build with the `unconfined` template (D12). Automatic part.

| # | Question | Result |
|---|---|---|
| S1 | Plays a local file? | **Pass**, from `~/Videos` and `~/Music`. 1080p H.264 starts in 1.2 s at normal speed. Smoothness still to be judged by eye |
| S2 | Reading folders directly | **Pass.** The home folder lists as well. No SD card in the phone, so `/media` is untested |
| S3 | Media library | **Pass.** 187 songs, 27 albums, 34 artists, 11 genres. `query("", VideoMedia)` lists all 10 videos, each with width, height, duration and a thumbnail address. A text query narrows it (1 result for "sidecar") |
| S4 | Thumbnails and album art | **Video thumbnail: pass.** Album art: the first album in the library has no artist or album tag and its art fails to load; to be repeated with a tagged album |
| S6b | Seeking | **Works, with a caveat.** A seek lands on the keyframe before the requested time, not on the time itself. The test file has a keyframe every 8.3 s: asking for 10.0 s gave 8.3 s, 30.0 s gave 25.0 s, 40.0 s gave 33.3 s, 5.0 s gave 0. So a seek can land up to one keyframe interval early. Playback resumes 0.4 to 1.5 s after the call. Seeking while paused works the same way. Same figures in two runs |
| S6b | Position updates | 10 per second with `notifyInterval: 100` |
| S7 | Playback speed | **Confirmed absent.** Asked for 2.0, the property read back 1 and the measured speed was 1.00 |
| S8 | Fullscreen | **Pass**, as in run 1 |
| S10 | Reading a `.srt` | **Pass**, as in run 1 |
| S13 | Network streams | **Pass.** HLS and a plain MP4 over `https` both start in 1.6 s and are seekable. **A missing file (HTTP 404) raises no error**: the player just never starts, so the app needs its own time limit for streams. The MP4 that failed in run 1 was such a 404, a wrong address in the test |
| S14 | Formats | **All pass.** Video: H.264, HEVC, VP9 and AV1, in MP4, MKV and WebM, up to 1080p; a portrait file too. Audio: MP3, FLAC, Opus, Vorbis, AAC. Video starts in 0.5 to 1.2 s, audio in 0.25 to 0.35 s |
| S15 | QML modules | As in run 1: only `org.nemomobile.mpris` is missing |
| S16 | Tracks, subtitles, chapters | **Nothing is exposed.** The file with two audio tracks, two subtitle tracks and three chapters plays, but `metaData` is empty: no track list, no chapters, no codec, no resolution. Which audio track is heard and whether embedded subtitles are drawn is a manual check |
| S16 | Capturing a frame | **Pass.** `grabToImage` on the video surface returned the real picture, 1080x607, and saved it as a PNG |
| - | Queue | **Pass.** A `Playlist` of three files plays, `next()` moves on and keeps playing. Loop mode reads back; random mode did not read back |
| - | Volume | After setting 0.3 the property read back 0.01. Whether the sound level changed is a manual check |
| S5, S6, S9, S11, S12 | | See run 3 and the manual part |

### Run 3: driven over adb, 2 October 2026

The spike takes commands from a file, so these checks were run from the
computer: the app was sent behind the Calculator through the URL dispatcher,
and the system's own media interface (MPRIS, `org.mpris.MediaPlayer2.MediaHub`)
was read while GemPlayer was suspended.

| # | Question | Result |
|---|---|---|
| S5 | Audio under another app | **Pass.** A queue of three 30 s files kept playing with GemPlayer suspended, and moved to the second and third file by itself. media-hub runs the queue, not the app |
| S5 | Video under another app | **It keeps playing.** media-hub does not pause a video when its app is suspended: the position advanced 7 → 15 → 26 s behind the Calculator. Pausing when the app is left (D10) is therefore the app's job |
| S6 | Play as audio: same player, picture hidden | **Pass.** Playback is unaffected by hiding the `VideoOutput`, and continues under another app |
| S6 | Play as audio: same player, video surface detached | **Pass.** Setting `VideoOutput.source` to null and back does not interrupt playback. Whether the picture returns cleanly is still to be seen by eye |
| S6 | Play as audio: a second player without a surface | **Fail, and not needed.** A second `MediaPlayer` given the same file never started while the first was paused |
| S6 | With the screen off | **Open, needs the power button.** media-hub holds the display on for a file with a picture, but asks the system to stay awake only for audio files, so the phone may suspend once the screen is off. A candidate fix is in the spike: a second player looping a silent audio file ("Keep-alive"). It was shown to run alongside the video and to make media-hub request the stay-awake lock |
| - | Two players at once | **Pass.** A video and an audio queue from the same app play at the same time |
| S11 | System controls without an MPRIS module | **Pass at the interface.** media-hub publishes the playing item over MPRIS with status, position, title, album and length, and `Pause`, `Play` and `Next` sent to it took effect. What the sound indicator and lock screen show is still to be seen by eye |

### Run 4: manual part, 2 October 2026

Done by hand on the phone; timings read from the journal afterwards.

| # | Question | Result |
|---|---|---|
| S1 | Is 1080p H.264 smooth? | **Pass.** Smooth, and the volume keys change the loudness |
| S16 | A file with two audio tracks and embedded subtitles | The first audio track plays; there is no way to pick the other. **No subtitles are drawn**: media-hub switches the text stream off **[source]**. It does see both audio streams (its log says "1 video streams and 2 audio streams") but does not pass that on |
| S9 | Rotation | The system rotates the app. With the phone's rotation lock on, it offers its rotate button first, then the window becomes 2220x1005. Whether the app can force landscape by itself was not tried; the player will rotate its own content instead |
| S6 | Video with the screen off | **Kept playing for 53 s**, cable unplugged: position and clock advanced by the same 52.8 s. But the keep-alive was on during this run, and 53 s may be too short for the phone to suspend. **To be repeated**, longer, with the keep-alive off and then on |
| S5 | Music with the screen off | **Pass.** A library queue played on for 39 s behind the lock screen |
| S11 | Lock screen and sound indicator | The lock screen shows nothing; it has no media controls of its own. The sound indicator has a player section with play, previous and next, wired to media-hub, but it is labelled "Media Player" with the stock app's icon: media-hub reports itself as `lomiri-mediaplayer-app` and the indicator only lists that name. Showing "GemPlayer" there would take an MPRIS service of our own, which is compiled code |
| S12 | Open with, from the file manager | **Pass.** The file arrives as `~/.cache/gemplayer.yenis/HubIncoming/2/av1-720p.mp4`, and it is a hard link to the original (same inode, link count 2), so it takes no extra space. The spike only logs it; playing it is the player's job |

### Run 5: screen off, 2 October 2026

`long-35min.mp4` playing as a normal video, cable unplugged, power button
pressed. The app logs position and clock when it is suspended and when it
wakes; if playback had stopped or the phone had slept, the two would differ.

| Run | Keep-alive | Screen off for | Position advanced by | Verdict |
|---|---|---|---|---|
| 1 | Off | 3 min 38.8 s | 3 min 38.8 s | **Played throughout.** For the first 62 s a stray audio queue was also playing (see below), which holds the stay-awake lock; the remaining 2 min 45 s had no lock from media-hub and the video still played |
| 2 | On | 10 min 20.6 s | 10 min 20.6 s | **Played throughout** |

So on this phone a video plays on with the screen off without help, at least
for several minutes. S6 is a pass, and the silent keep-alive stays in reserve.
The 30-minute pocket test is left for the battle test, with the real player.
It also means a video does not stop by itself when the screen goes off: that
is the app's job too (D10).

### Other observations

- With no media loaded, `MediaPlayer.position` reads a large negative number
  (-140462611), not 0. The player must not show or store it.
- `hasAudio` reads `false` for every video file, although each has an audio
  track; `hasVideo` is right. `metaData` is always empty. Width, height and
  duration come from the media library instead.
- Volume: after setting 0.3 the property read back 0.01. To be looked at.
- Position updates arrive about 10 times a second with `notifyInterval: 100`.
- Clearing `MediaPlayer.source` raises an error ("Failed to open uri"); the
  player should stop instead of clearing.
- After `stop()`, calling `play()` on the same source does not play: the state
  goes to playing, then paused, and stays there. The source has to be set
  again. The player should pause and seek to 0 instead of stopping.
- A second `MediaPlayer` that had been stopped started playing again by itself
  at the moment another one was started (run 5). Together with the failed
  second-player test in run 3: the app uses exactly one `MediaPlayer`.
- media-hub's MPRIS metadata carries what `MediaPlayer.metaData` does not:
  audio codec, container format, album. QML cannot read D-Bus, so using it
  would take compiled code.
- The system bus offers `com.canonical.Unity.Screen.setUserBrightness`, a real
  brightness control. Again D-Bus, so compiled code.
- The library reports 1920x1088 and 640x368 for files that are 1920x1080 and
  640x360: coded size, rounded up to a multiple of 16. Aspect ratio must not be
  computed from these without care.
