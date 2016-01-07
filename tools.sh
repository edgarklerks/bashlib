#!/bin/bash

source "$1"

function tools_init(){
    true
}

to_lower(){
    awk '{print tolower($0)}'
}

to_upper(){
    awk '{print toupper($0)}'
}

stream(){
    local i
    for i in "$@"; do
	echo $i
    done
}

uniq_var(){
    echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

}

open_fd(){
    fn=$(mktemp)
    eval "exec $1$2$fn"
    trap "exec $1>&-; rm $fn" SIGINT SIGTERM
}


close_fd(){
    eval  "exec $1>&-"
}

anon_fifo(){
    PIPE=$(mktemp -u)
    mkfifo $PIPE
    eval "exec $1$2$PIPE"
    trap "exec $1>&-; rm $PIPE" SIGINT SIGTERM
    rm $PIPE

}

close_fifo(){
    eval "exec $1>&-"
}

slurp_fifo(){
    stop_token=$(uniq_var)

    echo $stop_token >&"$1"

    while read p; do
	if [[ "$p" == "$stop_token" ]]; then
	    exit
	fi
	echo "$p"
    done <&"$1"
}

result(){
    read p
    _result="$p"
}
