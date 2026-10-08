# GemPlayer - a VLC-style media player for Ubuntu Touch - plan

Status: **Phase 2 closed on 3 October 2026: the video side of the app is
whole** (version 0.0.11). Phases 0, 1 and 2 are done: a video player, and
around it the app shell with VLC's five tabs and a video library with grid
and list, sorting, filter, favourites, grouping, groups made by hand, a
queue, an item menu, multiple selection and an information page. Phase 3,
audio, is under way: version 0.0.12 has the audio player and the mini-player,
0.0.13 a queue that moves on in the background and can be added to,
0.0.14 the music library, 0.0.15 shuffle and repeat, 0.0.16 the audio
player's menu, 0.0.17 its volume and brightness swipes, 0.0.18 a queue
that is kept between launches and can be trimmed, 0.0.19 a filter for
the music lists and the blurred cover, and 0.0.20 their sorting and
favourites.
Target device is the
Pixel 3a on Ubuntu Touch 24.04-1.x (tag `24.04-1.4`), the same one GemTicker
was verified on.

## Milestone 1 - where things stand

One day's work, from an empty folder to a player that runs on the phone.

| | |
|---|---|
| **Works, checked by hand on the Pixel 3a** | Video list with thumbnails; playback of H.264, HEVC, VP9 and AV1; VLC's gestures (tap, double tap, swipe seek, system volume, real brightness, pinch); twelve picture sizes; lock; own rotation; resume; play as audio and back; background and screen-off playback; sleep timer; jump to time; A-B repeat; bookmarks; external subtitles; screenshot; opening files from other apps |
| **Known and settled** | The app is unconfined (D12). No playback speed, track selection or embedded subtitles on this backend. Seeks land on the keyframe before their target. System media controls work but carry the name "Media Player" |
| **Still open from Phase 1** | A check with a real film and real subtitles. Decisions on the Discuss items in the table at the end of [Phase 1](#phase-1---video-player) |
| **To pick up next** | Phase 3, audio. Read [DEVELOPING.md](DEVELOPING.md) first: it has the build loop, the remote control for checking changes on the phone, and the rules the backend imposes. Mind D13: nothing over the network |

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

| D13 | Network | **Nothing over the network except playing streams** (decided by Yenis, 3 October 2026). The aim is an app that needs no network permission and cannot connect anywhere by itself. Dropped for good: network shares, casting, remote access, subtitle download, film metadata. Kept: opening a stream by address, stream history, and a link handed over by another app, since each is playing a stream. See [Network](#network) |

### Still open

None. Discuss items become decisions as the work reaches them.

### Network

What D13 rests on, and what is still to be shown:

| Point | State |
|---|---|
| A stream is fetched by media-hub, the system's playback service, not by the app. The app hands over an address and draws the picture | **[source]**, **[device]**: playback runs in media-hub (S5, S13) |
| The app's own code opens no connection. QML's only way to is `XMLHttpRequest`; it is used twice, both times on a `file://` address: subtitles (`SubtitleTrack.qml`) and the development remote (`dev/Remote.qml`) | Checked by search, 3 October 2026. To be checked again before each release |
| The diagnostics page played three test streams from the internet in its automatic run | Taken out on 3 October 2026 (version 0.0.11), its question being answered. No network address is left in the app's code |
| Until streams are built (Phase 4, "open by address") | Nothing in the app touches the network at all, and nothing is to be added that does (Yenis, 3 October 2026) |
| No network permission | The package is unconfined today (D12), so the system enforces nothing: the rule is kept by what the code does. A confined build (Phase 6) would then be declared **without** the `networking` policy group, which makes it enforced. Whether streams still play in that build is **[verify]**: they should, media-hub doing the fetching |
| Album art in Phase 3 | The system's thumbnailer may look covers up online for `image://albumart/` **[verify]**. If it does, the app shows only the art found in the files |

Rules that follow, for every later phase:

- No `XMLHttpRequest`, `Image` or any other loader on an `http(s)` address.
  A network address goes to the player and nowhere else.
- No feature that needs a server, an account or a lookup.

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
| **Discuss** | Playback speed, equalizer, audio delay and boost, choosing audio and embedded-subtitle tracks, chapters, replay gain, decoder settings, 360° video, pop-up player |
| **Dropped** | By D13: network shares, casting, remote access, subtitle download, film metadata. Not needed: choosing library folders |
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
| Audio mode | `qml/Gem/AudioPlayerPage.qml` (since 0.0.12; `AudioModePage.qml` before) | What shows while a video plays as audio |
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
| Queue played as audio (found in Phase 2) | The app moves the queue on, and the app is frozen in the background. Behind the lock screen the current item plays to its end and the next starts only when the app is opened | Solved in 0.0.13: audio is handed to media-hub as a list, which it moves through by itself **[device]** (the `Playlist` type). See [Phase 3](#phase-3---audio) |
| Sleep timer, A-B repeat | They run in the app, and Ubuntu Touch freezes an app a few seconds after it leaves the foreground or the screen goes off. For a video on screen they work. For audio behind the lock screen the timer fires late, when the app is next opened | The system exempts apps listed in the setting `lifecycle-exempt-appids`, which holds the stock Music app. An unconfined app can add itself. To discuss |
| Seeking, A-B repeat, bookmarks, resume | A seek lands on the keyframe before its target, so all four start a little early | None on this backend |

Discuss items this phase reached, for a decision (D2):

| Item | What it would take | Suggestion |
|---|---|---|
| Playback speed and fast play, audio delay and boost, choosing audio and embedded-subtitle tracks, chapters | A second playback engine, in compiled code | After 0.1.0, as one decision |
| Sleep timer and A-B repeat while the app is in the background | The app adding itself to the system's list of apps that are not frozen | An opt-in switch in Settings, Phase 4. It would also do away with the catching up after a freeze that 0.0.18 needs (see [Phase 3](#phase-3---audio)) |
| Pop-up player | The platform has no floating windows | Drop |
| Subtitle download | An account with an online subtitle service, and a file hash | Dropped (D13) |
| Renaming a bookmark | A text field in a turned player; the system keyboard appears on the window's edge, not the content's | With playlists in Phase 4, which need naming too. The name dialog exists since 0.0.10 (`NameDialog.qml`); what is left is using it in a turned player |

## Phase 2 - App shell and video library

How it is built:

| Part | File | What it does |
|---|---|---|
| Shell | `qml/Gem/AppShell.qml`, `TabBar.qml` | The bar along the bottom and the page behind each tab. The players cover both |
| Information | `qml/Gem/MediaInfoPage.qml` | What is known about one video; the file's size comes from a listing of its folder |
| Asking for a name | `qml/Gem/NameDialog.qml` | One line of text with Cancel and a confirming button, placed clear of the keyboard. For groups now, playlists and bookmarks later |
| Order, filter, favourites, grouping | `qml/js/Library.js`, `qml/Gem/SearchField.qml`, `PlayerStore.qml`, `GroupThumb.qml` | What the list shows and in which order; folders and groups; the filter's text field; favourites in the app's database |
| Queue | `qml/Gem/Playback.qml`, `PlayerControls.qml`, `VideoPlayerPage.qml` | The list of what plays after what, moved on by the app; previous, next and the queue's list in the player |
| Video tab | `qml/Gem/VideoLibraryPage.qml`, `VideoThumb.qml` | The videos on the phone as a grid of cards or a list, after VLC's `video_grid_card.xml` and `video_list_card.xml`. The choice is remembered |
| Tabs still to be built | `qml/Gem/PlaceholderPage.qml` | Audio (Phase 3), Browse and Playlists (Phase 4) say what will be there |
| More tab | `qml/Gem/MorePage.qml` | The version, and the way to the diagnostics page. Streams, history and settings join it in Phase 4 |

- [x] The five tabs: Video, Audio, Browse, Playlists, More (version 0.0.4).
- [x] Grid and list views with thumbnail, duration, resolution, progress and
      seen marker (version 0.0.5). Resolution is VLC's class ("1080p", "SD"),
      not the pixel size.
- [x] Grouping: none, by folder, by name (version 0.0.7). By name is the
      default, as in VLC. Its rule is in VLC's native media library, not in
      the clone: names that begin with the same six characters, ignoring case
      and a leading "the", as remembered and still to be checked against the
      source. A folder or group opens in place, with a way back in the header.
- [x] Manual groups (version 0.0.10), under "Group by name": add to a new or
      an existing group, remove from a group, rename, ungroup, regroup
      automatically. Kept in the app's database. A group that formed by name
      becomes one kept by hand the moment it is renamed or added to. Ungrouped
      videos stay on their own until "Regroup automatically", as in VLC.
- [x] Sorting, "only favourites", filter within the list (version 0.0.6).
      Sorts: name, file name, length, recently added. VLC's "insertion date"
      is left out: the system's library does not record it. A video's menu
      has its first two entries, Play and the favourite switch, so that there
      are favourites to show; the rest comes with the item menu below.
- [x] Item menu (version 0.0.8), in VLC's order. A video: Play, Play from
      start, Play all, Play as audio, Mark as played or not played, favourite.
      A folder or group: Play all, Mark all as played or not played.
- [x] Video queue (version 0.0.8): play a folder or group in order, or
      everything shown from one video on; previous and next in the player;
      queue shown over the video, a tap goes to that item.
- [x] Multiple selection (version 0.0.9): a long press starts it, taps add
      and remove, and a bar in the header's place plays the selection, plays
      it as audio, or switches its favourite marks. Where VLC hides both
      favourite actions for a mixed selection, the one button here adds.
- [x] Default action on tap (version 0.0.9), VLC's "Playback action": Play,
      or Play all. "Add to queue" and "Insert next" join it with the menu
      entries below.
- Carried over to later phases: "Insert next" and "Append", in the item
  menu, the selection bar and the playback action, for a player that keeps
  playing behind the library (the mini-player of Phase 3); "Add to playlist"
  (Phase 4). Delete, rename and share are Discuss items (compiled code;
  sharing was not tried in the spike).
- [x] Media information screen (version 0.0.11), from "Information" in a
      video's menu or in the selection bar with one video selected: picture,
      name, a Play or Resume button, length, file size, resolution class,
      format, file, folder, date changed, how far it was played. VLC's list
      of tracks and codecs is left out: neither the library nor the playback
      service reports them (S16).
- [x] Film metadata: dropped (D13).
- [x] Networking, raised with Yenis at the end of the phase as asked: decided
      as D13.
- [x] Choosing library folders: dropped (Yenis, 3 October 2026). The
      system's scanner decides what it scans, so a choice would take a
      scanner of our own; "Group by folder" shows where the videos are, and
      the Browse tab of Phase 4 reaches any folder.

## Phase 3 - Audio

How it is built:

| Part | File | What it does |
|---|---|---|
| Audio tab | `qml/Gem/AudioLibraryPage.qml`, `qml/js/AudioLibrary.js` | Artists, albums, tracks and genres, each worked out from the scanner's one list of tracks; an artist, album or genre opens in place |
| Full player | `qml/Gem/AudioPlayerPage.qml` | Cover, title, artist, timeline, buttons, the queue's list; the seek gestures on the cover. For music and for a video played as audio |
| Mini-player | `qml/Gem/MiniPlayer.qml` | The bar above the tabs while something plays as audio and the full player is not open |
| Two ways of playing | `qml/Gem/Playback.qml` | A video on screen is one address at a time, moved on by the app; audio is a list given to media-hub, which moves through it also while the app is frozen. Switching between the two loads the item again, and the list is emptied before an address plays (0.0.15): left full, it turns the next video upside down |
| Where audio lives | `qml/Gem/AppShell.qml` | Going back from the full player leaves it playing; only the mini-player's cross or the end of the queue ends it |

- [x] Library tabs (version 0.0.14): artists, albums, tracks, genres. An
      artist, album or genre opens to its tracks, with a heading per album
      for an artist and a genre. A tap plays the list from that track on,
      behind the page. Row menu: Play, Insert next, Add to play queue.
      Artists go by album artist where a file names one. An album is an
      album title within one folder: on real files the artist cannot decide,
      a soundtrack's tracks naming a different one each, as album artist too
      **[device]**. Playlists have their own tab, in Phase 4.
- [x] A "Files" list beside the four (version 0.0.14, asked for by Yenis,
      7 October 2026; **our own addition**): every audio file by its file
      name with its folder and length, in the order the system's library
      gives them, neither sorted nor grouped.
- [x] Filter for the music lists (version 0.0.19), as the video library has
      it: each list is narrowed by what it lists, so an artist, album or
      genre that matches keeps all its tracks. Not offered inside an open
      artist, album or genre.
- [x] Sorting and favourites for the music lists (version 0.0.20), in a
      "Display settings" sheet like the Video tab's. Orders, after VLC's for
      each list and without its "insertion date": tracks by name, album,
      artist, length, recently added; albums by name, artist, release date;
      artists and genres by name; "Files" stays as the library gives it.
      Each list remembers its own. Favourites are tracks, kept in the table
      the videos' favourites are in; "only favourites" narrows every list to
      what the favourite tracks make of it. VLC also lets an artist, album
      or genre be a favourite; that is not built.
- [ ] Library, still to do: separate artist and album pages as VLC has them
      (an artist's albums as cards); multiple selection as in the video
      library; the rest of VLC's item menu (information, add to playlist,
      go to album or artist).
- [x] Mini-player bar on every main page (version 0.0.12): cover, title,
      artist, progress, play and pause; a tap opens the full player, a swipe
      to the left is next and to the right previous, and a cross stops
      playback. VLC's "hold play to stop" was tried and dropped (Yenis,
      7 October 2026).
- [x] Full player (version 0.0.12): cover, title, artist, seek bar, previous
      and next, rewind and forward by 10 s, the queue's list, "Play as
      video". VLC's 20 s on a long press was tried and dropped (Yenis,
      7 October 2026): not needed, and a seek lands too unevenly on this
      backend for 20 s to be told from 10.
- [x] Volume and brightness swipes in the full audio player (version
      0.0.17, asked for by Yenis, 7 October 2026): up and down on the right
      of the cover for the system volume, on the left for the backlight, as
      in the video player. **Our own addition**, like the seek gestures: VLC
      for Android has neither for audio. The brightness is the page's, as it
      is the video player's: the phone's own comes back when the page or the
      app is left. Unlike the video player the page does not remember its
      brightness from one opening to the next, being made anew each time.
- [x] Full player: blurred cover as the background (version 0.0.19).
      `qml/Gem/BlurredCover.qml`, with `FastBlur` of QtGraphicalEffects
      **[device]**, on a 128-pixel copy of the cover. Loaded through a
      Loader, so the page stands without the module. Only for a cover that
      is in the file, like every cover (D13).
- [x] Seek gestures in the full audio player (version 0.0.12), as in the
      video player: a double tap on a side seeks 10 s back or forward, one in
      the middle pauses, and a horizontal swipe seeks (asked for by Yenis,
      7 October 2026). **Our own addition**: VLC for Android has neither for
      audio. The gesture layer of Phase 1 (`qml/Gem/GestureLayer.qml`,
      `qml/js/Gestures.js`) is reused, with its volume, brightness and pinch
      switched off. Settled: in the full player a sideways swipe seeks, and
      previous and next are buttons; on the mini-player it is previous and
      next.
- [x] Shuffle and repeat modes (version 0.0.15), for audio and for a video
      queue. None of it is the hub list's own doing except "repeat one"
      **[device]**: its "loop" skips the first item at every turn (Qt's
      player answers the end of the list with a `next()` of its own, on top
      of the hub's), and its "random" plays items twice before others once.
      So the app shuffles the queue itself and gives the hub the result, and
      "repeat all" is the queue laid out again behind itself, about 200
      items deep, topped up while the app is awake. The list can only be
      changed behind the playing item: taking out or inserting before it
      leaves the list's index pointing at the wrong item. That is why
      shuffle mixes only what follows.
- [x] Queue restored on launch (version 0.0.18): what plays as audio is kept
      in the app's database, its items when they change and its place when
      that does, and is back in the mini-player at the next start, paused at
      the track's resume point. Nothing is loaded until it is played. VLC
      asks with a card; here it is simply there. A video queue is not kept:
      it ends with its page.
- [x] "Remove from queue" and "Stop after this track" (version 0.0.18), from
      holding an item in the audio player's queue. Removing is for items
      still to come, by the rule above. "Stop after" is the hub's list
      ending at that item, so it holds while the app is frozen; moving past
      the item by hand lifts it. When it stops, the queue is closed, where
      VLC keeps it.
- [x] Found on the way (version 0.0.18) **[device]**: with each index change
      of the list, Qt's own player sets that item and plays it, as if the
      list were its to run. Awake, that happens at the start of a track and
      is not heard. After a freeze it happens on waking, for every change
      made meanwhile, and the track that was playing started again. The app
      now works out from the clock where the track had got to and seeks
      there: a short break on opening the app, in place of a restart. The
      stock Music app does not meet this, being exempt from freezing.
- [x] Found on the way (version 0.0.18) **[device]**: media-hub plays on
      when the app's process ends. The app now pauses when its window is
      closed. A process that is killed outright cannot, and its music plays
      on to the end of its list; the next thing played, by any app, stops it.
- [ ] Queue with search and reorder. Reorder is limited by the same rule:
      only behind the playing item.
- [x] Sleep timer, jump to time, A-B repeat and bookmarks in the audio player
      (version 0.0.16), behind a menu button in its header. The timer, the
      store and the pickers are the video player's; the menu and its sheets
      are written out a second time in `AudioPlayerPage.qml`, the video
      page's being bound up with its turned stage. The limits are the video
      player's too: the sleep timer and A-B repeat act only while the app is
      awake, so behind the lock screen the timer fires late and the loop is
      not kept (see [Phase 1](#phase-1---video-player)).
- [ ] Playback under other apps and with the screen locked (D10), and system
      controls and headset behaviour as far as S11 allows.
- [x] "Play as video" for files that have a picture: a button in the full
      player's header (version 0.0.12), an entry of the player menu since
      0.0.16.
- [x] Carried over from Phase 2 (version 0.0.13): the queue is handed to
      media-hub when it plays as audio, and moves on while the app is frozen.
      A video on screen cannot be played that way: from a list its picture
      stays black or shows a stale frame, and attaching the surface again
      does not help **[device]**. So the app keeps two ways of playing, and
      "play as audio" and back load the item again and seek to where it was,
      a break of about a second. One video on its own is spared that: it has
      nothing to move on to, and stays as it is.
- [x] Carried over from Phase 2 (version 0.0.13): "Insert next" and "Add to
      play queue" (VLC's wording for append) in the video library's item
      menu, behind a queue button in the selection bar, and as playback
      actions. They add to what plays as audio; with nothing playing they
      play the video. What the backend allows **[device]**: adding a list at
      the end, and inserting one item before an existing one. Inserting
      several at once is "not yet implemented" there, and inserting at the
      very end is refused.
- [ ] Album art: check whether the system's thumbnailer looks covers up
      online; if it does, show only the art found in the files (D13). Until
      that is known, the safe half is in place (version 0.0.12): the library
      gives `image://albumart/artist=...&album=...` for a track with no cover
      of its own **[device]**, and `qml/platform/MediaLibrary.qml` does not
      pass that on; only a cover inside the file is shown.
- [ ] Discuss, when reached: equalizer, replay gain, passthrough.

## Phase 4 - Browse, playlists, streams and settings

- [ ] Browse tab: local and removable storage with a path bar, favourite
      folders, play a folder.
- [ ] Playlists tab: create, rename, delete, reorder; save the queue as a
      playlist; add from any list, the video library's item menu and
      selection bar included (carried over from Phase 2).
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
- Network shares, casting and remote access are dropped (D13). The Browse
  tab is local and removable storage only.

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
| Privacy | Nothing leaves the device except the addresses of streams the user opens, and those go to the system's player, not through the app (D13); said plainly in the README and the listing |

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

## After the app is finished - ideas, not commitments

- Seek gestures for audio in VLC for Android itself: the double tap and the
  horizontal swipe that GemPlayer adds to its audio player in
  [Phase 3](#phase-3---audio), offered to VideoLAN as a merge request
  (Yenis, 7 October 2026). To be considered only once GemPlayer is done. It
  would be Kotlin work in the `vlc-android` clone, around
  `src/gui/audio/AudioPlayer.kt`, and has nothing in common with this app's
  QML but the behaviour.

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
