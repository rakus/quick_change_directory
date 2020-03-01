#!/bin/bash
#
# FILE: run.sh
#
# ABSTRACT: run qc tests
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-10
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

cd "$script_dir" || exit 1

function run_tests
{
    shell="$1"
    if command -v "$shell" >/dev/null 2>&1; then
        for fn in test-*.sh; do
            echo "Running $shell $fn"
            if ! $shell "./$fn"; then
                echo >&2 "$shell: Test FAILED"
                exit 1
            fi
        done
    else
        echo "Shell $shell not found -- skipping tests"
    fi
}


run_tests bash


echo
echo "ALL test successful"

#---------[ END OF FILE run.sh ]-----------------------------------------------
