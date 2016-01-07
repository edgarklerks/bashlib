#!/bin/bash

source "$1"
load_module colors

function messages_init {
    true
}

function general_message {
    if [[ ! $(flag_set :quiet) ]]; then
	fg="$1"
	bg="$2"
	style="$3"
	mark="$4"
	message="$5"
	read -a styles <<< "$style"

	for st in "${styles[@]}"; do
	    style "$st"
	done

	color "$bg" "$fg"
	printf "[%s] %s\n" "$mark" "$message"
	reset_color
    fi >&2

}

if [[ $(flag_set :debug) ]]; then

    function debug {
	general_message cyan default bold "d" "$1"
    }

else

    function debug {
	return 0
    }
fi

function ok {
    general_message green default bold "+" "$1"
}

function info {
    general_message blue default bold "?" "$1"
}
function error {
    general_message red default bold "-" "$1"
    is_function $HELP_HANDLER
    if [[ $? == 0 ]]; then
	$HELP_HANDLER
	exit 1
    fi
    exit "${2-1}"
}

function warning {
    general_message yellow default bold "!" "$1"
}
