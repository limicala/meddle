#!/bin/sh
export ROOT=$(cd `dirname $0`; pwd)
export SKYNET_DIR="$ROOT/skynet"

function export_process_env(){
    [ ! -d "$ROOT/run" ] && mkdir -p "$ROOT/run" && mkdir -p "$ROOT/run/logs"
    export PROCESS_RUN_PATH=$(cd "$ROOT/run";pwd)
    [ -f "$PROCESS_RUN_PATH/run.pid" ] && rm "$PROCESS_RUN_PATH/run.pid"
    export PROCESS="$SKYNET_DIR/skynet $ROOT/config.lua"
    [ ! -d "$PROCESS_RUN_PATH/shell.log" ] && touch "$PROCESS_RUN_PATH/shell.log"
    export SHELL_LOG="$PROCESS_RUN_PATH/shell.log"
}

start_process(){
    export_process_env
    echo "" > "$SHELL_LOG"

    local process_info=$(ps aux | grep -v grep | grep "$PROCESS" | awk '{print "pid: "$2"   process: "$11"  "$12}')
    if [ -n "$process_info" ]
    then
        echo -e "\nThe process is already running:\n$process_info\n"
        exit
    fi

    export DAEMON="true"
    export STARTMODE="$2"

    $PROCESS
}

cmd=$1
shift
case "$cmd" in
    start)           start_process    ;;
esac