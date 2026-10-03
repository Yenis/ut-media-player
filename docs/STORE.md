# OpenStore notes

Working notes for the submission in Phase 6 of [PLAN.md](PLAN.md). The listing
text and screenshots are added when there is a player to describe. What is
recorded from the start is the confinement: which permissions the app asks
for, why, and what `click-review` says about each.

## Confinement

GemPlayer is **unconfined** (decision D12 in [PLAN.md](PLAN.md)). Checked with
`click-review` in the Clickable 24.04 build image on 2 October 2026:

| Setting | `click-review` |
|---|---|
| `"template": "unconfined"`, no policy groups | **Needs manual review**: `'unconfined' not allowed` |

### Why, for the reviewer

A media player needs two things from the system: to play the user's files in
`~/Music` and `~/Videos`, and to read the media library. Neither is available
to a confined third-party app, whatever policy groups it declares:

- media-hub opens files under `Music/`, `Videos/` and `/media` only for the
  packages `music.ubports` and `gallery.ubports`
  (`src/service/apparmor/lomiri.cpp`).
- mediascanner answers a confined app only if it is `music.ubports`, and only
  for audio (`src/ms-dbus/service-skeleton.cc`).

Both were confirmed on a Pixel 3a with 24.04-1.x: a build with `audio`,
`video`, `music_files_read` and `video_files_read` could list the folders and
get thumbnails, but every file was refused with "Client is not allowed to
access", and the library came back empty. The record is in
[TESTING.md](TESTING.md), runs 1 and 2.

What the app does with its access: it reads media files, reads the media
library, and writes only its own settings and database. It has no network use
beyond opening the stream addresses the user enters.

### The confined alternative

If an unconfined package is not acceptable, the fallback is a confined build
whose library is filled through Content Hub: the user hands files over from
the file manager, and the app plays the hard links Content Hub creates in the
app's own folder. It would declare `audio`, `video`, `content_exchange`,
`keep-display-on` and `networking`, all of which `click-review` accepts.
Under D13 the aim is to leave `networking` out as well: streams are fetched
by media-hub, not by the app. Whether they still play without the group is
to be tried when a confined build is made.

## Listing

To be written. Constraints already known:

- Name: GemPlayer. Package `gemplayer.yenis`; permanent once published.
- The text may say "modelled on VLC for Android" but must not use the VLC name
  as the app's own, nor the cone.
- Licence GPL-3.0 or later, with a public source link.
- Privacy statement: the app does nothing over the network except play a
  stream the user gives it an address for (D13); the system's player fetches
  it.
