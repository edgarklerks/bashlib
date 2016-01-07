#!/bin/bash
# Bootstrap our bash library

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# This will expose a simple module system. A module is a source file, which can load other module and export certain variables
# It also allows to look up an argument by name

function is_function {
   fname="$1"
   ftype=$(type -t "$fname")
   if [ "$ftype" == "function" ]; then
       return 0
   fi
   return 1
}

function set_help_handler(){
    export HELP_HANDLER="$1"
}

function load_module {


    source "$DIR/$1.sh" "$DIR/bashcore.sh" "$2" "$3" "$4"

    # Run the module init
    init_func="$1_init"
    export HELP_HANDLER="$1_help"
    res=is_function "$init_func" 2>/dev/null
    if [[ $res ]]; then
	$init_func
    fi
}

# This is still defunct, somehow we need to be able to declare functions private to a module. Not sure how.
function private {
    for k in "$@"; do
	private_symbols+=($k)
    done;
}

function public {
    for k in "$@"; do
	public_symbols+=($k)
    done;
}

function export_all {
    read -a symbols <<< "$1"
    for exp in "${symbols[@]}"; do
	eval "declare -x $exp"
    done
}
function arg_by_name_map {
    index="$1"
    map="$2"
    ret=$(eval "echo \${$map[$index]}")
    echo "$ret"
}

function set_arg_by_name {
    argname="$1"
    eval "$argname=$2"
}

function arg_by_name_scalar {
    argname="$1"
    ret=$(eval "echo \${$argname}")
    echo "$ret"
}

function flag_set {
    flag="$1"
    echo "$CORE_FLAG" | grep "$flag"
}

function set_flag {
    flag="$1"
    CORE_FLAG="$CORE_FLAG $flag"
}

function unset_flag {
    flag="$1"
    CORE_FLAG=$(echo "$CORE_FLAG" | grep -v "$flag")
}

function fasthash {
    data="$1"
    res=$(echo "$data" | cksum)
    echo "${res% *}"
}
function trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}
function init_vars {
    CURRENT_USERNAME=$(whoami)
    PROJECTROOT="$DIR/../.."
    SCRIPTSDIR="$DIR/.."
    LIBDIR="$DIR"
    TMPDIR="/tmp"

    # Dirty fix
    if [[ "$TERM" == "rxvt-unicode-256color" ]]; then
	export TERM="xterm"
    fi

}
contains_element () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}
silently(){
	"$@" >/dev/null 2>/dev/null
}
# Initialize variables we use
init_vars
