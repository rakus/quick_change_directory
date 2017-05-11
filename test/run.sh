#!/bin/bash
#
# FILE: run.sh
#
# ABSTRACT: 
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-10
#

script_dir=$(cd "$(dirname $0)" 2>/dev/null; pwd)
script_name="$(basename "$0")"
script_file="$script_dir/$script_name"

cd "$script_dir"

for shell in bash ksh; do
    if which $shell >/dev/null 2>&1; then
        for fn in test-*.sh; do
            echo "Running $shell $fn"
            $shell ./$fn
            if [ $? -ne 0 ]; then
                exit 1
            fi
        done
    else
        echo "Shell $shell not found -- skipping tests"
    fi
done

#---------[ END OF FILE run.sh ]-----------------------------------------------
