#!/bin/bash

functional_init(){
    true
}

stream(){
    local i
    for i in "$@"; do
	echo $i
    done
}


take_from(){
    needle="$1"
    shift
    out=0
    for token in "$@"; do
	if [[ $out == "1" ]]; then
	    printf "%s\n" "$token"
	else
	    if [[ "$token" == "$needle" ]]; then
		out=1
	    fi

	fi
    done
}

# Filter a stream with a function
# Usage: echo "test.gz" | filter ends_with "gz"
filter(){
    while read ln; do
	if "$@" "$ln" >/dev/null 2>&1; then
	    echo "$ln"
	fi
    done

}

# make a function on a stream into a normal function
unmap(){
    local -i n
    array=( "$@" )
    n=${#array[@]}
    (( n = n - 1 ))
    val="${array[$n]}"
    unset "array[$n]"
    echo "$val" |  "$@"


}

# lift an function in a stream
map(){
    while read ln; do
	"$@" "$ln"
    done
}
