#!/bin/bash

# A module gets some files passed, which have to be sourced, from then on the module system is initialized and modules can be loaded
source "$1"


# provides ok, error, info, debug
load_module messages
load_module checks
load_module cache

# When error is called, help is automatically executed
function emr_help(){
    usage=$(cat <<EOF
emr lib is a shell library to communicate with aws emr.
It enables the user to run remote hadoop jobs.

Synopsis:
   emr_start_cluster "TestClusterBla" "BigDataCloudKey" "m3.xlarge" 3
   emr_wait_starting_cluster "TestClusterBla"

   emr_setup "TestClusterBla" <keypair_path>

   emr_put "somejob.jar" "~/jobs/"

   emr_job "~/jobs/somejob.jar" arg1 arg2 arg3

   emr_hive <<SCRIPT
        SELECT SUM(t.col) FROM (
		      SELECT 1+1 AS col
	    UNION ALL SELECT 2+2 AS col
            UNION ALL SELECT 3+3 AS col
        ) t;

    SCRIPT


   emr_ssh ls
   emr_stop_cluster "TestClusterBla"
   emr_cleanup

   # Different flow
   emr_generic_setup
   emr_ssh ls
   emr_cleanup

Description:

    emr_generic_setup -- Sets up a emr for BigData_Platform and use whatever key works.
    emr_setup <cluster_name> <keypair_path> - setup the keypair and cluster_id env vars for later usage
    emr_start_cluster <clustername> <keyname> <instancetype> <instance-count> <subnetid>
    emr_stop_cluster <clustername>
    emr_add_task_workers <clustername> <instancetype> <instance-count> <max-price> - add <instance-count> workers of <instancetype> till <max-price>
    emr_remove_workers <clustername> <instancegroup> -- remove the instance group again
    emr_get_spot_price <instancetype> <availability_zone>-- Returns a spot price with a stddev
    emr_put <local> <remote> - put a file with path <local> on the cluster at <remote>
    emr_job <remote> [args] - run a remote hadoop job <remote> with arguments [args]
    emr_hive <heredoc> - run a hive job <heredoc>
    emr_active_cluster <clustername> - find cluster name
    emr_wait_starting_cluster <clustername> -- wait until a cluster started
    emr_ssh <cmd> [args] - run a ssh command <cmd> [args], preserves return value and respects the text interface
    emr_cleanup - cleanup the environment
    emr_cache_clear - clear the emr cache


Prequisites:

    The aws command tool should be installed on your system.
    The jq command tool should be installed on your system (for the usage of emr_active_cluster).

EOF
)
    warning "$usage"
}

function emr_init(){
    debug "Starting up emr library"
    command -v aws > /dev/null 2>&1 || error "AWS should be available"
}


function emr_start_cluster(){
    # First check if a cluster with the name exists

    CLUSTERNAME="$1"
    KEYNAME="${2-BigDataCloudKey}"
    INSTANCETYPE="${3-m3.xlarge}"
    INSTANCECOUNT="${4-3}"
    SUBNETID="${5-subnet-fa93c29f}"

    cluster_id=$(emr_active_cluster "$CLUSTERNAME")

    # Cluster exists, thus return the current id
    if [[ ! -z "$cluster_id" ]]; then
	ok "Cluster already running"
	return 0
    fi
    cluster_id=$(aws emr list-clusters | jq ".[] | map (select (.Name == \"$CLUSTERNAME\" and (.Status.State == \"STARTING\" or .Status.State == \"RUNNING\")).Id) | .[] " | head -n 1 | tr -d '"')

    if [[ ! -z "$cluster_id" ]]; then
	info "Cluster already starting up, waiting"
	return 0
    fi


    aws emr create-cluster --name "$CLUSTERNAME" --release-label emr-4.1.0 \
	--applications Name=Mahout Name=Hue Name=Pig Name=Spark \
	--use-default-roles \
	--ec2-attributes KeyName="$KEYNAME",SubnetId="$SUBNETID" \
	--use-default-roles \
	--region eu-west-1 \
	--instance-type "$INSTANCETYPE" --instance-count "$INSTANCECOUNT" \
        | jq '.ClusterId' | tr -d '"'

}

