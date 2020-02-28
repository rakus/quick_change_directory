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

script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
script_name="$(basename "$0")"

[ -z "$QC_DIR" ] && QC_DIR=$HOME/.qc

LST="$QC_DIR/qc-index.list"

usage()
{
    echo >&2 "USAGE: $script_name [-E] [-i dir] [index...]"
    echo >&2 ""
    echo >&2 "   -E      Don't update extension index(es)."
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
    typeset str="$*"
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
    typeset e
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

typeset -a INC_UPD
while getopts ":Ei:" o "$@"; do
    case $o in
        i)
            d=$OPTARG
            d="${d%"${d##*[!/]}"}"
            INC_UPD+=( -i "$d" )
            ;;
        E)
            ignExt=true
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
# shellcheck disable=SC2013
for ln  in $(cat "$LST"); do
    ln=$(trim_str "$ln")
    if [[ "$ln" = \#* ]] || [ -z "$ln" ]; then
        continue
    fi
    #echo "LN: $ln"
    if ! eval "ARGS=( $ln )"; then
        echo >&2 "Error parsing: $ln"
        exit 1
    fi

    if [ $ignExt ]; then
        case "${ARGS[0]}" in
            *.index.ext) continue ;;
            *.index.ext.$HOSTNAME) continue ;;
        esac
    fi

    case "${ARGS[0]}" in
        *.index) : ;;
        *.index.ext) : ;;
        *.index.$HOSTNAME) : ;;
        *.index.ext.$HOSTNAME) : ;;
        *) echo >&2 "Ignoring ${ARGS[0]}"
            continue
            ;;
    esac

    if [ $# -gt 0 ]; then
        # ZSH: Arrays are 1-based
        if ! contained "${ARGS[0]}" "$@"; then
            continue
        fi
    fi

    if [ ${#INC_UPD[@]} -gt 0  ]; then
        # ZSH: Arrays are 1-based
        tmpargs=("${ARGS[0]}")
        tmpargs+=( "${INC_UPD[@]}")
        tmpargs+=("${ARGS[@]:1}")
        ARGS=("${tmpargs[@]}")
    fi

    # ZSH: Arrays are 1-based
    echo "Updating ${ARGS[0]}..."
    #(set -x;$script_dir/qc-index-proc.sh "${ARGS[@]}")
    if ! "$script_dir/qc-index-proc.sh" "${ARGS[@]}"; then
        exit 1
    fi
done
IFS="$oifs"

