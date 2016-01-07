#!/bin/bash
_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$_SCRIPTDIR/bashcore.sh"

# load_module libtest
load_module emr


echo "$(emr_master_ip "j-1LA88QK7S9NWZ")"

# set_help_handler

# emr_wait_starting_cluster "BigData_Platform"
# emr_setup "BigData_Platform" "$HOME/.ssh/BigDataCloudKey.pem"


# should_succeed emr_ssh_ls exit 0
# should_fail emr_ssh_ls_not_existing emr_ssh exit 1

# emr_ssh ls /asdsasadsad