function emr_stop_cluster(){
    CLUSTERNAME="$1"
    cluster_id=$(emr_active_cluster "$CLUSTERNAME")
    aws emr terminate-clusters --cluster-ids $cluster_id
}


function emr_add_task_workers(){
    CLUSTERNAME="$1"
    INSTANCETYPE="$2"
    INSTANCECOUNT="$3"
    MAXPRICE="$4"
    numeric $MAXPRICE || error "Need a maximum price"

}

function emr_remove_task_workers(){
    INSTANCEGROUP="$1"
}

function emr_get_spot_price(){
    INSTANCETYPE="${1-c3.xlarge}"
    AZ="${2-eu-west-1a}"
    current_time=$(date +"%s")
    end_date=$(date --date="@$current_time" +"%Y-%m-%d")
    end_time=$(echo "$current_time - 60 * 60 * 24 * 7" | bc -l )
    echo "$end_time"
    start_date=$(date --date="@$end_time" +"%Y-%m-%d")
    echo "$start_date"
    echo "$end_date"

    aws ec2 describe-spot-price-history --availability-zone $AZ --start-time "$start_date" --end-time "$end_date" --instance-type "$INSTANCETYPE" --product-descriptions "Linux/UNIX" \
    | jq '.SpotPriceHistory | .[] | .SpotPrice' | tr -d '"' | awk 'BEGIN { first=0; summed=0; n=0; } {if(first == 0){ first=$1 }; summed+=$1; n+=1.0;} END {avg=summed/n; print summed; print n  }'

}
function emr_wait_starting_cluster(){
    CLUSTERNAME="$1"
    ok "Waiting on $CLUSTERNAME"
    while true; do
	clusterid=$(emr_active_cluster "$CLUSTERNAME")
	if [[ ! -z "$clusterid" ]]; then
	    break;
	    ok "Cluster started"
	fi
	sleep 3
	debug "Waiting on cluster $CLUSTERNAME"
    done
    ok "Cluster $CLUSTERNAME started"

}

function emr_cache_clear {
    cache_delete "cluster_id_$1"
    cache_delete "cluster_ip_$1"
}

function emr_active_cluster(){
    CLUSTERNAME="$1"
    cache_get "cluster_id_${emr_name}" || (
         cluster_id=$(aws emr list-clusters | jq ".[] | map (select (.Name == \"$CLUSTERNAME\" and ( .Status.State == \"WAITING\" or .Status.State == \"RUNNING\")).Id) | .[] " | head -n 1 | tr -d '"')
         cache_set "cluster_id_$emr_name" 86400 "$cluster_id"
         cache_get "cluster_id_${emr_name}"
    )
}

function emr_check_keys(){
    [[ -z "${emr_id}" ]] && return 1
    [[ -z "${emr_key}" ]] && return 1
    return 0
}

function emr_master_ip(){
    local local_emr_id
    local_emr_id="$1"
    local_emr_name="$2"
    cache_get "cluster_ip_${local_emr_name}" || (
	for i in $(seq 1 10); do
	    dns_name=$(aws emr describe-cluster --cluster-id "${local_emr_id}" | jq " .[] | .MasterPublicDnsName" | tr -d '"')
	    if [[ "$?" == "0" ]]; then
		cache_set "cluster_ip_${local_emr_name}" 86400 "$dns_name"
		cache_get "cluster_ip_${local_emr_name}"
		return 0
	    fi
	    x=$((i * 10))
	    warning "Retrying retrieval of cluster ip in $x seconds"
	    sleep $x

	done
	error "Cannot obtain ip of cluster"
    )

}

function aws_emr_ssh(){
    [[ -z "${emr_id}" ]] && error "Need an emr id"
    [[ -z "${emr_key}" ]] && error "Need an emr key"
    debug "Connecting with ssh to $emr_id with key $emr_key"
    for i in $(seq 1 10); do
	dns="$(emr_master_ip "${emr_id}" "${emr_name}" )"
	ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i "${emr_key}" "hadoop@${dns}" "$@"
	res=$?
	if [[ "$res" != 255 ]]; then
	    return "$res"
	else
	    x=$((i * 10))
	    warning "Retrying operation with cleared cluster_id in $x seconds"
	    sleep $x
	    emr_cache_clear "$emr_name"
	    emr_id_lookup="$(emr_active_cluster "$emr_name")"
	    export emr_id="$emr_id_lookup"
	    cache_set "cluster_id_$emr_name" 86400 "$cluster_id"
	    dns=$(emr_master_ip "$emr_id" "$emr_name")
	    cache_set "cluster_ip_$emr_name" 86400 "$dns"

	fi
    done

}

