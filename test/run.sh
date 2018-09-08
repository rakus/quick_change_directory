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

script_dir=$(cd "$(dirname "$0")" 2>/dev/null; pwd)

cd "$script_dir"

for shell in ksh bash; do
    if which $shell >/dev/null 2>&1; then
        for fn in test-*.sh; do
            echo "Running $shell $fn"
            $shell "./$fn"
            if [ $? -ne 0 ]; then
                echo >&2 "$shell: Test FAILED"
                exit 1
            fi
        done
    else
        echo "Shell $shell not found -- skipping tests"
    fi
done
echo
echo "ALL test successful"

#---------[ END OF FILE run.sh ]-----------------------------------------------
