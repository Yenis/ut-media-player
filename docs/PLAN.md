# GemPlayer - a VLC-style media player for Ubuntu Touch - plan

Status: **Milestone 1 reached on 2 October 2026: a working video player**
(version 0.0.3). Phases 0 and 1 are done. Phase 2 is under way: the app shell
with VLC's five tabs is in (version 0.0.4), the video library is next. Target device is the
Pixel 3a on Ubuntu Touch 24.04-1.x (tag `24.04-1.4`), the same one GemTicker
was verified on.

## Milestone 1 - where things stand

One day's work, from an empty folder to a player that runs on the phone.

| | |
|---|---|
| **Works, checked by hand on the Pixel 3a** | Video list with thumbnails; playback of H.264, HEVC, VP9 and AV1; VLC's gestures (tap, double tap, swipe seek, system volume, real brightness, pinch); twelve picture sizes; lock; own rotation; resume; play as audio and back; background and screen-off playback; sleep timer; jump to time; A-B repeat; bookmarks; external subtitles; screenshot; opening files from other apps |
| **Known and settled** | The app is unconfined (D12). No playback speed, track selection or embedded subtitles on this backend. Seeks land on the keyframe before their target. System media controls work but carry the name "Media Player" |
| **Still open from Phase 1** | A check with a real film and real subtitles. Decisions on the Discuss items in the table at the end of [Phase 1](#phase-1---video-player) |
| **To pick up next** | Phase 2. Read [DEVELOPING.md](DEVELOPING.md) first: it has the build loop, the remote control for checking changes on the phone, and the rules the backend imposes |

What the first day established, in the order it was found:

1. The VLC clone was surveyed into [VLC-FEATURES.md](VLC-FEATURES.md), with a
   verdict per feature.
2. A confined app cannot play the user's media on Ubuntu Touch today; the app
   went unconfined (D12).
3. The spike answered every platform question ([TESTING.md](TESTING.md)).
   The surprises: playback runs in a system service and outlives the app being
   frozen, which makes "play as audio" trivial and a sleep timer hard; and the
   backend's volume control is a stub.
4. The player was built in two steps, 0.0.2 and 0.0.3, each checked over adb
   and then by hand.

Goal: every feature of VLC for Android, where feasible, on top of the media
stack Ubuntu Touch already ships. This is a new QML app modelled on VLC's UI,
not a port of its code. Features the system backend cannot deliver are not
dropped in advance: each is discussed when the work reaches it (D2).

## Where things are

| What | Where |
|---|---|
| This project | `~/ut-media-player/` - work happens from this folder |
| VLC for Android source, for reference | `vlc-android/` inside this folder, cloned from `https://github.com/videolan/vlc-android` at commit `e0d3fe77b` (version 3.7.2 Beta 2) |
| What VLC does and what each feature needs here | [VLC-FEATURES.md](VLC-FEATURES.md) |
| How to build, drive the app on the phone, and the backend's rules | [DEVELOPING.md](DEVELOPING.md) |
| What was checked on the device, and how | [TESTING.md](TESTING.md) |
| GemTicker, the source of the reusable components and the build setup | `~/ut-crypto-dashboard/` |
| GemTicker's plan, for the conventions this one follows | `~/ut-crypto-dashboard/docs/ROLLOUT.md` |

Rules for the reference clone:

- It is read, never built, and never edited.
- It stays out of this project's git history (`.gitignore`) and out of the
  click package.
- It is the authority on how a VLC feature behaves: gesture zones and
  thresholds, skip lengths, the order of aspect modes, what the resume prompt
  says, how the queue reacts to shuffle. Read the code before building the
  feature, and name the file in the phase notes.
- Its Android plumbing (services, JNI, the media library bindings, Gradle) is
  ignored; the Ubuntu Touch side comes from the table in
  [What the platform gives us](#what-the-platform-gives-us).
- The libVLC bindings (`libvlcjni/`) are not part of the clone; VLC's build
  fetches them. What is defined there cannot be read here.

Facts are marked:

- **[source]** - read in the upstream UBports source on 2 October 2026, not yet
  seen on a device.
- **[vlc]** - read in the `vlc-android` clone.
- **[device]** - checked on the Pixel 3a.
- **[verify]** - still an assumption. Phase 0 exists to turn these into
  **[device]**.

---

## Decisions

### Made

| # | Decision | Outcome |
|---|---|---|
| D1 | Playback engine | **The system backend** (QtMultimedia over media-hub), as the stock Music and Media Player apps use. This is the engine the app is built on; whether a second route is added for a feature it cannot do is a D2 discussion |
| D2 | Scope | **Every VLC for Android feature, where feasible** (changed 2 October 2026; it was "UI features only, drop what the backend cannot do"). A feature that is very hard on Ubuntu Touch is not dropped in advance: when the work reaches it, we discuss whether it is worth trying. [VLC-FEATURES.md](VLC-FEATURES.md) marks these as "Discuss" |
| D3 | Rule for adopting an API | Only what is **confirmed on the device** in Phase 0 goes into the build phases |
| D4 | Name and identity | **GemPlayer**, under the GemsTech brand. Organization and application name are both `gemplayer.yenis`. No app of that name is on the OpenStore (checked by Yenis, 2 October 2026). Own icon; never the VLC name or cone, which are VideoLAN trademarks |
| D5 | Licence and reuse | **GPL-3.0 or later, as GemTicker** (decided 2 October 2026); the text is in `LICENSE`. VLC for Android is "GPLv2 or later" **[vlc]** (`README.md`, `COPYING`, file headers), which GPLv3 can absorb, so behaviour, layouts, strings and icons may be adapted from the clone as long as the README credits VLC for Android and adapted files keep their copyright notices. The VLC name and cone stay off limits (D4). This also gives the OpenStore listing the licence and public source link it needs |
| D6 | UI toolkit | **Plain QtQuick with our own components and theme**, reusing GemTicker's (`Theme`, `IconButton`, `Toggle`, `SettingRow`, `PageHeader`, `SectionLabel`, `SegmentedChoice`, `TextButton`). Lomiri only for grid units, Content Hub and thumbnails |
| D7 | Packaging | **Pure-QML click**, one package for every architecture. The spike found every module the plan needs on the device (S15), and system media controls work without a bundled MPRIS module. Compiled code comes back on the table only with a Discuss item that needs it (our own name in the sound indicator, real brightness, deleting files) |
| D8 | Order | **Video player first**: it is the larger gap, since the stock video app is a bare player with no library. Audio second |
| D9 | Distribution | **OpenStore, eventually.** First a self-installed click that is battle-tested on the Pixel 3a for a few weeks; the store submission follows and is not urgent. Store requirements shape choices from the start, see [Phase 6](#phase-6---openstore) |
| D10 | Background playback | **Audio plays while other apps are in use and while the screen is locked**, as the stock Music app does. **Video stops when the app leaves the foreground**, except through "Play as audio". This matches VLC's own default **[vlc]** |
| D11 | "Play as audio" | **Essential.** A playing video can be switched to audio-only and back; see [Play as audio](#play-as-audio) |
| D12 | Confinement | **Unconfined** (decided 2 October 2026), for development and the battle test. A confined app cannot play files from `~/Videos` or `~/Music` nor read the media library: media-hub and mediascanner allow that by package name only **[source, device]**. File access is kept behind one module so that a confined build with a Content Hub import library stays possible; a fix is proposed upstream. Which form goes to the OpenStore is decided in Phase 6. See [Confinement](#confinement) |

### Still open

None. Discuss items become decisions as the work reaches them.

### Confinement

Ubuntu Touch has no permission the app could ask for at run time here. What
exists, and why each does or does not help:

| Mechanism | What it is | Helps? |
|---|---|---|
| Policy groups | Declared in the package, fixed at install. We declare `video_files_read` and `music_files_read` | No. media-hub and mediascanner do not look at them |
| Trust prompts | The "Allow this app to use the camera?" dialogs | No. They exist for camera, microphone and location. Both services carry a note that they should use this for media one day; neither does |
| Content Hub | The user picks files in another app and hands them to ours | Yes, confined. See option A |
| Unconfined template | The package opts out of the sandbox | Yes. See option B |

The check sits inside the two services, so nothing in our package can satisfy
it. The options for D12:

| Option | What works | Cost |
|---|---|---|
| A. Stay confined, library by import | The user picks videos and music in the file manager and hands them over. Content Hub hard-links them into the app's folder, so files on the phone's own storage take no extra space **[source]**; files on an SD card are copied. From there they play, in the background too. Network streams work | The library holds only what was imported; new files do not appear by themselves. No artist, album or duration from the system library. Removing an import needs compiled code, since QML cannot delete a file |
| B. Go unconfined | Everything the plan assumes, as far as the remaining spike rows confirm it: both services accept an unconfined app | The package runs with the user's full rights instead of in a sandbox. In the OpenStore that means a manual review and a visible warning on the listing **[verify]**. Self-installing is unaffected |
| C. Change the platform | A confined app with the reserved groups could play and query, if media-hub and mediascanner asked AppArmor whether the app may read the file instead of comparing package names | A patch to two UBports components, their review, and an OTA release before any user has it. Not in our hands, but we can propose it |
| D. Play without media-hub | Qt's own GStreamer backend is on the device and would read files in-process | The app is suspended in the background, so no audio with the screen off. That breaks D10 and D11 |

Chosen: B, confirmed on the device, with file access kept behind one module so
that A remains possible, and C proposed upstream. Which of A or B goes to the
OpenStore is decided in Phase 6, when it is known whether C landed. D is ruled
out by D10 and D11.

---

## What the platform gives us

| Need | API | Status |
|---|---|---|
| Audio and video playback | `QtMultimedia` `MediaPlayer`, `VideoOutput` | **[device]** H.264, HEVC, VP9, AV1; MP3, FLAC, Opus, Vorbis, AAC |
| Seeking | `seek()` lands on the keyframe before the requested time, which can be several seconds early, and playback resumes 0.4 to 1.5 s later | **[device]** |
| Network streams | HLS and plain MP4 over `https` play and seek. A missing file raises no error; the player never starts | **[device]** |
| What the player tells us about a file | Duration, position, `hasVideo`. Not: tracks, chapters, codecs, resolution (`metaData` is empty), and `hasAudio` is wrong for videos | **[device]** |
| Capturing a video frame | `grabToImage` on the `VideoOutput` returns the real picture | **[device]** |
| Play queue | `QtMultimedia` `Playlist`, with sequential, loop, repeat-one and random modes | **[device]** items, `next()` and loop mode work; random mode did not read back |
| Queue saved across launches | `Playlist.save()`/`load()` do not work; the music app stores the queue itself | **[source]** |
| Music library | `MediaScanner 0.1`: `SongsModel`, `AlbumsModel`, `ArtistsModel`, `GenresModel`, `SongsSearchModel` | **[device]**, unconfined only |
| Video library | No video model. `MediaStore.query(text, VideoMedia)` lists every video for an empty text; each `MediaFile` carries title, duration, width, height and a thumbnail address | **[device]**, unconfined only |
| Confinement for video | Policy groups `video`, `audio`, `content_exchange` | **[source]** stock video app |
| Confinement for music | `audio`, `music_files_read`, `content_exchange`, `content_exchange_source`, `networking`, `keep-display-on`; read paths for `~/.cache/media-art/`, `~/.cache/mediascanner-2.0/` and `/media/*/*/` | **[source]** music app |
| Reading media folders directly | `video_files_read` and `music_files_read` cover `~/Videos`, `~/Music` and the `Videos` and `Music` folders of an SD card, nothing else. Both are reserved: `click-review` flags them for manual review. They allow listing, thumbnails and reading a `.srt`, but **not playback** | **[device]** |
| Who may play a file | media-hub decides by package name, not by policy group: only `music.ubports` and `gallery.ubports` may open files under `Music/`, `Videos/` and `/media`. Any confined app may open files in its own data and cache folders, and network streams. Unconfined apps may open anything | **[source]** media-hub, **[device]** |
| Who may read the library | mediascanner answers a confined app only if it is `music.ubports`, and only for audio. Unconfined apps get everything | **[source]** mediascanner, **[device]** |
| Deleting and renaming files | QML has no API for either, whatever the confinement allows. Needs compiled code plus the write groups `video_files`, `music_files` | **[source]**; a Discuss item |
| Keeping the display on | `QtSystemInfo 5.0` `ScreenSaver`, policy group `keep-display-on` | **[source]** music app. media-hub also holds the display on by itself while a video source plays |
| Calls and low battery | media-hub pauses multimedia sessions for a phone call and resumes them afterwards | **[source]** media-hub |
| Own database | `QtQuick.LocalStorage 2.0` (SQLite) | **[source]** music app; used here for resume points, history, playlists, bookmarks, favourites, groups |
| Audio role | The backend accepts Qt's music and video roles but maps both to the same media-hub "multimedia" role, so the role does not tell audio from video. media-hub itself decides by whether the stream has a picture | **[source]** `qtubuntu-media`, media-hub |
| System media controls | media-hub publishes the playing item over MPRIS by itself, with title, album, position and working pause, play and next. The sound indicator shows a player section for it, labelled "Media Player" with the stock app's icon. The lock screen has no media controls | **[device]**. Our own name and icon there would need an MPRIS service of our own: compiled code, as the Music app bundles |
| Files from other apps | Content Hub delivers a file as a hard link in `~/.cache/gemplayer.yenis/HubIncoming/`, taking no extra space | **[device]** |
| Embedded subtitles and audio tracks | The first audio track plays; embedded subtitles are never drawn; neither can be chosen | **[device]**, **[source]** media-hub |
| Rotation | The system rotates the window, subject to the user's rotation lock | **[device]** |
| Audio in the background | media-hub plays the queue and advances it while the app is suspended | **[device]** |
| Volume | `MediaPlayer.volume` is accepted and ignored (an empty function in `qtubuntu-media`). The system volume can be set through the sound indicator's `volume` action, with `QMenuModel`'s `QDBusActionGroup` | **[source]**, **[device]** |
| Screen brightness | The power indicator's `brightness` action sets the real backlight, the same way | **[device]** |
| Running in the background | An app is frozen a few seconds after it leaves the foreground, so its timers stop. Apps listed in `com.canonical.qtmir lifecycle-exempt-appids` are not; the list holds `music.ubports` | **[device]** |
| **Playback speed** | **Not available.** The backend's `setPlaybackRate()` ignores its argument and always reports 1.0 | **[source]** `qtubuntu-media`, **[device]** |

---

## Feature map

The full list, with the VLC file behind each feature and a verdict for Ubuntu
Touch, is in [VLC-FEATURES.md](VLC-FEATURES.md). In short:

| Verdict | What falls under it |
|---|---|
| **Build** | Gestures, player controls and menu, lock, aspect modes, resume and seen marker, sleep timer, jump to time, A-B repeat, bookmarks, queue, repeat and shuffle, playlists, favourites, history, incognito mode, video grouping, sorting, multiple selection, stream history, subtitle styling, settings |
| **Spike** | Everything that touches the system: playback itself, background audio, play as audio, library models and thumbnails, direct file access, external subtitles, system controls, orientation, keep-screen-on, opening from other apps, network streams |
| **Discuss** | Playback speed, equalizer, audio delay and boost, choosing audio and embedded-subtitle tracks, chapters, replay gain, decoder settings, 360° video, pop-up player, casting, real screen brightness, screenshots, network shares, remote access, subtitle download, film metadata, choosing library folders |
| **N/A** | Android widgets, Android Auto, Android TV, ringtone, launcher shortcuts, permission onboarding |

### How Discuss items are handled

- Each one is raised in the phase that builds its screen, not before.
- The screen is built so the feature has a place to go: the player menu keeps
  the VLC order, and an entry that is not available is left out, not greyed.
- The discussion weighs what it would take against what it gives. Most of the
  playback items share one answer, an engine that exposes more than
  QtMultimedia 5; see the grouping at the end of
  [VLC-FEATURES.md](VLC-FEATURES.md).
- The outcome is recorded here as a decision.

### Play as audio

The one feature that must work (D11).

How VLC does it **[vlc]**: one playback service owns the media for both
screens. "Play as audio" closes the video screen and playback carries on in the
audio player without interruption (`VideoPlayerActivity.switchToAudioMode`).
"Play as video" appears in the audio player's menu when the file has a video
track (`PlayerOptionsDelegate.kt`). A setting chooses what happens when the app
is left during video: stop (the default), play as audio in background, or
picture-in-picture.

Behaviour here:

| Situation | Behaviour |
|---|---|
| A video is playing | The player menu offers "Play as audio" |
| Switched to audio | Playback continues from the same position on the audio now-playing screen, with the mini-player, queue and system controls. It keeps playing with the screen locked and under other apps, like any music track |
| In audio mode, the file has a video stream | The player menu offers "Play as video", which returns to the video player at the current position |
| The file is audio-only | Neither switch is ever shown |
| Video player leaves the foreground without the switch | Playback pauses (D10). A setting can change this to "play as audio in background", as in VLC |
| Resume point | Shared: position saved in either mode resumes in either mode |

How it works **[device]**, except for the last point: playback runs in
media-hub, a system service, not in the app. A video therefore keeps playing
when the app is suspended, with or without a picture on screen. So:

- "Play as audio" is the same player with its video surface hidden or
  detached. Nothing is re-opened and there is no gap in the sound. "Play as
  video" shows the surface again.
- Pausing a video when the app is left (D10) is something the app does itself,
  on leaving the foreground, unless it is in audio mode.
- A second player for the audio side does not work and is not needed.
- With the screen off, a video played on for 3.6 minutes without help and for
  10 minutes with a silent keep-alive player beside it; the 30-minute pocket
  test is part of the battle test. If it ever fails, the fix in reserve is
  that keep-alive: a second player looping a silent audio file, which makes
  media-hub hold the stay-awake lock.
- The app uses exactly one `MediaPlayer` for all playback. A second one
  misbehaves: it fails to start, or starts by itself.

Whether a file "has video" comes from the media library, since the player's
own `hasVideo` is only known once the file is loaded.

---

## Phase 0 - Reference survey and spike on the Pixel 3a

### Survey of the clone (done)

- [x] Clone path and licence confirmed (D5); `vlc-android/` is in `.gitignore`.
- [x] Module map: where the video player, audio player, library browsers,
      playlists and settings live.
- [x] Feature map rebuilt from the source: every user-facing feature, the file
      behind it, and the behaviour worth matching (zones, thresholds,
      defaults).
- [x] Screens and their navigation, as the outline for Phases 1-4.
- [x] Strings and layouts worth adapting.

All of it is in [VLC-FEATURES.md](VLC-FEATURES.md).

### Project skeleton

- [x] Copied from `~/ut-crypto-dashboard/`: `clickable.yaml`, manifest,
      AppArmor file, `Theme`, shared components, units.
- [x] App identity `gemplayer.yenis` (D4) set in `qml/Main.qml` before anything
      stores data.
- [x] The click build does not pick up `vlc-android/`: `CMakeLists.txt`
      installs only `qml/`, the icon and the four package files.
- [x] `LICENSE` (D5), `README.md` with the credit to VLC for Android,
      `CHANGELOG.md`, `docs/INSTALL.md`, `docs/STORE.md`, `docs/TESTING.md`.
- [x] Builds as `gemplayer.yenis_0.0.1_all.click` and installs on the Pixel 3a.
- [ ] A real icon. `assets/icon.png` is a placeholder.
- [ ] Draft the upstream proposal for media-hub and mediascanner (D12, option C).

### Spike (done)

| # | Outcome |
|---|---|
| S1 | Pass, unconfined: 1080p H.264 is smooth |
| S2 | Direct reading works; playing from `~/Videos` and `~/Music` needs the app unconfined (D12) |
| S3 | Pass, unconfined: music models and the video query |
| S4 | Video thumbnails pass; album art still to be seen with a tagged album |
| S5 | Audio continues in the background and with the screen off. A video does too, so pausing it is the app's job |
| S6 | Pass: the same player with its picture hidden. Screen off: played on for minutes; pocket test in the battle test |
| S6b | Seeks land on the keyframe before the target and take 0.4 to 1.5 s; position updates 10 times a second |
| S7 | Confirmed: no playback speed |
| S8 | Fullscreen covers the panel; media-hub keeps the display on for a video |
| S9 | The system rotates the window, subject to the user's rotation lock; the player rotates its own content |
| S10 | Pass |
| S11 | Controls in the sound indicator work through media-hub, under the name "Media Player" |
| S12 | Pass: files arrive through Content Hub as hard links |
| S13 | Pass: HLS and MP4 over `https`; a dead address raises no error |
| S14 | Pass: H.264, HEVC, VP9, AV1; MP3, FLAC, Opus, Vorbis, AAC |
| S15 | Pass: pure QML is enough (D7) |
| S16 | The backend exposes no tracks, chapters or codecs, draws no embedded subtitles; a video frame can be captured |

One throwaway diagnostics page, `qml/spike/`, shipped as version 0.0.1. It
runs most checks by itself on launch and writes each finding to the app log;
the rest need hands on the phone. How to run it, and the answers, are in
[TESTING.md](TESTING.md). Each row ends as pass, fail or "works with a caveat",
and [VLC-FEATURES.md](VLC-FEATURES.md) is updated before anything else is
built.

| # | Question |
|---|---|
| S1 | Does a pure-QML click with `MediaPlayer` + `VideoOutput` play a local 1080p file smoothly under confinement? Which policy groups are needed? |
| S2 | Can the app read `~/Videos`, `~/Music` and the SD card directly, and with which policy groups? Can it delete and rename there? What does `click-review` say about each group and each extra path: accepted, or flagged for manual review (matters for the OpenStore, D9)? |
| S3 | Do the MediaScanner music models work from our app? Does `MediaStore.query("", VideoMedia)` list all videos? |
| S4 | Do video thumbnails and album art load (`image://thumbnailer/`, `image://albumart/`)? |
| S5 | Does a music file keep playing with the screen locked and with another app in front? Does a playing video pause in both cases? What happens to playback during a call or a notification sound? |
| S6 | **Play as audio:** does a video file, played with the music role and no video surface, keep playing with the screen locked and in a pocket for 30 minutes? Can the switch happen during playback, and how long is the gap in each direction? Does it still decode the picture (battery)? |
| S6b | How fast is `seek()`, and how often does `position` update? Decides how the seek gesture and subtitle timing are built |
| S7 | Confirm on the device that `playbackRate` does nothing |
| S8 | Can the display be kept on during video (`keep-display-on`), and can the app go fullscreen over the panel? |
| S9 | Can the app lock its own orientation? |
| S10 | Can QML read a `.srt` file sitting next to the video? |
| S11 | Do the sound indicator, lock screen and headset buttons control playback without bundling an MPRIS module? Does unplugging a headset pause playback? Can the app read or set the system volume, or only its own? |
| S12 | Does opening a video from the file manager, and importing through Content Hub, reach the app? Can the app share a file to another app? |
| S13 | Do `http(s)` streams and HLS play? |
| S14 | Which formats and codecs play: H.264, HEVC, VP9, AV1; MP4, MKV, WebM; MP3, FLAC, Opus, AAC? |
| S15 | Does `ubuntu-sdk-20.04-qml` cover every module used, or is a compiled click needed (D7)? |
| S16 | Background for the Discuss list: with a file that has two audio tracks, embedded subtitles and chapters, what does the backend do on its own, and does `metaData` expose any of it? Can `grabToImage` capture a video frame? |

## Phase 1 - Video player

The screen that plays one video, opened from a file path or Content Hub.
Behaviour follows [VLC-FEATURES.md](VLC-FEATURES.md), "Video player" and
"Values worth matching". Done: built in versions 0.0.2 and 0.0.3, and checked
by hand.

How it is built:

| Part | File | What it does |
|---|---|---|
| Playback core | `qml/Gem/Playback.qml` | The app's one `MediaPlayer`, with the backend's quirks hidden behind it: open, play, pause, seek, resume, position saving |
| What is remembered | `qml/Gem/PlayerStore.qml` | SQLite: position, length and "seen" per file, and bookmarks |
| Player screen | `qml/Gem/VideoPlayerPage.qml` | Picture, picture size, own rotation, overlays, lock |
| Gestures | `qml/Gem/GestureLayer.qml`, `qml/js/Gestures.js` | Recognises taps, swipes and pinch with VLC's zones and thresholds |
| Volume and brightness | `qml/platform/SystemVolume.qml`, `SystemBrightness.qml` | The system's own levels, through the sound and power indicators |
| Subtitles | `qml/Gem/SubtitleTrack.qml`, `qml/js/Srt.js` | Finds and reads the `.srt` beside a video; the page draws the current line |
| Menu features | `qml/Gem/TimePicker.qml`, `SleepTimer.qml`, `PlayerStore.qml` | Keypad for jump and sleep, the timer, bookmarks |
| Controls | `qml/Gem/PlayerControls.qml`, `SeekBar.qml`, `OptionSheet.qml`, `Glyph.qml` | Title bar, timeline, buttons, menu, icons |
| Audio mode | `qml/Gem/AudioModePage.qml` | What shows while a video plays as audio |
| Way in | `qml/Gem/VideoLibraryPage.qml`, `qml/platform/MediaLibrary.qml`, `qml/platform/ContentImport.qml` | A plain list of videos until Phase 2 builds the library; files from other apps |
| Development aid | `qml/dev/Remote.qml` | Drives and photographs the app over adb. Off unless a marker file exists; removed in Phase 5 |

Two rules the spike imposed: the video surface exists before a file is opened
(the backend will not start a video otherwise), and it is never destroyed, only
hidden.

- [x] Player surface, auto-hiding controls, title, seek bar with time labels.
- [x] Gesture layer: single tap, double-tap seek and pause, swipe seek, volume,
      brightness, pinch to fit. Tried by hand.
- [x] Volume gesture sets the system volume, brightness gesture the real
      backlight; the phone's own brightness returns when the player is left.
- [ ] A setting for each gesture, and for the skip lengths (with Settings, Phase 4).
- [ ] Optional rewind and forward buttons (with Settings).
- [x] Lock with slide to unlock.
- [x] Orientation: the player turns its own content to follow the phone, and
      the button locks it.
- [x] The twelve picture sizes: tap steps through six, long press lists all.
- [x] Player menu in VLC's order.
- [x] Resume where the file was left (always; the "ask" and "never" choices come
      with Settings). Seen marker when a file is played to the end.
- [x] Jump to time, on a keypad of its own.
- [x] A-B repeat, with marks on the timeline.
- [x] Sleep timer, with VLC's two options. Limited by the platform, see below.
- [x] Bookmarks: add, jump, remove, marks on the timeline. Renaming waits for
      a text field that works in a turned player.
- [x] External `.srt` subtitles beside the video, with a delay control.
      Styling, other encodings and picking a file by hand come with Settings
      and the file browser.
- [x] Video information, as far as the library goes.
- [x] Play as audio and back to video (D11), with a minimal audio page; Phase 3
      replaces it with the full one.
- [x] Pause when the app is suspended in video mode (D10).
- [x] Screenshot of the picture, saved to Pictures.
- [x] Keyboard shortcuts.
- [x] "Loading" while a file starts, and a message when a file or stream does
      not start within 20 s.
- [x] Checked by hand: volume, brightness, jump to time, sleep timer,
      bookmarks, A-B repeat, subtitles.
- [ ] Still by hand: a real film with real subtitles; a keyboard.

What the platform limits, found while building:

| Feature | Limit | Way out |
|---|---|---|
| Sleep timer, A-B repeat | They run in the app, and Ubuntu Touch freezes an app a few seconds after it leaves the foreground or the screen goes off. For a video on screen they work. For audio behind the lock screen the timer fires late, when the app is next opened | The system exempts apps listed in the setting `lifecycle-exempt-appids`, which holds the stock Music app. An unconfined app can add itself. To discuss |
| Seeking, A-B repeat, bookmarks, resume | A seek lands on the keyframe before its target, so all four start a little early | None on this backend |

Discuss items this phase reached, for a decision (D2):

| Item | What it would take | Suggestion |
|---|---|---|
| Playback speed and fast play, audio delay and boost, choosing audio and embedded-subtitle tracks, chapters | A second playback engine, in compiled code | After 0.1.0, as one decision |
| Sleep timer and A-B repeat while the app is in the background | The app adding itself to the system's list of apps that are not frozen | An opt-in switch in Settings, Phase 4 |
| Pop-up player | The platform has no floating windows | Drop |
| Subtitle download | An account with an online subtitle service, and a file hash | After 0.1.0 |
| Renaming a bookmark | A text field in a turned player; the system keyboard appears on the window's edge, not the content's | With playlists in Phase 4, which need naming too |

## Phase 2 - App shell and video library

How it is built:

| Part | File | What it does |
|---|---|---|
| Shell | `qml/Gem/AppShell.qml`, `TabBar.qml` | The bar along the bottom and the page behind each tab. The players cover both |
| Video tab | `qml/Gem/VideoLibraryPage.qml` | The videos on the phone |
| Tabs still to be built | `qml/Gem/PlaceholderPage.qml` | Audio (Phase 3), Browse and Playlists (Phase 4) say what will be there |
| More tab | `qml/Gem/MorePage.qml` | The version, and the way to the diagnostics page. Streams, history and settings join it in Phase 4 |

- [x] The five tabs: Video, Audio, Browse, Playlists, More (version 0.0.4).
- [ ] Grid and list views with thumbnail, duration, resolution, progress and
      seen marker.
- [ ] Grouping: none, by folder, by name; manual groups.
- [ ] Sorting, "only favourites", filter within the list.
- [ ] Item menu and multiple selection; default action on tap.
- [ ] Video queue: play a folder or group in order, queue shown over the video.
- [ ] Media information screen.
- [ ] Discuss, when reached: choosing library folders, film metadata.

## Phase 3 - Audio

- [ ] Library tabs: artists, albums, tracks, genres, playlists; album and
      artist pages.
- [ ] Mini-player bar on every page, with swipe for previous and next.
- [ ] Full player: cover, blurred background, seek bar, rewind and forward.
- [ ] Queue with search, reorder and remove, shuffle, repeat modes, "stop after
      this track", queue restored on launch.
- [ ] Sleep timer, jump to time, A-B repeat and bookmarks shared with the video
      player.
- [ ] Playback under other apps and with the screen locked (D10), and system
      controls and headset behaviour as far as S11 allows.
- [ ] "Play as video" in the player menu for files that have a picture.
- [ ] Discuss, when reached: equalizer, replay gain, passthrough.

## Phase 4 - Browse, playlists, streams and settings

- [ ] Browse tab: local and removable storage with a path bar, favourite
      folders, play a folder.
- [ ] Playlists tab: create, rename, delete, reorder; save the queue as a
      playlist; add from any list.
- [ ] More tab: streams (open by address, history), playback history, settings,
      about.
- [ ] Library search across videos, artists, albums, tracks, genres and
      playlists.
- [ ] Incognito mode.
- [ ] Content Hub import, "open with" and sharing.
- [ ] Settings in VLC's grouping: interface, video, subtitles, audio, history,
      advanced; export and restore.
- [ ] Landscape and tablet layouts.
- [ ] Empty, error and unsupported-format states.
- [ ] Tips for the gestures; parental control.
- [ ] Discuss, when reached: network shares, casting, remote access.

## Phase 5 - Release 0.1.0, self-installed

- [ ] README, `docs/INSTALL.md`, `CHANGELOG.md`, in the style of GemTicker's.
- [ ] Remove the development aids: `qml/dev/` (remote control) and `qml/spike/`
      (diagnostics page), and the entry that opens it.
- [ ] `clickable review` clean, or every exception written down in
      `docs/STORE.md`.
- [ ] Verified on the Pixel 3a from a clean install.
- [ ] **Battle test: a few weeks of daily use on the Pixel 3a.** Problems go
      into `docs/TESTING.md` and are fixed in 0.1.x releases.

## Phase 6 - OpenStore

Not urgent, and only after the battle test. Everything here is **[verify]**
against the OpenStore's current submission rules, which are read in Phase 0 so
that nothing built later has to be undone.

### Choices the store affects from the start

| Topic | Consequence |
|---|---|
| Confinement | Policy groups and extra read paths beyond the common set can send an app to manual review. S2 records what `click-review` says about each one, and the app uses the smallest set that works. Content Hub is the fallback for file access if direct reading is refused |
| Review errors | No `ignore_review_errors` in `clickable.yaml`; every warning is fixed or explained |
| Architectures | A pure-QML click serves every device with one package. A compiled click needs arm64, armhf and amd64 builds |
| Framework | Decides which Ubuntu Touch releases can install it; 20.04 devices stay untested unless a tester turns up |
| Identity | `gemplayer.yenis` is permanent once published; the version only goes up |
| Trademark | Listing text may say "inspired by VLC for Android" but not use the name as the app's own, nor the cone |
| Privacy | Nothing leaves the device except stream URLs the user opens; said plainly in the README and the listing |

### Documents kept from the first commit

| File | Purpose |
|---|---|
| `README.md` | What it is, features, privacy, build, credits to VLC for Android |
| `CHANGELOG.md` | One entry per release; the store's changelog field is copied from it |
| `LICENSE` | GPL-3.0 or later (D5); added |
| `docs/PLAN.md` | This plan |
| `docs/VLC-FEATURES.md` | The feature survey and the verdict for each feature |
| `docs/DEVELOPING.md` | Build loop, development remote, backend rules, reference sources |
| `docs/INSTALL.md` | Self-install route, used during the battle test |
| `docs/TESTING.md` | Device checks per release and battle-test findings |
| `docs/STORE.md` | Draft listing (tagline, description, category, keywords), screenshot list, and the reason for each policy group and read path, ready for a reviewer |

### Submission

- [ ] Read the OpenStore submission and content rules; correct this section.
- [ ] Public source repository, linked from the listing.
- [ ] Screenshots from the Pixel 3a: library, video player with controls,
      now-playing, queue, settings.
- [ ] Icon at the sizes the store asks for.
- [ ] `clickable review` clean on the release build.
- [ ] Submit; answer the reviewer from `docs/STORE.md` if manual review applies.

---

## How work is verified

| What | How |
|---|---|
| Layout and static UI | Rendered offscreen in the Clickable build image at Pixel 3a resolution, as for GemTicker |
| Playback, gestures, background behaviour, confinement | Only on the device. Each phase ends with a device check and a read of the journal for AppArmor denials and QML errors |

## Lessons carried over from GemTicker

- Set organization and application name in QML before anything stores data.
- `Qt.labs.settings`: write with `setValue()` + `sync()`; property writes can be
  lost on quit.
- No inline `component` declarations, to stay compatible with Qt 5.12.
- `Component.onCompleted` order between parent and child is undefined; stores
  open on first use.
- Nothing takes focus on launch, and content must sit above the on-screen
  keyboard.
