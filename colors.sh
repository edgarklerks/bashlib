#!/bin/bash

source "$1"

default_color="default"
range1="black red green yellow blue magenta cyan lightgray"
range2="darkgray lightred lightgreen lightyellow lightblue lightmagenta lightcyan white"
stylerange="none bold dim italic underline blink not_used_wup inverted hidden crossed"

style_range_extended="double_underline normal steady positive"

function define_style() {
    let style_idx=$1 || true
    read -a styles <<< "$2"
    for style in "${styles[@]}"; do
	eval "export ${style}=$style_idx"

	(( style_idx++ )) || true
    done
}

function define_color_range {
    let start=$1 || true
    read -a colors <<< "$2"
    export_all "$colors"
    for num in "${colors[@]}"; do
          eval "${num}[0]=$start"
          (( nextcolor = start + 10 ))
          eval "${num}[1]=$nextcolor"
       (( start++ ))
    done
}

function rgb_fg {
   echo -en "\e[38;2;$1;$2;$3m"
}

function rgb_bg {
    echo -en "\e[48;2;$1;$2;$3m"
}



function reset_color {
    echo -en "\e[39;49m"
    tput el
}

function reset_style {
    echo -en "\e[21;22;24;25;27;28m"
    tput el
}

function reset_all {
    color default default
    echo -en "\e[0m"
    tput sgr0
    tput el
}

function style {
   pstyle=$(arg_by_name_scalar "$1")
   echo -en "\e[${pstyle}m"
}

function color {
    bgcolor=$(arg_by_name_map 1 "$1")
    fgcolor=$(arg_by_name_map 0 "$2")
    echo -en '\e'"[${bgcolor};${fgcolor}m"
}

function colors_init {
    define_color_range 39 "$default_color"
    define_color_range 30 "$range1"
    define_color_range 90 "$range2"
    define_style 0 "$stylerange"
    define_style 21 "$style_range_extended"
}

function flag(){
    i=1
    COLORS=("" "$1" "$2" "$3")
    while [ $i -le 3 ]; do
	j=1
	color "${COLORS[i]}" "${COLORS[i]}"
	while [ $j -le 5 ]; do
	    printf "LOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOL\n"
	    j=$(( j + 1 ))
	done
	i=$(( i + 1 ))
    done
    reset_all

}
