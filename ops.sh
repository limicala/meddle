#!/bin/bash
export ROOT=$(cd `dirname $0`; pwd)
export SKYNET_DIR="$ROOT/skynet"
export PROJECT_NAME="meddle"

export_process_env(){
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

do_exec(){
    docker exec -ti $PROJECT_NAME bash
}

do_build(){
    docker-compose build
}

do_stop(){
    docker-compose --project-name $PROJECT_NAME stop $PROJECT_NAME
}

do_start(){
    do_stop
    if [ "$1" != "" ];
    then
        export MEDDLE_ARG="$1"
    fi
    docker-compose --project-name $PROJECT_NAME up -d
}

cmd=$1
shift
case "$cmd" in
    local_start)           start_process        ;;
    build)                 do_build             ;;
    start)                 do_start             ;;
    stop)                  do_stop              ;;
    r)                     do_start "console"   ;;
    exec)                  do_exec              ;;
esac
