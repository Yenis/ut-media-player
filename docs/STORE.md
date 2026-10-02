# OpenStore notes

Working notes for the submission in Phase 6 of [PLAN.md](PLAN.md). The listing
text and screenshots are added when there is a player to describe. What is
recorded from the start is the confinement: which permissions the app asks
for, why, and what `click-review` says about each.

## Policy groups

As of version 0.0.1, checked with `click-review` in the Clickable 24.04 build
image on 2 October 2026.

| Policy group | Why the app needs it | `click-review` |
|---|---|---|
| `audio` | Playing sound through the system media service | Accepted |
| `video` | Playing video through the system media service | Accepted |
| `content_exchange` | Receiving files that other apps hand over ("Open with") | Accepted |
| `keep-display-on` | Keeping the screen on while a video plays | Accepted |
| `networking` | Opening network streams by address | Accepted |
| `music_files_read` | Listing and playing everything in `~/Music` and the SD card's `Music` folder without importing each file | **Reserved: needs manual review** |
| `video_files_read` | The same for `~/Videos` and the SD card's `Videos` folder | **Reserved: needs manual review** |

The two reserved groups are what makes a library possible: a media player that
could only play files handed to it one by one through Content Hub would have no
library, no folders and no "continue watching". They grant read access only,
and only to the Music and Videos folders. The stock Music app uses
`music_files_read` for the same reason.

If a reviewer refuses them, the fallback is Content Hub import: the app keeps
its own copies of imported files and builds its library from those.

## Not requested

| Policy group | Why not |
|---|---|
| `music_files`, `video_files` (write access) | The app never changes media files. Deleting and renaming from inside the app would need them, and compiled code as well; that is undecided |
| `content_exchange_source` | Sharing a file to another app. Added if and when sharing is built |

## Listing

To be written. Constraints already known:

- Name: GemPlayer. Package `gemplayer.yenis`; permanent once published.
- The text may say "modelled on VLC for Android" but must not use the VLC name
  as the app's own, nor the cone.
- Licence GPL-3.0 or later, with a public source link.
- Privacy statement: nothing leaves the device except the addresses of streams
  the user opens.
