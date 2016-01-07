#!/bin/bash

source "$1"

# Parses two dates by heuristics (a bit dangerous I know), but if you give it as yyyy-mm-dd it would be fine
# then give back a discrete interval of days with a day spacing
function enumerate_dates(){
    start_date="$1"
    end_date="$2"
    start_date_sec="$(date --date "$start_date" +%s)"
    end_date_sec="$(date --date "$end_date" +%s)"
    (( cur_date = start_date_sec ))
    while [[ $cur_date -le $end_date_sec ]]; do
	date --date="@${cur_date}" +"%Y-%m-%d"
	cur_date=$(( cur_date + 60*60*24 ))
    done

}

function previous_month(){
   cur=$1
   prev_month=$(( (cur - 1) % 12  ))
   if [[ "$prev_month" == "0" ]]; then
       echo 12
   else
       echo "$prev_month"
   fi
}

function date_init(){
    true
}
