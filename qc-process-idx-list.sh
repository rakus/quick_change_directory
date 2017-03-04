#!/bin/bash
#
# FILE: qc-process-idx-list.sh
#
# ABSTRACT: Reads qc-index.list and builds indexes using qc-create-idx.sh.
#
# Content of qc-index.list are the command line parameters used for
# qc-create-idx.sh. Each line describes one call of that script.
# Empty lines and lines starting with '#' are ignored.
#
# See 'qc-create-idx.sh --help'.
#
# Example qc-index.list:
#
#    # create index of $HOME
#    test.index $HOME -- '.*' CVS
#    
#    # create index of home that only containing hidden directories (and their childs)
#    test.hidden.index.ext -f '*/.*' $HOME -- .settings .git .svn .hg '.jazz*' .bzr .qc .cp .cache CVS
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-03-02
#

script_dir=$(cd "$(dirname $0)" 2>/dev/null; pwd)
script_name="$(basename "$0")"
script_file="$script_dir/$script_name"

LST="$script_dir/qc-index.list"

usage()
{
    echo >&2 "USAGE: $script_dir [-i dir]"
    echo >&2 ""
    echo >&2 "   -i dir  Incremental update the given dir in the affected index(es)."
    echo >&2 "           Indexes that does not contain the dir are not touched."
    echo >&2 ""
    exit 1
}

trim_str() {
    local str="$*"
    # remove leading whitespaces
    str="${str#"${str%%[![:space:]]*}"}"
    # remove trailing whitespaces
    str="${str%"${str##*[![:space:]]}"}"   
    echo -n "$str"
}

INC_UPD=
while getopts ":i:" o "$@"; do
    case $o in
        i)
            if [ -n "$INC_UPD" ]; then
                echo >&2 "Duplicate '-i'."
                exit 1
            fi
            INC_UPD=$OPTARG
            INC_UPD="${INC_UPD%"${INC_UPD##*[!/]}"}"
            ;;
        *)
            [ "${!OPTIND}" != "--help" ] && echo >&2 "can't parse: ${!OPTIND}" && echo >&2 ""
            usage
            ;;
    esac
done

export QC_LIST_UPD=true

oifs="$IFS"
IFS=$'\n'
for ln  in $(cat "$LST"); do
    ln=$(trim_str "$ln")
    if [[ "$ln" = \#* ]] || [ -z "$ln" ]; then
        continue
    fi
    #echo "LN: $ln"
    eval "ARGS=( $ln )"
    if [ $? -ne 0 ]; then
        echo >&2 "Error parsing: $ln"
        exit 1
    fi

    if [ $INC_UPD ]; then
        tmpargs=("${ARGS[0]}")
        tmpargs+=(-i "$INC_UPD")
        tmpargs+=("${ARGS[@]:1}")
        ARGS=("${tmpargs[@]}")
    fi

    echo "Updating ${ARGS[0]}..."
    #(set -x;$script_dir/qc-create-idx.sh "${ARGS[@]}")
    ($script_dir/qc-create-idx.sh "${ARGS[@]}")
done

