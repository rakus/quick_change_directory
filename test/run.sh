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

for fn in test-*.sh; do
    echo "Running $fn"
    ./$fn
    if [ $? -ne 0 ]; then
        exit 1
    fi
done

#---------[ END OF FILE run.sh ]-----------------------------------------------
