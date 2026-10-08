# Testing GemPlayer on a device

This page records what has been checked on a device, and how. The first part
is multiple selection for music (version 0.0.22), a track's information and "go to" (version 0.0.21), sorting and favourites for music (version 0.0.20), the music filter and blurred cover (version 0.0.19), the kept queue (version 0.0.18), the audio player's volume and brightness swipes (version 0.0.17), its menu (version 0.0.16), shuffle and repeat (version 0.0.15), the music library (version 0.0.14), the queue in the background (version 0.0.13), the audio player and mini-player (version 0.0.12), the information page (version 0.0.11), groups made by hand (version 0.0.10), multiple selection (version 0.0.9), the queue and item menu (version 0.0.8), the video library (versions 0.0.5
to 0.0.7), the app shell (version 0.0.4) and the player (versions 0.0.2 and 0.0.3);
the rest is the Phase 0 spike from
[PLAN.md](PLAN.md), a diagnostics page that found out what Ubuntu Touch offers
a QML-only media player. The spike is still in the app, under More →
Diagnostics.

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
