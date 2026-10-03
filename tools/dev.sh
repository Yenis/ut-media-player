#!/bin/bash
# Drives GemPlayer on a phone connected over adb, through the development
# remote in qml/dev/Remote.qml. See docs/DEVELOPING.md.
#
#   tools/dev.sh deploy            build, install, restart the app
#   tools/dev.sh restart           restart the app, with the remote switched on
#   tools/dev.sh cmd <command...>  send one command, e.g. cmd open /home/phablet/Videos/x.mp4
#   tools/dev.sh shot <name>       have the app photograph itself; saved as build/shots/<name>.png
#   tools/dev.sh log [seconds]     the app's recent log lines, without the usual noise
#   tools/dev.sh switch <app id>   bring another app to the front, e.g. calculator.ubports_calculator_4.1.0
#
# Commands sent closer together than half a second overwrite each other; `cmd`
# waits long enough by itself.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHOTS="$ROOT/build/shots"
PHONE_CACHE=/home/phablet/.cache/gemplayer.yenis
VERSION=$(grep -o '"version": "[^"]*"' "$ROOT/manifest.json" | cut -d'"' -f4)
APP="gemplayer.yenis_gemplayer_$VERSION"
SESSION='export XDG_RUNTIME_DIR=/run/user/$(id -u); export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus;'
NOISE='libertine|AppArmor policy prevents|propsReply|nmReply|error calling result|XMLHttpRequest: Using GET|AalMediaPlayerControl::(state|mediaStatus|position|duration)|Timers cannot be'

number() { echo $(( $(date +%s%N) / 1000000 % 100000000 )); }

switch_to() {
    adb shell "$SESSION timeout 5 gdbus call --session --dest com.lomiri.URLDispatcher \
        --object-path /com/lomiri/URLDispatcher --method com.lomiri.URLDispatcher.DispatchURL \
        'application:///$1.desktop' ''" > /dev/null
}

restart() {
    # `clickable install` leaves the old process running the old QML, and
    # `lomiri-app-launch` hangs over adb: stop the process by hand and start
    # the app through the URL dispatcher.
    adb shell 'for p in $(pgrep -f "qmlscene -I qml qml/Main.qml"); do
        case "$(readlink /proc/$p/cwd)" in *gemplayer.yenis*) kill $p;; esac; done'
    sleep 1
    # The remote only switches on if this file exists when the app starts.
    adb shell "mkdir -p $PHONE_CACHE/shots; echo '0 none' > $PHONE_CACHE/dev-remote.txt"
    switch_to "$APP"
}

case "$1" in
    deploy)
        cd "$ROOT" && clickable build 2>&1 | grep -E 'Successfully|rror'
        clickable install 2>&1 | grep -E 'rror'
        restart ;;
    restart)
        restart ;;
    cmd)
        shift
        adb shell "echo '$(number) $*' > $PHONE_CACHE/dev-remote.txt"
        sleep 0.7 ;;
    shot)
        mkdir -p "$SHOTS"
        adb shell "rm -f $PHONE_CACHE/shots/$2.png; echo '$(number) shot $2' > $PHONE_CACHE/dev-remote.txt"
        sleep 1.5
        adb pull "$PHONE_CACHE/shots/$2.png" "$SHOTS/$2.png" 2>&1 | tail -1 ;;
    log)
        adb shell "journalctl --user --since '-${2:-20}sec' --no-pager 2>/dev/null" \
            | grep -E 'aa-exec|qmlscene' | grep -v -E "$NOISE" \
            | sed -E 's/^(... .. )(..:..:..) [^ ]+ [^ ]+: /\2 /' | cut -c1-300 ;;
    switch)
        switch_to "$2" ;;
    *)
        sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
