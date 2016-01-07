#!/bin/bash

source "$1"
load_module messages


function backup_init(){
    # These two paths should be a mirror of each other
    HDFS_DIR="/mnt/hdfs"

    # prefix length of /mnt... part, which need to be stripped of
    HDFS_PRE_LEN=${#HDFS_DIR}
    (( HDFS_PRE_LEN++ ))

    # Some directory on the disk
    CHECKFILE="/sources/fi/sac/sanoma/2015/08/29"


}

function backup_help(){
    HELP=$(cat <<EOF
The backup lib contains a toolset for translating file paths between hdfs and s3 and
various tools to calculate differences between sources.

There are three file spaces, where filenames can reside:

The symbolic space, this is the path without prefixes, it can be projected into the s3 space or the hdfs space by using
the (s3|hdfs)p style functions.

The s3 space, this is the path at s3, it can be projected back into the symbolic space by using s3u.

The hdfs space, this is the path at hdfs, it can be projected back into the symbolic space by using hdfsu

The functions s3p, hdfsp, s3u, hdfsu are subjected to the following laws (under a s3rootpath)

p : symbolic => (s3u . s3p) p  = p
p : s3 => (s3p . s3u) p = p

p : symbolic => (hdfsu . hdfsp) p = p
p : hdfs => (hdfsu . hdfsp) p = p

Description:

   get_file_list <dir> [ignore_pats] -- get a list of files of <dir>, while ignoring certain patterns
   get_dir_list <dir> [ignore_pats] -- get a list of dirs of <dir>, while ignoring certain patterns
   sets3root <dir> -- set the s3 root path
   s3p <dir> -- translate a name from the symbolic space to the s3 space
   s3u <dir> -- translate a name from the s3 space to the symbolic space
   hdfsp <dir> -- translate a name from the symbolic space to the hdfs space
   hdfsu <dir> -- translate a name from the hdfs space to the symbolic space
   hdfss3t <dir> -- translate a name from the hdfs space to the s3 space
   s3hdfst <dir> -- translate a name from the s3 space to the hdfs space

   check_both_mounted -- Checks if both fs are mounted and if they are reachable for the current user

   must_be_backed -- Checks if a file should be copied between hdfs and s3

EOF
)
    warning "$HELP"
}

# Get directory list and file list
# The user should be aware that he will get a list in the s3 or hdfs space
# and that he need to marshall between the two himself.
function get_file_list(){
    if [[ ! -z "$2" ]]; then
	find "$1" -type f -and -not -regex "$2"
    else

	find "$1" -type f
    fi
}

function get_dir_list(){
    if [[ ! -z "$2" ]]; then
	find "$1" -type d -and -not -regex "$2"
    else

	find "$1" -type d
    fi

}

function sets3root(){
    S3_DIR="$1"
    S3_PRE_LEN=${#S3_DIR}
    (( HDFS_PRE_LEN++ ))

}

# gives the path on the s3 side
function s3p(){
    path="$1"
    echo "${S3_DIR}${path}"
}

# gives the path on the hdfs side
function hdfsp(){
    path="$1"
    echo "${HDFS_DIR}${path}"
}

function hdfss3t(){
    sym="$(hdfsu "$1")"
    s3="$(s3p "$sym")"
   # Now we need to check that:
   # (hdfsp . s3u) s3 == "$1"

    [[ "$(hdfsp "$(s3u "$s3")")" == "$1" ]]  || error "Error, hdfss3t invariant doesn't hold for hdfspath: $1"
    echo "$s3"
}

function s3hdfst(){
    sym="$(s3u "$1")"
    hdfs="$(hdfsp "$sym")"

    # (s3p . hdfsu) hdfs == "$1"
    [[ "$(s3p "$(hdfsu "$hdfs")")" == "$1" ]] || error "Error, s3hdfst invariant doesn't hold for s3path: $1"
    echo "$hdfs"
}

# Back from  s3
# law $(s3u $(s3p bla)) == bla
function s3u(){
    path="$1"
    echo "$path" | cut -c $S3_PRE_LEN-
}

# Back from hdfs
# law $(hdfsu $(hdfsp bla)) == bla
function hdfsu(){
    path="$1"
    echo "$path" | cut -c $HDFS_PRE_LEN-
}


function file_size(){
    stat --printf="%s" "$1"
}

# Check if a symbolic name has to be moved from the hdfs side to the
# s3 side


function must_be_backed(){
    sympath="$1"
    s3path="$(s3p "$sympath")"
    hdfspath="$(hdfsp "$sympath")"

    if [[ -e "$s3path" && -d "$s3path" ]]; then
	return 1
    fi

    if [[ -e "$s3path" && -r "$s3path" ]]; then

	hsize=$(file_size "$hdfspath")
	ssize=$(file_size "$s3path")

	(( hsize == ssize )) && return 1
    fi

    return 0

}


# This function will check if both filesystems are mounted (s3 and hdfs).
# This is done by checking if a common file exists.

function check_hdfs_mounted(){
    spath=$(hdfsp "$CHECKFILE")
    if [[ ! -e "$spath" ]]; then
	warning "$spath not found"
	warning "Please mount hdfs first"
	exit 1
    fi

    ok "hdfs is mounted"
}
