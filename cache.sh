#!/bin/bash

source "$1"
load_module messages

function cache_help(){
    usage=$(cat <<EOF
Caching functionality for scripts with a fixed retention time (15 minutes).

Synopsis:

   cache_get "some_value" || (
       # no value
       cache_set "some_value" 1234 "$(do_expensive_calculation)"
       cache_get "some_value"
   )
   cache_delete "some_value"

Description:
   cache_get <key> -- get the key out of the cache, error code 1 means no key
   cache_set <key> <retentiontime> <value 1> <value 2> <value 3> -- set a key to the cache with a retentiontime in seconds

EOF
)
    warning "$usage"
}

function cache_init(){
    debug "Loading cache library"
    CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    HELPDIR="$CURDIR/helpers"

}

function cache_get(){
    key=$1
    shift
    perl "$HELPDIR/cache.pl" "read" "$key"
}

function cache_set(){
    key=$1
    shift
    ret=$1
    shift
    perl "$HELPDIR/cache.pl" "write" "$key" "$ret" "$@"
}

function cache_delete(){
    key=$1
    shift
    perl "$HELPDIR/cache.pl" "delete" "$key"
}
