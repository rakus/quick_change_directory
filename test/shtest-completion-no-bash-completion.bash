#!/usr/bin/env bash
#
# FILE: shtest-completion-no-bash-completion.bash
#
# ABSTRACT: test bash completion without bash_completion support loaded
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2020-10-14
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

shopt -s expand_aliases

# DO NOT load bash-completion
# declare -F _completion_loader &>/dev/null || {
#     # shellcheck disable=SC1091
#     [ -e /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion
# }

# make sure no function _get_comp_words_by_ref exists
unset -f "_get_comp_words_by_ref"

export BUILD_TEST_DIRS=true
# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

# disable -u because of bash completion functions
set +u

TEST_STATUS=0

# Prints completions, one per line
# $*: mvn command line
get_completions(){
    local COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS COMPREPLY=()

    COMP_LINE=$*
    COMP_POINT=${#COMP_LINE}

    #eval set -- "$@"

    COMP_WORDS=("$@")

    # add '' to COMP_WORDS if the last character of the command line is a space
    [[ "$COMP_LINE" = *' ' ]] && COMP_WORDS+=('')

    # index of the last word
    COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))

    # execute completion function
    __qc_complete > "$COMP_LOG_FILE" 2>&1

    # print completions to stdout
    printf '%s\n' "${COMPREPLY[@]}" | LC_ALL=C sort
}

#export -f get_completions __qc_complete

COMP_LOG_FILE="$TEST_DIRECTORY/_comp.log"

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

    cat /dev/null > "$COMP_LOG_FILE"
    printf "qc %s -> %s " "${args[*]}" "${expected[*]}"
    mapfile -d$'\n' -t result < <(get_completions qc "${args[@]}")
    if [ -s "$COMP_LOG_FILE" ]; then
        ERROR
        echo >&2 "   Completion produced output:"
        sed 's/^/   /' "$COMP_LOG_FILE"
        echo >&2
        return
    fi

    if [ "${expected[*]}" = "${result[*]}" ]; then
        OK
    else
        ERROR
        echo "   Expected: ${expected[*]}"
        echo "   Got:      ${result[*]}"
    fi
}

startTest "BASH Completion WITHOUT bash-completion support"

echo -n "Check fallback functions for completion are loaded"
if declare -f __qc_complete_get_cur_and_words | grep -q COMP_WORDS; then
    OK
else
    ERROR
fi

qc -U

dstore :label "$TEST_DIRECTORY/Customer/ACME"

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

test_completion "white" -- "whitespace dir/"

test_completion NotThere

test_completion :la -- "label"

test_completion :la A -- "Admin/"

endTest

