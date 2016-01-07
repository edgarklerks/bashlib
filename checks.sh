#!/bin/bash

source "$1"

load_module tools
load_module messages

function checks_init(){
    true
}

checks_help(){
    info "A check failed"
}

run_when(){
    check="$1"
    shift
    value="$1"
    shift

    ensure $value $check && "$@"



}

ensure(){
  check="$1"
  shift
  for i in $@; do
      $i $check
  done
}

numeric(){
    silently <<EOF
test "$1" && printf "%f" "$1" 1>&2 >/dev/null
EOF
}

non_empty(){
    test -n "$1"
}

octal(){
    res=$(printf "0%o" "$1")
    [[ $res == "$1" ]]
}


hexadecimal(){
    res=$(printf "0x%X" $(echo "$1" | awk '{ print toupper($0) }' ))
    echo "$res"
    tst=$(stream "$1" | to_upper)
    echo "$tst"
    [[ $res == $(stream "$1" | to_upper) ]]
}

is_assoc_array(){
   ( typeset -p "$1" | grep -E "^declare -A $1" ) >/dev/null 2>&1
}


is_array(){
   ( typeset -p "$1" | grep -E "^declare -a $1" ) >/dev/null 2>&1
}

is_readable(){
    x="$1"
    [[ -r "$x" ]]
}

is_file(){
    x="$1"
    [[ -f "$x" ]]
}

is_dir(){
    x="$1"
    [[ -d "$x" ]]
}

is_writeable(){
    x="$1"
    [[ -w "$x" ]]
}

is_executable(){
    x="$1"
    [[ -x "$x" ]]
}

ends_with(){
    val="$1"
    shift
    echo "$@" | grep -E "$val\$" >/dev/null 2>&1
}

contains(){
    val="$1"
    shift
    echo "$@" | grep -E "$val" >/dev/null 2>&1

}
assert(){
    "$@"
    if [[ "$?" == "0" ]]; then
	return 0
    fi
    error "Assertion failed: $*"
    exit 1

}

inverse(){
    "$@" && return 1
    return 0
}
