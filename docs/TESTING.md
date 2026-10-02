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

Not run yet.
