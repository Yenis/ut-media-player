# VLC for Android - feature survey

What VLC for Android does, read from the reference clone, and what each feature
needs on Ubuntu Touch. This is the list GemPlayer is built against; the phases
in [PLAN.md](PLAN.md) take their items from here.

Surveyed on 2 October 2026.

| What | Value |
|---|---|
| Clone | `vlc-android/`, from `https://github.com/videolan/vlc-android` |
| Commit | `e0d3fe77b`, 1 October 2026 |
| Version | 3.7.2 Beta 2 (`build.gradle`) |
| Licence | GPLv2 or later (`README.md`, `COPYING`, file headers) |
| Not in the clone | `libvlcjni/` (the libVLC bindings) and the native media library are fetched by VLC's build scripts. Anything defined there is marked **[not in clone]** |

Paths below are shortened:

- `src/...` is `vlc-android/application/vlc-android/src/org/videolan/vlc/...`
- `res/...` is `vlc-android/application/vlc-android/res/...`
- `strings.xml` and `arrays.xml` are in
  `vlc-android/application/resources/src/main/res/values/`

## Verdicts

The goal is every VLC feature, where feasible. Each feature gets one verdict:

| Verdict | Meaning |
|---|---|
| **Build** | Own QML over the system backend. Nothing known stands in the way |
| **Spike Sn** | Buildable if spike row Sn in [PLAN.md](PLAN.md) passes on the Pixel 3a |
| **Discuss** | The system backend does not offer it. Not dropped: when the work reaches it, we decide together whether another route is worth trying |
| **Dropped** | Decided against: by D13 in [PLAN.md](PLAN.md) (nothing over the network except playing streams), or as not needed |
| **N/A** | Tied to Android itself; has no counterpart on Ubuntu Touch |

---

## Modules in the clone

| Module | What it holds | Use to us |
|---|---|---|
| `application/vlc-android` | The phone app: 359 source files, 166 layouts | The reference |
| `application/resources` | Strings (1450 in English), arrays, colours, icons, shared constants | Strings and option lists |
| `application/tools` | `Settings` and the preference keys | Names and defaults of settings |
| `application/mediadb` | Room database: browser favourites, external subtitles, equalizer presets, widgets | Shape of the app's own data |
| `medialibrary` | Java wrapper over VLC's native media library | Ignored; MediaScanner replaces it |
| `application/television` | Android TV interface | Ignored |
| `application/remote-access-server`, `remote-access-client` | Web remote control | Dropped (D13) |
| `application/moviepedia` | Film and series metadata lookup | Dropped (D13) |
| `application/donations`, `live-plot-graph`, `app` | Donations, the statistics graph, app entry point and tests | Ignored |

Packages inside `src/`:

| Package | Holds |
|---|---|
| `gui/video` | Video player and video library |
| `gui/audio` | Audio player and audio library |
| `gui/browser` | File, storage and network browsers, file picker |
| `gui/dialogs` | Sleep timer, jump to time, speed, tracks, equalizer, save playlist, display settings, context sheet |
| `gui/preferences` | Settings screens; their content is in `res/xml/preferences*.xml` |
| `gui/network` | Stream URL panel |
| `gui/helpers` | Player options menu, bookmarks, key handling, tips |
| `media` | `PlaylistManager` (queue, resume, repeat, shuffle) and `PlayerController` |
| `PlaybackService.kt` | The background service that owns playback |
| `viewmodels`, `providers`, `repository` | Data behind the lists |

---

## Screens and navigation

The app has five bottom tabs (`res/menu/bottom_navigation.xml`).

| Tab | Content | Source |
|---|---|---|
| Video | Grid or list of videos, optionally grouped by folder or by name | `src/gui/video/VideoGridFragment.kt` |
| Audio | Tabs: Artists, Albums, Tracks, Genres, Playlists | `src/gui/audio/AudioBrowserFragment.kt` |
| Browse | Favourites, local storages, network shares | `src/gui/browser/MainBrowserFragment.kt` |
| Playlists | Audio and video playlists | `src/gui/PlaylistFragment.kt` |
| More | Streams, History, Settings, About | `src/gui/MoreFragment.kt` |

Screens reached from them:

