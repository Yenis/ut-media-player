# Testing GemPlayer on a device

This page records what has been checked on a device, and how. The first part
is the information page (version 0.0.11), groups made by hand (version 0.0.10), multiple selection (version 0.0.9), the queue and item menu (version 0.0.8), the video library (versions 0.0.5
to 0.0.7), the app shell (version 0.0.4) and the player (versions 0.0.2 and 0.0.3);
the rest is the Phase 0 spike from
[PLAN.md](PLAN.md), a diagnostics page that found out what Ubuntu Touch offers
a QML-only media player. The spike is still in the app, under More →
Diagnostics.

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
