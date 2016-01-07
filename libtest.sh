#!/bin/bash

source "$1"
echo "$1"

load_module messages

# Set this flag to get extra output
# set_flag :debug

typeset -i FAILED=0
typeset -i SUCCEEDED=0
typeset -i TOTAL=0

function libtest_init(){
    FAILED=0
    SUCCEEDED=0
    TOTAL=0
}

function expected(){
    name="$1"
    result="$(echo "$2" | command sed -e 's/[[:space:]]*$//')"
    expect="$(echo "$3" | command sed -e 's/[[:space:]]*$//')"
    (( TOTAL++ )) || true
    if [[ "$result" == "$expect" ]]; then
	ok "test $name passed!"
	(( SUCCEEDED ++ )) || true
	return 0
    else
	warning "test $name failed: $result != $expect"
	(( FAILED ++ )) || true
	return 1
    fi
}

function should_fail(){
    name="$1"
    shift
    (( OLD_FAILED = FAILED ))
    (( OLD_TOTAL = TOTAL ))
    (( OLD_SUCCEED = SUCCEEDED ))
    output="$(eval "$@")"
    run="$?"
    (( SUCCEEDED = OLD_SUCCEED ))
    (( FAILED = OLD_FAILED ))
    (( TOTAL = OLD_TOTAL ))
    (( TOTAL++ )) || true
    if [[ "$run" != "0" ]]; then
	ok "test $name failed as expected"
	(( SUCCEEDED ++ )) || true
	return 0
    else
	warning "test $name didn't fail as expected: $output"
	(( FAILED ++ )) || true
	return 1
    fi
}

function should_succeed(){
    name="$1"
    shift
    (( TOTAL++ )) || true
    (( OLD_FAILED = FAILED )) || true
    (( OLD_TOTAL = TOTAL )) || true
    (( OLD_SUCCEED = SUCCEEDED )) || true
    output="$(eval "$@")"
    run="$?"
    (( SUCCEEDED = OLD_SUCCEED )) || true
    (( FAILED = OLD_FAILED )) || true
    (( TOTAL = OLD_TOTAL )) || true

    if [[ "$run" == "0" ]]; then
	(( SUCCEEDED ++ )) || true
	ok "test $name succeeded as expected"
	return 0
    else
	warning "test $name didn't succeed as expected: $output"
	(( FAILED ++ )) || true
	return 1
    fi
}

function print_stats(){
    if [[ "$FAILED" == "0" ]]; then
	ok "All tests passed!"
	ok "$FAILED/$SUCCEEDED/$TOTAL (fail/succes/total)"
	return 0
    else
	error "Some tests failed, please check the ouput:"
	error "$FAILED/$SUCCEEDED/$TOTAL (fail/succes/total)"
	return 1
    fi
}

# Mock commands, just output the options passed
# It also catches common gotchas (like using a raw hadoop command)

function can_pipe(){
    local -i READLINE=0
    while read line; do
	echo "$line"
	READLINE=1
    done
    if (( READLINE == 1 )); then
	echo "pipe"
    fi

}

# Some meta test (these are horrible to look at)
warning "Some meta tests may look like they fail (e.g. test dummy ..), but these are actually the tests of the tests"
should_succeed should_fail_succeed should_fail dummy true
should_fail should_succeed_fail should_succeed dummy false
should_fail should_fail_fail should_fail dummy true
should_succeed should_succeed_succeed should_succeed dummy true

should_succeed expect_succeed expected dummy "111" "111"
should_fail expect_fail expected dummy "111" "112"
