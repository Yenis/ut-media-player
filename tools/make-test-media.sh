#!/bin/bash
# Generates the test set described in docs/TESTING.md: a synthetic picture
# (testsrc2 shows a running timestamp) and quiet tones, so nothing here is
# anyone's content. Needs ffmpeg with x264, x265, vpx, svtav1, opus, vorbis
# and mp3lame.
#
#   tools/make-test-media.sh         generate into build/test-media/ (about 200 MB)
#   tools/make-test-media.sh push    generate if needed, then copy to the phone over adb,
#                                    into ~/Videos/gemplayer-test and ~/Music/gemplayer-test
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/test-media"

push() {
    adb shell "mkdir -p /home/phablet/Videos/gemplayer-test /home/phablet/Music/gemplayer-test"
    adb push "$OUT/video/." /home/phablet/Videos/gemplayer-test/
    adb push "$OUT/audio/." /home/phablet/Music/gemplayer-test/
}

if [ "$1" = "push" ] && [ -f "$OUT/audio/silence.ogg" ]; then
    push
    exit 0
fi

mkdir -p "$OUT/video" "$OUT/audio"
cd "$OUT"
FF="ffmpeg -hide_banner -loglevel error -y"
V() { echo "testsrc2=size=$1:rate=$2:duration=$3"; }
A() { echo "sine=frequency=$1:duration=$2,volume=0.15"; }

# S1: the smoothness reference.
$FF -f lavfi -i "$(V 1920x1080 30 60)" -f lavfi -i "$(A 440 60)" \
    -c:v libx264 -preset veryfast -profile:v high -pix_fmt yuv420p -b:v 6M \
    -c:a aac -b:a 128k -movflags +faststart video/h264-1080p30.mp4

# S14: codecs and containers.
$FF -f lavfi -i "$(V 1280x720 30 20)" -f lavfi -i "$(A 440 20)" \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a libopus video/h264-opus-720p.mkv
$FF -f lavfi -i "$(V 1920x1080 30 20)" -f lavfi -i "$(A 440 20)" \
    -c:v libx265 -preset veryfast -pix_fmt yuv420p -tag:v hvc1 -c:a aac video/hevc-1080p.mp4
$FF -f lavfi -i "$(V 1280x720 30 20)" -f lavfi -i "$(A 440 20)" \
    -c:v libvpx-vp9 -deadline realtime -cpu-used 8 -b:v 2M -pix_fmt yuv420p -c:a libopus video/vp9-720p.webm
$FF -f lavfi -i "$(V 1280x720 30 20)" -f lavfi -i "$(A 440 20)" \
    -c:v libsvtav1 -preset 10 -pix_fmt yuv420p -c:a aac video/av1-720p.mp4
$FF -f lavfi -i "$(V 1080x1920 30 10)" -f lavfi -i "$(A 440 10)" \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac video/portrait-1080x1920.mp4

# S10: a subtitle file beside the video.
$FF -f lavfi -i "$(V 1280x720 30 60)" -f lavfi -i "$(A 440 60)" \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac video/sidecar.mp4
{
  n=1
  for s in 0 5 10 15 20 25 30 35 40 45 50 55; do
    printf '%d\n00:00:%02d,000 --> 00:00:%02d,000\nSubtitle %d, from %d s\n\n' $n $s $((s+4)) $n $s
    n=$((n+1))
  done
} > video/sidecar.srt

# S16: two audio tracks (eng 440 Hz, deu 880 Hz), two subtitle tracks, chapters.
sed 's/Subtitle/Untertitel/; s/from/ab/' video/sidecar.srt > "$OUT"/gp-deu.srt
cat > "$OUT"/gp-chapters.txt <<EOF
;FFMETADATA1
title=GemPlayer multi-track test
[CHAPTER]
TIMEBASE=1/1000
START=0
END=20000
title=Chapter one
[CHAPTER]
TIMEBASE=1/1000
START=20000
END=40000
title=Chapter two
[CHAPTER]
TIMEBASE=1/1000
START=40000
END=60000
title=Chapter three
EOF
$FF -f lavfi -i "$(V 1280x720 30 60)" -f lavfi -i "$(A 440 60)" -f lavfi -i "$(A 880 60)" \
    -i video/sidecar.srt -i "$OUT"/gp-deu.srt -i "$OUT"/gp-chapters.txt \
    -map 0:v -map 1:a -map 2:a -map 3:s -map 4:s -map_metadata 5 -map_chapters 5 \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac -c:s srt \
    -metadata:s:a:0 language=eng -metadata:s:a:0 title="English 440 Hz" \
    -metadata:s:a:1 language=deu -metadata:s:a:1 title="Deutsch 880 Hz" \
    -metadata:s:s:0 language=eng -metadata:s:s:1 language=deu \
    video/multi-track.mkv
rm -f "$OUT"/gp-deu.srt "$OUT"/gp-chapters.txt

# S6: 35 minutes for the pocket test. Small picture, a short quiet beep every
# 10 s so playback can be heard without being a constant tone.
$FF -f lavfi -i "testsrc2=size=640x360:rate=15:duration=2100" \
    -f lavfi -i "sine=frequency=330:beep_factor=2:duration=2100,volume='if(lt(mod(t,10),0.25),0.25,0)':eval=frame" \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p -crf 30 -c:a aac -b:a 64k \
    -movflags +faststart video/long-35min.mp4

# S14: audio formats, tagged so the library groups them as one album.
T='-metadata artist=GemPlayer -metadata album=GemPlayer-test -metadata genre=Test'
$FF -f lavfi -i "$(A 440 30)" $T -metadata title="MP3 440 Hz"    -metadata track=1 -c:a libmp3lame audio/test-1.mp3
$FF -f lavfi -i "$(A 523 30)" $T -metadata title="FLAC 523 Hz"   -metadata track=2 -c:a flac       audio/test-2.flac
$FF -f lavfi -i "$(A 659 30)" $T -metadata title="Opus 659 Hz"   -metadata track=3 -c:a libopus    audio/test-3.opus
$FF -f lavfi -i "$(A 784 30)" $T -metadata title="Vorbis 784 Hz" -metadata track=4 -c:a libvorbis  audio/test-4.ogg
$FF -f lavfi -i "$(A 880 30)" $T -metadata title="AAC 880 Hz"    -metadata track=5 -c:a aac        audio/test-5.m4a

# A silent loop, for the keep-alive experiment (docs/TESTING.md, run 3).
$FF -f lavfi -i anullsrc=r=44100:cl=mono -t 30 $T -metadata title="Silence" -c:a libvorbis -q:a 0 audio/silence.ogg

ls -la video audio
[ "$1" = "push" ] && push
echo "Done: $OUT"
