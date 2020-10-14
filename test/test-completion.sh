#!/bin/bash
#
# FILE: test-completion.sh
#
# ABSTRACT:
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2020-10-14
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

export BUILD_TEST_DIRS=true
# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

TEST_STATUS=0

test_completion()
{
    typeset -a args
    typeset -a expected
    at_completion=""
    for a in "$@"; do
        if [ "$a" = "--" ]; then
            at_completion="true"
        elif [ -z "$at_completion" ]; then
            args+=( "$a" )
        else
            expected+=( "$a" )
        fi
    done

    readarray -t expected < <(printf '%s\n' "${expected[@]}" | sort )

    printf "qc %s -> %s " "${args[*]}" "${expected[*]}"
    mapfile -d$'\n' -t result < <(quick-change-directory --complete "${args[@]}")

    if [ "${expected[*]}" = "${result[*]}" ]; then
        OK
    else
        ERROR
        echo "   Expected: ${expected[*]}"
        echo "   Got:      ${result[*]}"
    fi


}

startTest "Completion"

qc -U

dstore :label testDirectory/Customer/ACME/Admin

test_completion A Ad -- Admin/
test_completion YoYo -- YoYo/ YoYoDyne/
test_completion YoYo/ -- YoYo/MyProject/
test_completion Cu YoYo -- YoYo/ YoYoDyne/
test_completion Customer YoYo -- YoYo/ YoYoDyne/
test_completion Customer/ YoYo -- YoYo/ YoYoDyne/

test_completion Customer/ -- Customer/ACME/ Customer/YoYo/ Customer/YoYoDyne/

test_completion Customer//A -- Customer//Admin/ Customer//ACME/
test_completion Customer// A -- Admin/ ACME/
test_completion "Customer/**/A" -- "Customer/**/Admin/" "Customer/**/ACME/"
test_completion "Customer/*/A" -- "Customer/*/Admin/"

test_completion NotThere

test_completion :la -- "label"

endTest $TEST_STATUS

