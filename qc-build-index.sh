#!/bin/bash
#
# FILE: qc-build-index.sh
#
# ABSTRACT: Reads qc-index.list and builds indexes using qc-index-proc.sh.
#
# Content of qc-index.list are the command line parameters used for
# qc-index-proc.sh. Each line describes one call of that script.
# Empty lines and lines starting with '#' are ignored.
#
# See 'qc-index-proc.sh --help'.
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

LST="$HOME/.qc/qc-index.list"

usage()
{
    echo >&2 "USAGE: $script_dir [-i dir] [index...]"
    echo >&2 ""
    echo >&2 "   -i dir  Incremental update the given dir in the affected index(es)."
    echo >&2 "           Indexes that does not contain the dir are not touched."
    echo >&2 ""
    echo >&2 "   index   Name of the indexes that should be updated. The given names"
    echo >&2 "           are matched against the index names. So 'home' will match"
    echo >&2 "           'home.index' and 'home.hidden.index.ext'."
    echo >&2 "           To only update extension indexes use '*.ext'."
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

#
# Check whether the first argument is somewhere in the following.
# Used like: contains x.txt "${file[@]}"
#
contained()
{
    local e
    for e in "${@:2}"; do
        case "$1" in
            $e*)
                return 0
                ;;
        esac
    done
    return 1
}
#---------[ MAIN ]-------------------------------------------------------------

INC_UPD=()
while getopts ":i:" o "$@"; do
    case $o in
        i)
            d=$OPTARG
            d="${d%"${d##*[!/]}"}"
            INC_UPD+=( -i "$d" )
            ;;
        *)
            [ "${!OPTIND}" != "--help" ] && echo >&2 "can't parse: ${!OPTIND}" && echo >&2 ""
            usage
            ;;
    esac
done

shift $((OPTIND-1))

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

    if [ $# -gt 0 ]; then
        if ! contained "${ARGS[0]}" "$@"; then
            continue
        fi
    fi

    if [ ${#INC_UPD[@]} -gt 0  ]; then
        tmpargs=("${ARGS[0]}")
        tmpargs+=( "${INC_UPD[@]}")
        tmpargs+=("${ARGS[@]:1}")
        ARGS=("${tmpargs[@]}")
    fi

    echo "Updating ${ARGS[0]}..."
    #(set -x;$script_dir/qc-index-proc.sh "${ARGS[@]}")
    ($script_dir/qc-index-proc.sh "${ARGS[@]}")
done