function aws_emr(){
    subcommand="$1"
    shift
    [[ -z "${emr_id}" ]] && error "Need an emr id"
    [[ -z "${emr_key}" ]] && error "Need an emr key"
    debug "$emr_id"
    for i in $(seq 1 10); do
	aws emr "$subcommand" --cluster-id "$emr_id" --key-pair-file "$emr_key" "$@"
  res=$?
	if [[ $res != 255 ]]; then
	    return "$res"
	else
      x=$((i * 10))
	    warning "Retrying operation with cleared cluster_id in $x seconds"
      sleep $x
	    emr_cache_clear "$emr_name"
	    emr_id_lookup="$(emr_active_cluster "$emr_name")"
	    export emr_id="$emr_id_lookup"
	    cache_set "cluster_id_$emr_name" 86400 "$cluster_id"
	fi
    done
}

function emr_setup(){
    # declare -g would be cleaner
    export emr_name="$1"
    emr_id_lookup="$(emr_active_cluster "$emr_name")"
    export emr_id="$emr_id_lookup"
    export emr_key="$2"
    debug "Starting emr_setup"
    if [[ -z "$emr_id" ]]; then
	unset emr_id
	unset emr_key
	error "Need cluster id to work"
	return 1;
    fi

    if [[ -z "$emr_key" || ! -r "$emr_key" ]]; then
	unset emr_id
	unset emr_key
	error "Need a keypair file, which is readable"
	return 1;
    fi
    debug "emr setup done."
}


function emr_hive_raw(){
    emr_ssh hive "$@"
}

function emr_hive(){
    CMD=""
    while read line; do
	CMD+=("$line")
    done
    output="$(
   emr_ssh hive "$@" <<EOF
${CMD[@]}
EOF
)"
    res="$?"
    echo "$output" | grep -E -v "^hive>" || true
    return $res
}

function emr_cleanup(){
    emr_name=$1
    unset emr_key
    unset emr_id
    cache_delete "cluster_id_${emr_name}"
    cache_delete "cluster_ip_${emr_name}"
    debug "Cleaned up env variables"
}

function emr_put(){
    debug "Putting $1 to $2"
    aws_emr put --src "$1" --dest "$2" || error "Something went wrong"
    debug "Succesfully transfered $1 to $2"

}

function emr_hadoop_streaming(){
    emr_ssh hadoop-streaming "$@"
}

function emr_job(){
    emr_ssh hadoop jar "$@"
}

# because aws emr ssh outputs the ssh cmd it executes on stdout, we need to filter it out.
# aws_emr ssh --command lala | grep -E -v ...
# This has a problem, it doesn't preserve return value.
# To achieve this, we need to run aws_emr ssh --command and then capture directly its return value.
# The first attempt was like:
# output=$(aws_emr ssh --command)
# res=$?
# This sucks, because it breaks the line for line interface of unix and it will hog memory.
# Thus to do it correctly, we run the command in a subshell, capture in the subshell the return value and pipe it to file.
# The subhsell output is filtered by grep -E -v ...
# after the subshell exits, the grep will exit. Then the result is read out from the file,
# and given back to the user.
# And finally we will remove the file.
# This preserves return values and the text interface.
#
# It seems to be slow to communicate through a file, but this is not a problem. Tmpfs is based on ramfs in linux and fully kept in memory, thus
# it is a valid way to do IPC.
# The subshell creation is also not straining the system extra. A normal pipeline, e.g.:
# A | B | C
# Will actually be executed like:
# (A ) | ( B ) | C
#
# Thus subshell creation is ok here, and will happen anyway.
function emr_ssh(){
    # List of arguments needs to be passed as single string
    local arguments_as_string="$*"

    aws_emr_ssh "${arguments_as_string}"
    res=$?

    if [[ "$res" == "0" ]]; then
	    ok "Succesfully executed command"
    fi
    return $res

}
