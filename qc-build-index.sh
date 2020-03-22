#!/bin/bash
#
# FILE: qc-build-index.sh
#
# ABSTRACT: Reads qc-index.list and builds indexes.
#
# The content of qc-index.list describes the indexes to create.
# Empty lines and lines starting with '#' are ignored.
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

#script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
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

is_descendant()
{
    typeset e
    for e in "${@:2}"; do
        case "$1" in
            $e)
                return 0
                ;;
            $e/*)
                return 0
                ;;
        esac
    done
    return 1
}

build_index()
{
    typeset IDX_NAME=$1
    shift

    if [ "$IDX_NAME" != "$(basename "$IDX_NAME")" ]; then
        echo >&2 "ERROR: Index name must be a plain filename."
        return 1
    fi

    typeset -a FILTER
    typeset -a INC_UPD
    typeset OPTARG OPTIND=0 d
    while getopts ":f:i:" o "$@"; do
        case $o in
            f) FILTER=( "${FILTER[@]}" "$OPTARG" )
                ;;
            i)
                d=$OPTARG
                d="${d%"${d##*[!/]}"}"
                INC_UPD+=( "$d" )
                ;;
            *)
                return 1
                ;;
        esac
    done

    shift $((OPTIND-1))

    typeset -a ROOTS
    while [ $# -gt 0 ]; do
        if [ "$1" = "--" ]; then
            shift
            break
        fi
        d="$(readlink -f "$1")"
        ROOTS=( "${ROOTS[@]}" "$d" )
        shift
    done
    if [ ${#ROOTS[@]} -eq 0 ]; then
        echo >&2 "ERROR: No root directory given"
        return 1
    fi


    typeset -a IGNORE_DIRS
    while [ $# -gt 0 ]; do
        IGNORE_DIRS=( "${IGNORE_DIRS[@]}" "$1" )
        shift
    done

    #echo "INDEX:  $IDX_NAME"
    #echo "ROOTS:  ${ROOTS[@]}"
    #echo "IGNORE: ${IGNORE_DIRS[@]}"
    #echo "FILTER: ${FILTER[@]}"

    [ ! -d "$QC_DIR" ] && mkdir "$QC_DIR"

    typeset INDEX_FILE=$QC_DIR/$IDX_NAME

    typeset -a INC_ROOTS
    if [ ${#INC_UPD[@]} -gt 0 ]; then
        if [ -e "$INDEX_FILE" ]; then
            for d in "${INC_UPD[@]}"; do
                if [ -d "$d" ]; then
                    if is_descendant "$d" "${ROOTS[@]}"; then
                        INC_ROOTS+=( "$d" )
                        #else
                        #    echo "WARN: Index $IDX_NAME does not contain $d -- ignored"
                    fi
                else
                    echo "WARN: $d does not exist -- ignored"
                fi
            done
            if [ ${#INC_ROOTS[@]} -eq 0 ]; then
                if [ -z "$QC_LIST_UPD" ]; then
                    echo >&2 "ERROR: Index $IDX_NAME does not contain any of [ ${INC_UPD[*]} ]"
                    return 1
                else
                    echo >&2 "Skipping $IDX_NAME: does not contain any of [ ${INC_UPD[*]} ]"
                    return 0
                fi
            fi
        else
            echo "Index $IDX_NAME does not exist -- ignoring incremental update"
        fi
    fi

    typeset NEW_INDEX
    NEW_INDEX=$(mktemp "${INDEX_FILE}.XXXX")

    # if incremental update set new ROOTS and prefill index file
    if [ ${#INC_ROOTS[@]} -gt 0 ]; then
        ROOTS=( "${INC_ROOTS[@]}" )
        re=$(printf "%s|" "${ROOTS[@]}")
        re=${re:0:-1}
        grep -aEv "^($re)(/|$)" "$INDEX_FILE" > "$NEW_INDEX"
    fi
    typeset inc_start
    inc_start=$(wc -l < "$NEW_INDEX")

    # Build the 'find' expression for ignored dirs.
    typeset -a ignDirs
    if [ ${#IGNORE_DIRS[@]} -gt 0 ]; then
        ignDirs=( '(' )
        for ign in "${IGNORE_DIRS[@]}"; do
            if [ ${#ignDirs[@]} -gt 1 ]; then
                ignDirs+=(-o )
            fi
            if [[ "$ign" =~ ^/.*$ ]]; then
                ignDirs+=(-wholename "$ign")
            elif [[ "$ign" =~ ^\./.*$ ]]; then
                for R in "${ROOTS[@]}"; do
                    ignDirs+=(-wholename "${R}${ign:1}")
                done
            elif [[ "$ign" =~ ^.*/.*$ ]]; then
                ignDirs+=(-wholename "*$ign")
            else
                ignDirs+=(-name "$ign")
            fi
        done
        ignDirs+=( ")" )
    else
        # nothing to ignore
        ignDirs=( '-false' )
    fi

    typeset -a filter
    if [ ${#FILTER[@]} -gt 0 ]; then
        filter=( '(' )
        for f in "${FILTER[@]}"; do
            if [ ${#filter[@]} -gt 1 ]; then
                filter+=(-o)
            fi
            filter+=(-wholename)
            filter+=("$f")
        done
        filter+=(")")
    fi

    # find all directories excluding those configured
    find "${ROOTS[@]}" -xdev -type d "${ignDirs[@]}" -prune -o -xtype d "${filter[@]}" -print >> "$NEW_INDEX"
    # Don't check exit code.
    # A "permission denied" in some subdir would kill the index

    if [ -s "$NEW_INDEX" ]; then
        # replace .qc/index with new content
        mv -f "$NEW_INDEX" "$INDEX_FILE"

        typeset dir_count
        dir_count=$(wc -l < "$INDEX_FILE")

        typeset UPD=''
        if [ ${#INC_ROOTS[@]} -gt 0 ]; then
            dir_diff=$((dir_count - inc_start))
            UPD=" (Updated: $dir_diff)"
        fi

        echo "Stored $dir_count directory names$UPD."
    else
        rm -f "$NEW_INDEX"
        echo "No directories found -- no index created."
    fi
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

shopt -s extglob

oifs="$IFS"
IFS=$'\n'
typeset -i lno=0
while IFS= read -r line; do
    ((lno += 1))
    line=$(trim_str "$line")
    if [[ "$line" = \#* ]] || [ -z "$line" ]; then
        continue
    fi
    # shellcheck disable=SC2016  # the '$(' MUST NOT be expanded
    if [[ $line == *'$('* ]] || [[ $line == *'`'* ]]; then
        printf >&2 '%s[%d] ERROR: Possible command substitution: %s\n' "$LST" "$lno" "$line"
        continue
    fi
    #echo "LN: $line"

    if ! eval "ARGS=( $line )"; then
        printf >&2 '%s[%d] ERROR: Cannot parse: %s\n' "$LST" "$lno" "$line"
        continue
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
        *.index.!(*.*)) continue ;; # ignore index with other host name
        *.index.ext.!(*.*)) continue ;; # ignore index with other host name
        *) printf >&2 '%s[%d] Ignoring index %s\n' "$LST" "$lno" "${ARGS[0]}"
            continue
            ;;
    esac

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
    if ! build_index "${ARGS[@]}"; then
        printf >&2 '%s[%d] ERROR: Building index failed.\n' "$LST" "$lno"
    fi
done < "$LST"
IFS="$oifs"

