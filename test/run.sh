#!/bin/sh
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

test_shells=""

run_tests()
{
    shell="$1"
    if command -v "$shell" >/dev/null 2>&1; then
        test_shells="$test_shells$shell "
        echo "============================================================"
        echo "Testing with $shell ($($shell --version 2>&1 | head -n1))"
        for fn in test-*.sh test-*."$shell"; do
            if [ -e "$fn" ]; then
                echo "Running $shell $fn"
                if ! $shell "./$fn"; then
                    echo >&2 "$shell: Test FAILED"
                    exit 1
                fi
            fi
        done
    else
        echo "Shell $shell not found -- skipping tests"
    fi
}

if [ $# -eq 0 ]; then
    set -- bash
elif [ $# -eq 1 ] && [ "${1}" = "all" ]; then
    set -- bash ksh zsh
fi

for shell in "$@"; do
    run_tests "$shell"
done

echo
echo "Tested with $test_shells"
echo
echo "ALL test successful"

#---------[ END OF FILE run.sh ]-----------------------------------------------
