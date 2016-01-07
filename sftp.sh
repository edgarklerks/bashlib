#!/bin/bash

# A module to communicate to sftp over a shell script

source "$1"

load_module messages
load_module checks

function sftp_help(){

    usage=$(cat <<EOF
sftp lib contains a couple of procedures to
to communicate with a sftp server.

Description:
   sftp_login <host> <user> <password> -- Log into a sftp server
   sftp_logout <cmd> -- log out of the server

   sftp_cmd <cmd> -- run an arbitrary sftp command

   sftp_is_dir <path> -- check if a path is a directory
   sftp_is_file <path> -- check if a path is a file

   sftp_ls -- show file listing
   sftp_ls_l -- show detailed file listing
   sftp_ls_r -- recursive file listing

   sftp_put -- copy a file from local to remote
   sftp_get -- copy a file from remote to local



EOF
)

    warning "$usage"
}

function sftp_init(){
    true
}

function sftp_put(){
    true
}

function sftp_login(){
    _SFTP_HOST="$1"
    _SFTP_USER="$2"
    _SFTP_PASSWORD="$3"
}

function sftp_logout(){
    unset _SFTP_HOST
    unset _SFTP_USER
    unset _SFTP_PASSWORD
}

function sftp_cmd(){
    (
    assert ensure "$_SFTP_HOST" non_empty
    assert ensure "$_SFTP_USER" non_empty
    assert ensure "$_SFTP_PASSWORD" non_empty
    ) || error "Need to run sftp_login first"
    cmd="$1"
    shift

    expect -f "$DIR/expect/$cmd.exp" -- -host=$_SFTP_HOST -passwd=$_SFTP_PASSWORD -user=$_SFTP_USER "$@"
}

function sftp_is_dir(){
    path="$1"
    sftp_cmd sftp_ls_l  "$(dirname "$path")"   | grep "$(basename "$path")" | grep -E "^d"  >/dev/null 2>&1

}


function sftp_ls(){
    sftp_cmd sftp_ls "$@"
}

function sftp_ls_r(){
    sftp_cmd sftp_recurs_ls "$@"
}

function sftp_is_file(){
   inverse sftp_is_dir "$@"
}

function sftp_is_executable(){
    path="$1"
    sftp_cmd sftp_ls_l "$(dirname "$path")" | grep "$(basename "$path")" | grep -E "^[d\-]{1}[r\-]{1}x"
}
