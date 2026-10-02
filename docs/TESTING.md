# Testing GemPlayer on a device

Version 0.0.1 is the Phase 0 spike from [PLAN.md](PLAN.md): a diagnostics page
that finds out what Ubuntu Touch offers a QML-only media player. This page says
how to run it and records the answers.

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
| `sidecar.mp4` + `sidecar.srt` | A subtitle file beside a video (S10); also used for the seek and speed checks |
| `multi-track.mkv` | Two audio tracks (English 440 Hz, German 880 Hz), two subtitle tracks, three chapters (S16) |
| `long-35min.mp4` | 35 minutes with a short beep every 10 s, for the pocket test (S6) |
| `test-1.mp3` ... `test-5.m4a` | MP3, FLAC, Opus, Vorbis, AAC, tagged as one album (S14) |

## Running the spike

### Automatic part

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
| S1 | Player → `h264-1080p30.mp4` | Is the motion smooth, with no stutter or tearing? |
| S5 | Library → "Play a queue of 4 library songs". Press the power button and wait a minute. Unlock, then open another app | Does music continue with the screen off and under another app? Does it move on to the next song by itself? |
| S5 | Player → `long-35min.mp4`. Press the power button. Unlock, then open another app | Does the beep stop when the screen goes off, or when the app is left? |
| S6 | Player → `long-35min.mp4`, then "Play as audio". Press the power button and put the phone in a pocket for 30 minutes | Is it still beeping at the end? Then "Play as video": does the picture come back at the right time? |
| S8 | Player → `long-35min.mp4`, do not touch the phone past the screen timeout. Then "Fullscreen" | Does the screen stay on? Does fullscreen hide the top panel? |
| S9 | Turn the phone sideways. System → the orientation buttons | Does the page rotate? Do the buttons lock or change it? |
| S11 | While the song queue plays: the sound indicator in the top panel, the lock screen, headset buttons, unplugging a headset, the volume keys | Which of them show and control playback? |
| S12 | File manager → a video → open with GemPlayer | Does GemPlayer open, and does the log show a `RESULT S12` line? |

## Results

### Run 1: confined, 2 October 2026

Version 0.0.1 with the policy groups `audio`, `video`, `content_exchange`,
`keep-display-on`, `networking`, `music_files_read`, `video_files_read`.
Automatic part only; the manual part waits for the confinement decision (D12
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
| S13 | Network streams | **Inconclusive.** The phone had no network connection during the run |
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

### Other observations

- With no media loaded, `MediaPlayer.position` reads a large negative number
  (-140462611), not 0. The player must not show or store it.
- `hasAudio` read `false` for a file that has an AAC track, and
  `metaData.resolution` was empty. Neither can be relied on.
- Volume: after setting 0.3 the property read back 0.01. To be looked at.
- Position updates arrive about 10 times a second with `notifyInterval: 100`.
- Clearing `MediaPlayer.source` raises an error ("Failed to open uri"); the
  player should stop instead of clearing.