| Screen | Source |
|---|---|
| Video player, with its queue, option menu and overlays | `src/gui/video/VideoPlayerActivity.kt` and the delegates beside it |
| Audio player: a mini bar on every screen that expands to full screen with the queue | `src/gui/audio/AudioPlayer.kt` |
| Album, artist, genre and playlist detail | `src/gui/HeaderMediaListActivity.kt`, `src/gui/audio/AudioAlbumsSongsFragment.kt` |
| Folder and group content | `src/gui/video/VideoGridFragment.kt` |
| File browser with path bar | `src/gui/browser/FileBrowserFragment.kt`, `PathAdapter.kt` |
| Search across the library | `src/gui/SearchActivity.kt` |
| Media information | `src/gui/InfoActivity.kt` |
| Settings and its sub-screens | `src/gui/preferences/` |
| Equalizer | `src/gui/dialogs/EqualizerFragmentDialog.kt` |

---

## Video player

### Gestures

Source: `src/gui/video/VideoTouchDelegate.kt`. Settings and defaults:
`res/xml/preferences_video_controls.xml`.

| Feature | Behaviour in VLC | Verdict |
|---|---|---|
| Single tap | Shows or hides the controls, after the double-tap window has passed | Build |
| Double tap, sides | Left quarter of the width seeks back, right quarter forward, 10 s by default. Further taps add up and the overlay shows the total | Build. A jump lands on the keyframe before its target **[device]**: forward it can fall short, backward it can go further than 10 s |
| Double tap, centre | Play or pause | Build |
| Horizontal swipe | Seeks on release; see [Values worth matching](#values-worth-matching) | Build. A seek lands on the keyframe before the target and takes 0.4 to 1.5 s **[device]**, so the overlay shows the target and the position is corrected once the seek lands |
| Vertical swipe, right | Volume. VLC changes the system media volume | Build: the system volume, through the sound indicator **[device]**. The player's own volume is ignored by the backend |
| Vertical swipe, left | Screen brightness | Build: the real backlight, through the power indicator **[device]**; restored when the player is left. Darkens the picture instead where that is not available |
| Pinch | Out switches to "Fit screen", in returns to the previous mode | Build |
| Tap and hold | Plays at 2x while held ("fast play"), off by default | Discuss (needs playback speed) |
| Three-finger swipe | Screenshot, off by default | Build |
| Each gesture can be switched off | Seven toggles in the settings | Build |
| Drag on a 360° video | Moves the viewpoint; pinch changes field of view | Discuss |

### Controls on screen

Source: `res/layout/player_hud.xml`, `player_hud_right.xml`,
`src/gui/video/VideoPlayerOverlayDelegate.kt`.

| Feature | Behaviour in VLC | Verdict |
|---|---|---|
| Auto-hiding controls | Hide after 4 s by default, adjustable | Build |
| Title, time, length, seek bar | As expected | Build |
| Play, previous, next | Previous and next act on the queue | Build |
| Rewind and forward buttons | Optional. 10 s on tap, 20 s on long press, both adjustable | Build |
| Lock | Hides the controls and ignores touches until unlocked by a swipe | Build |
| Orientation button | Locks to the current orientation; a setting chooses automatic, portrait, landscape, reverse landscape or last locked | Build, by rotating the player's own content. The system's rotation follows the user's rotation lock **[device]**, which a video player has to override |
| Aspect button | Tap cycles the main modes, long press lists all twelve | Build |
| Tracks button | Audio track, subtitle track, video track, pick a subtitle file, download subtitles | External subtitles: Spike S10. Download: Dropped (D13). The rest: Discuss |
| Queue button | Shows the play queue over the video | Build |
| Quick-action chips | Appear when sleep timer, speed, a delay or orientation lock is active; tap to change | Build for sleep and orientation |
| Brightness, volume and info overlays | Vertical bar with a percentage; short text for seek and aspect changes | Build |
| Keep screen on while playing | Implied on Android | Build. media-hub holds the display on for a video by itself **[device]** |
| Fullscreen, hiding system bars | Yes | Build **[device]** |

### Player menu

Source: `src/gui/helpers/PlayerOptionsDelegate.kt`. The same menu serves the
audio player with a different set of entries.

| Entry | Behaviour in VLC | Verdict |
|---|---|---|
| Lock | As above | Build |
| Sleep timer | Time picker, with "Wait for current media item to finish first" and "Reset on any interaction". A default duration can be set | Build. Works while the app is in front; behind the lock screen the app is frozen and the timer fires late. Fixing that is Discuss |
| Playback speed | 0.25x to 8x in 0.01 steps, for this media or all media | Discuss |
| Jump to time | Hours, minutes, seconds | Build |
| Equalizer | Presets and custom bands, saved per preset | Discuss |
| Play as audio | Video only. Leaves the video screen; playback continues in the audio player | Build. The same player carries on with its picture hidden **[device]**. With the screen off: still Spike S6 |
| Play as video | Audio player only, shown when the file has a video track | Build **[device]** |
| Pop-up player | Video in a floating window | Discuss |
| Repeat | None, one, all; "all" is skipped when the queue has one item | Build |
| Shuffle | Offered when the queue has more than two items | Build |
| Video information | Codec, resolution, bitrate graphs | Build for what the metadata gives; live statistics are Discuss |
| Go to chapter | Shown when the file has chapters | Discuss |
| Bookmarks | Add at the current time, rename, delete, jump to previous or next; markers on the seek bar | Build. Renaming waits for Phase 4 |
| A-B repeat | Mark A, mark B, loop; markers on the seek bar; reset | Build |
| Save playlist | Saves the current queue as a playlist | Build |
| Digital audio passthrough | For external receivers | Discuss |
| Lock or unlock with PIN | Part of parental control | Build, low priority |
| Control settings | Shortcut to the gesture and button settings | Build |
| Share track info | Audio only | Spike S12 |
| Tips | Guided tour of the gestures and controls | Build, low priority |

### Other video behaviour

| Feature | Behaviour in VLC | Source | Verdict |
|---|---|---|---|
| Resume position | Saved per file. Setting: always, never, or ask. The prompt reads "Resume from last position?" with a "do this for all" box | `src/media/PlaylistManager.kt`, `VideoPlayerActivity.kt` | Build |
| Seen marker | A file played to the end is marked seen, its play count goes up and its position resets | `PlaylistManager.kt` `saveMediaMeta` | Build |
| When the app is left | Setting with three choices: stop (default), play as audio in background, picture-in-picture | `arrays.xml` `video_app_switch_action_titles` | Stop and play as audio: Spike S5, S6. PiP: Discuss |
| Restore video from background | Returning to the app reopens the video screen | `res/xml/preferences_video.xml` | Build |
| Aspect modes | Best fit, Fit screen, Fill, Center, 16:9, 4:3, 16:10, 2:1, 2.21:1, 2.35:1, 2.39:1, 5:4. The last one used is remembered | `src/gui/video/VideoPlayerResizeDelegate.kt` | Build |
| Audio delay, subtitle delay | 50 ms steps; audio delay can be saved per file or for Bluetooth | `src/gui/video/VideoDelayDelegate.kt` | Subtitle delay: Build (our own subtitle drawing). Audio delay: Discuss |
| Audio boost | Volume up to 200% | `VideoTouchDelegate.kt` | Discuss |
| Video queue | Play a folder as a queue; "Video playlist mode" plays all videos in order | `preferences_ui.xml` `playlist_mode_video` | Build |
| Screenshot | Button or gesture; saves a frame | `src/gui/video/VideoPlayerScreenshotDelegate.kt` | Build. `grabToImage` returns the real picture **[device]** |
| Keyboard | Space, arrows, media keys and letter shortcuts | `VideoPlayerActivity.kt` `onKeyDown` | Build |
| Hardware acceleration, deblocking, frame skip, preferred resolution, fast seek | Decoder settings | `res/xml/preferences.xml`, `preferences_adv.xml` | Discuss (the backend decides these itself) |
| Secondary display, cast to a renderer | Chromecast and presentation displays | `src/RendererDelegate.kt` | Dropped (D13) |

### Subtitles

| Feature | Behaviour in VLC | Source | Verdict |
|---|---|---|---|
| External subtitle file | Loaded automatically when it sits beside the video; can be picked by hand | `preferences_subtitles.xml` `subtitles_autoload`, `src/gui/browser/FilePickerFragment.kt` | Build **[device]** |
| Embedded subtitle tracks | Listed and selectable | `src/gui/dialogs/VideoTracksDialog.kt` | Discuss. media-hub never draws them and does not list them **[device]** |
| Styling | Size (seven steps), bold, colour, opacity, background, shadow, outline, and six presets | `res/xml/preferences_subtitles.xml` | Build, for subtitles we draw |
| Text encoding, preferred language | Settings | same | Encoding: Build. Preferred language applies to embedded tracks: Discuss |
| Download subtitles | Searches an online service by file | `src/gui/dialogs/SubtitleDownloaderDialogFragment.kt` | Dropped (D13) |

---

## Audio player

Source: `src/gui/audio/AudioPlayer.kt`, `res/layout/audio_player.xml`,
`res/xml/preferences_audio.xml`, `preferences_audio_controls.xml`.

| Feature | Behaviour in VLC | Verdict |
|---|---|---|
| Mini player | Bar on every screen with title, progress, play and pause; swipe sideways for previous and next; expands to full screen | Build |
| Full player | Cover, title, artist, seek bar, time and length, previous, play, next, shuffle, repeat | Build. Added to it, which VLC does not have for audio: the video player's gestures on the cover (double tap and swipe to seek, swipes for volume and brightness) |
| Blurred cover background | On by default | Build |
| Rewind and forward | 10 s on tap, 20 s on long press, adjustable | Build, 10 s on tap only. The long press is dropped (Yenis, 7 October 2026) |
| Hold play to stop | Long press on play stops playback | Dropped (Yenis, 7 October 2026). A cross on the mini-player stops instead |
| Queue | Shown inside the player; search within it, drag to reorder, swipe to remove; elapsed or remaining time for the whole queue | Build |
| Stop after this track | From a queue item's menu | Build |
| Shuffle and repeat | As in the video player; "always shuffle" setting | Build. Shuffle mixes what follows the playing item only: the system's list cannot be changed before it **[device]** |
| Sleep timer, jump to time, A-B repeat, bookmarks, save playlist | Shared with the video player | Build |
| Playback speed, equalizer, chapters | Shared with the video player | Discuss |
| Resume last queue | Queue and position restored on launch; a card offers to resume | Build |
| Background playback | Continues with the screen off and under other apps | Build **[device]**. media-hub runs the queue while the app is suspended, for audio only: a video's picture does not survive being played from a list |
| System controls | Notification, lock screen with cover, headset and Bluetooth buttons | Build for what the system gives: play, previous and next in the sound indicator, under the name "Media Player" **[device]**. Our own name, icon and cover there: Discuss (compiled MPRIS service) |
| Headset | Pause when unplugged, optional resume when plugged in | Spike S11 |
| Pause for calls, lower volume for notifications | Audio focus | Spike S5 (media-hub may do this for us) |
| Replay gain | Track or album mode, pre-amp, peak protection | Discuss |
| Audio output choice, time stretching | Decoder settings | Discuss |

---

## Library

### Video library

Source: `src/gui/video/VideoGridFragment.kt`,
`src/viewmodels/mobile/VideosViewModel.kt`.

| Feature | Behaviour in VLC | Verdict |
|---|---|---|
| Grid or list | Thumbnail, title, duration, resolution, progress bar, seen marker | Build **[device]** |
| Grouping | None, by folder, or by name (videos with a common name prefix) | Build |
| Manual groups | Add to group, rename, ungroup, regroup automatically | Build |
| Sorting | Name, file name, length, date, last modified, date added; ascending or descending | Build |
| Only favourites | Filter | Build |
| Item menu | Play, play from start, play all, play as audio, insert next, add to queue, add to playlist, add to group, mark as played or unplayed, information, share, delete, rename, go to folder, add or remove favourite, download subtitles | Build, except: delete and rename are Spike S2 (write access), share is Spike S12, download subtitles is Dropped (D13) |
| Multiple selection | Long press starts it; the same actions apply to the selection | Build |
| Default action on tap | Per list: play, play all, add to queue or insert next | Build |

### Audio library

Source: `src/gui/audio/AudioBrowserFragment.kt`,
`src/gui/audio/AudioAlbumsSongsFragment.kt`.

| Feature | Behaviour in VLC | Verdict |
|---|---|---|
| Artists, albums, tracks, genres | Each a tab, grid or list, with a fast scroller and letter headers | Spike S3 |
| Playlists tab | The same playlists as the Playlists tab | Build |
| Album and artist pages | Header with cover, track list, play all, shuffle all | Spike S3, S4 |
| Sorting | Name, artist, album, length, date, track number; ascending or descending | Build |
| Show all artists, show track numbers | Display options | Build |
| Item menu | Play, play all, insert next, add to queue, add to playlist, information, go to album, go to artist, go to folder, share, delete, add or remove favourite | As for video |
| Set as ringtone | Android only | N/A |

### Shared

| Feature | Behaviour in VLC | Source | Verdict |
|---|---|---|---|
| Search | One query across videos, artists, albums, tracks, genres and playlists; each list also has its own filter | `src/gui/SearchActivity.kt` | Spike S3 |
| Playlists | Create, rename, delete, reorder, remove items, add from anywhere, play, shuffle | `src/gui/PlaylistFragment.kt`, `src/gui/dialogs/SavePlaylistDialog.kt` | Build |
| Favourites | Mark media and folders; "only favourites" filter | `ContextOption.kt` | Build |
| History | Recently played, newest first; play, add to queue, clear. Can be switched off | `src/gui/HistoryFragment.kt` | Build |
| Incognito mode | Nothing is written to history or resume points | `PlaylistManager.kt` `savePosition` | Build |
| Media information | Path, size, tracks, duration | `src/gui/InfoActivity.kt` | Build for what the metadata gives |
| Library folders | Choose which folders are scanned; rescan on start | `res/xml/preferences.xml` | Dropped (3 October 2026): MediaScanner scans fixed places, and a choice would take a scanner of our own. Grouping by folder and the Browse tab cover the need |
| Metadata lookup | Posters and summaries for films and series | `application/moviepedia` | Dropped (D13) |

### Browse

Source: `src/gui/browser/`.

| Feature | Behaviour in VLC | Verdict |
|---|---|---|
| Local storage browser | Folders and files with a path bar; play a file or a whole folder | Build. The app being unconfined (D12), it reads any folder |
| Removable storage | SD card and USB | Build: what is mounted under `/media/<user>`. Not yet seen with a card |
| Favourite folders | Pinned at the top of the tab | Build |
| Show hidden files, folders first | Display options | Build |
| Add folder to playlist | This folder, or with subfolders | Build |
| Network shares | SMB, NFS, FTP, FTPS, SFTP, UPnP discovery; saved servers with login | Dropped (D13) |

### Streams

Source: `src/gui/network/MRLPanelFragment.kt`.

| Feature | Behaviour in VLC | Verdict |
|---|---|---|
| Open a stream by address | Text field; plays on enter | Build; the one use of the network D13 keeps. HLS and MP4 over `https` play **[device]**; a dead address gives no error, so the app sets its own time limit |
| Stream history | Past addresses; play, rename, delete, copy, add to playlist | Build |
| Open from other apps | Links and files handed over by the system | Build **[device]** |

---

## Settings

Every key and default is in `res/xml/preferences*.xml`. The ones that apply to
us follow the verdict of the feature they control. Settings with no feature
behind them:

| Setting | Options in VLC | Verdict |
|---|---|---|
| Theme | Follow system, light, black | Build |
| Language | Per-app language | Build if translations ship; otherwise the system language |
| Long titles | Default, cut left, right or middle, or scroll | Build |
| Show video thumbnails, show seen marker, show headers | Display toggles | Build |
| Export and restore settings | To a file | Spike S2 |
| Clear history, clear app data | Yes | Build |
| Parental control | PIN. "Safe mode" blocks deleting files and changing playlists without the PIN; access to the settings can be restricted too | Build, low priority |
| Debug log | Viewer and export | Build, low priority |

---

## Other

| Feature | What it is | Verdict |
|---|---|---|
| Remote access | A web page served by the phone, to browse and control playback from another device | Dropped (D13) |
| Home-screen widgets | Three widget styles | N/A |
| Android Auto | Car interface | N/A |
| Android TV interface | Separate module | N/A |
| Launcher shortcuts | Pin a media to the home screen | N/A |
| Permission onboarding | Storage and notification permissions | N/A (confinement is declared in the package) |
| Nightly installer, donations | Distribution extras | N/A |
| First-run welcome and theme choice | `src/gui/onboarding/` | Build, low priority |

---

## Discuss list, grouped by what it would take

The Discuss rows above, grouped by the one thing that would unlock each group.
None is decided; each is raised when the work reaches it.

| What would unlock it | Features |
|---|---|
| A playback engine that exposes more than QtMultimedia 5 does (libVLC, or GStreamer driven from compiled code) | Playback speed and fast play, equalizer, audio delay, audio boost, audio and embedded-subtitle track selection, chapters, replay gain, passthrough, decoder settings, 360° video, live statistics |
| A platform capability | Pop-up player and picture-in-picture |

Network shares, remote access, casting, subtitle download and film metadata
were on this list until D13 dropped them; choosing library folders until it
was dropped as not needed.

---

## Values worth matching

Read from `src/gui/video/VideoTouchDelegate.kt` unless another file is named.

| What | Value |
|---|---|
| Double-tap zones | Left quarter and right quarter of the width seek; everything between plays or pauses |
| Double-tap seek length | 10 s (`video_double_tap_jump_delay`) |
| Rewind and forward buttons | 10 s, long press 20 s (`video_jump_delay`, `video_long_jump_delay`) |
| Seek overlay | Stays 750 ms after the last tap |
| Controls timeout | 4 s (`video_hud_timeout_in_s`) |
| Edge margin | Gestures starting within 24 dp of a screen edge are ignored |
| Swipe direction | Vertical when the slope is steeper than 2:1, and only after moving 5% of the screen height |
| Vertical zones | Right of 4/7 of the width is volume, left of 3/7 is brightness, the middle seventh does nothing. If one of the two is switched off, the other takes both sides |
| Vertical range | A swipe over 80% of the screen height covers the full range |
| Seek swipe, dead zone | Nothing under 1 cm of travel; a swipe starting in the rightmost 5% of the screen is ignored |
| Seek swipe, length | `sign × (600 000 × (cm / 8)⁴ + 3000) / k` milliseconds, so 8 cm is 10 minutes. The seek happens on release; the overlay shows `+0:42 (12:10)` while dragging |
| Seek swipe, fine control | `k` grows as the finger drifts vertically from where it started, dividing the jump; the overlay then adds `x0.5` and so on |
| Fast play | Starts after 250 ms of holding; 2.0x by default |
| Delay steps | 50 ms (`src/gui/video/VideoDelayDelegate.kt`) |
| Speed range | 0.25x to 8x, buttons step 0.01 (`src/gui/dialogs/PlaybackSpeedDialog.kt`) |
| Repeat order | None, one, all, none (`src/gui/helpers/PlayerOptionsDelegate.kt`) |
| Aspect cycle on tap | The "main" modes, defined in libVLC **[not in clone]**; the full list of twelve is in `VideoPlayerResizeDelegate.kt` |
| Defaults | Resume: always. On leaving the app: stop. Volume, brightness, swipe seek, pinch, double-tap seek and double-tap pause: on. Fast play, screenshot, seek buttons: off |

## Strings and layouts worth adapting

GemPlayer is GPL-3.0 or later (D5 in [PLAN.md](PLAN.md)), so these may be
adapted, with credit to VLC for Android in the README and the copyright notice
kept on any adapted file.

| What | Where | Why |
|---|---|---|
| English strings | `strings.xml` | Menu entries, setting titles and summaries, and prompts are already short and consistent: "Play as audio", "Resume from last position?", "Wait for current media item to finish first" |
| Translations | `values-*/strings.xml` beside it, 76 languages | The same keys, if GemPlayer is translated later |
| Option lists | `arrays.xml` | Orientation, resume confirmation, subtitle sizes and presets, theme |
| Player layout | `res/layout/player_hud.xml` | Order and grouping of the controls |
| Player menu | `res/layout/player_options.xml`, `PlayerOptionsDelegate.kt` | Order of entries |
| Tips | `src/gui/video/VideoTipsDelegate.kt`, `res/layout/player_tips.xml` | The gesture tutorial's steps and wording |
| Icons | `application/resources/src/main/res/drawable/` | Vector icons under the same licence. The cone and the VLC name stay out (D4) |
