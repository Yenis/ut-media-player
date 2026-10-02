# GemPlayer - a VLC-style media player for Ubuntu Touch - plan

Status: Phase 0 is under way. The survey of the VLC clone is done, see
[VLC-FEATURES.md](VLC-FEATURES.md). The project skeleton builds and installs as
version 0.0.1, which is the spike's diagnostics page and not a player yet.
Next step: run the spike on the Pixel 3a and record the answers in
[TESTING.md](TESTING.md). Target device is the Pixel 3a on Ubuntu Touch
24.04-1.x (tag `24.04-1.4`), the same one GemTicker was verified on.

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
| D8 | Order | **Video player first**: it is the larger gap, since the stock video app is a bare player with no library. Audio second |
| D9 | Distribution | **OpenStore, eventually.** First a self-installed click that is battle-tested on the Pixel 3a for a few weeks; the store submission follows and is not urgent. Store requirements shape choices from the start, see [Phase 6](#phase-6---openstore) |
| D10 | Background playback | **Audio plays while other apps are in use and while the screen is locked**, as the stock Music app does. **Video stops when the app leaves the foreground**, except through "Play as audio". This matches VLC's own default **[vlc]** |
| D11 | "Play as audio" | **Essential.** A playing video can be switched to audio-only and back; see [Play as audio](#play-as-audio) |

### Still open

| # | Decision | Recommendation |
|---|---|---|
| D7 | Packaging | Pure-QML click like GemTicker if Phase 0 allows. Falls back to a compiled click only if a needed module has to be bundled (MPRIS is the likely one); for the store that means one build per architecture. Several "Discuss" features would also need compiled code |

---

## What the platform gives us

| Need | API | Status |
|---|---|---|
| Audio and video playback | `QtMultimedia 5.6` `MediaPlayer`, `VideoOutput` | **[source]** both stock apps use it |
| Play queue | `QtMultimedia` `Playlist`, with sequential, loop, repeat-one and random modes | **[source]** music app |
| Queue saved across launches | `Playlist.save()`/`load()` do not work; the music app stores the queue itself | **[source]** |
| Music library | `MediaScanner 0.1`: `SongsModel`, `AlbumsModel`, `ArtistsModel`, `GenresModel`, `SongsSearchModel` | **[source]** |
| Video library | No video model. `MediaStore.query(text, VideoMedia)` exists, and `MediaFile` carries title, duration, width, height and art | **[source]**; whether an empty query lists everything is **[verify]** |
| Confinement for video | Policy groups `video`, `audio`, `content_exchange` | **[source]** stock video app |
| Confinement for music | `audio`, `music_files_read`, `content_exchange`, `content_exchange_source`, `networking`, `keep-display-on`; read paths for `~/.cache/media-art/`, `~/.cache/mediascanner-2.0/` and `/media/*/*/` | **[source]** music app |
| Reading media folders directly | `video_files_read` and `music_files_read` cover `~/Videos`, `~/Music` and the `Videos` and `Music` folders of an SD card, nothing else. Both are reserved: `click-review` flags them for manual review | **[device]** policy files on the phone; review run on 0.0.1 |
| Deleting and renaming files | QML has no API for either, whatever the confinement allows. Needs compiled code plus the write groups `video_files`, `music_files` | **[source]**; a Discuss item |
| Keeping the display on | `QtSystemInfo 5.0` `ScreenSaver`, policy group `keep-display-on` | **[source]** music app. media-hub also holds the display on by itself while a video source plays |
| Calls and low battery | media-hub pauses multimedia sessions for a phone call and resumes them afterwards | **[source]** media-hub |
| Own database | `QtQuick.LocalStorage 2.0` (SQLite) | **[source]** music app; used here for resume points, history, playlists, bookmarks, favourites, groups |
| Audio role | The backend accepts Qt's music and video roles but maps both to the same media-hub "multimedia" role, so the role does not tell audio from video. media-hub itself decides by whether the stream has a picture | **[source]** `qtubuntu-media`, media-hub |
| Lock-screen and indicator controls | media-hub exposes the current multimedia player over MPRIS by itself. The Music app additionally bundles `org.nemomobile.mpris`, a compiled module that is **not** on the system image **[device]** | **[source]**; whether media-hub's own controls are enough is **[verify]**, S11 |
| **Playback speed** | **Not available.** The backend's `setPlaybackRate()` ignores its argument and always reports 1.0 | **[source]** `qtubuntu-media` |

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

How it is expected to work **[verify, S5-S6]**: playback runs in media-hub, a
system service, not in the app, so sound can outlive the app being suspended.
The open question is what media-hub does with a file that has a picture when
the screen goes off, since it treats "has video" as a property of the stream
and not of the role **[source]**. The spike tries two routes: the same player
with its picture hidden, and a second player that never had a video surface,
started at the video's position; for the second it measures the gap in sound.
Whether a file "has video" is remembered from when it was opened as a video,
or read from the media scanner.

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

### Spike

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
"Values worth matching".

- [ ] Player surface, auto-hiding controls, title, seek bar with time labels.
- [ ] Gesture layer: single tap, double-tap seek and pause, swipe seek, volume,
      dimming, pinch to fit; a toggle for each.
- [ ] Optional rewind and forward buttons.
- [ ] Lock with swipe to unlock, orientation lock, the twelve aspect modes.
- [ ] Player menu in VLC's order.
- [ ] Resume: always, never or ask; seen marker when a file is played to the
      end.
- [ ] Jump to time, A-B repeat, sleep timer, bookmarks.
- [ ] External subtitles with styling and delay.
- [ ] Video information, as far as the metadata goes.
- [ ] Play as audio and back to video (D11). In Phase 1 the audio side is a
      minimal now-playing screen; Phase 3 replaces it with the full one.
- [ ] Pause when the app leaves the foreground in video mode (D10).
- [ ] Keyboard shortcuts.
- [ ] Discuss, when reached: playback speed and fast play, audio delay and
      boost, audio and embedded-subtitle tracks, chapters, screenshot, real
      brightness, pop-up player, subtitle download.

## Phase 2 - App shell and video library

- [ ] The five tabs: Video, Audio, Browse, Playlists, More.
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
