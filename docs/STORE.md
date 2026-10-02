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

**These groups are not enough.** The spike showed that they let the app list
`~/Music` and `~/Videos` and get thumbnails, but not play anything from them
and not read the media library: media-hub and mediascanner each allow that
only to a short list of package names, whatever the policy groups say. See
"Why playback and the library fail" in [TESTING.md](TESTING.md).

What the package asks for therefore depends on decision D12 in
[PLAN.md](PLAN.md). If the app goes unconfined, this table is replaced by one
line, the `unconfined` template, and the reviewer's question becomes why; the
answer is the paragraph above.

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
