#!/bin/bash
#
# FILE: qc-index-proc.sh
#
# ABSTRACT: Script to create a directory index file for qc
#
# This script is intended to be called by qc-build-index.sh.
#
# AUTHOR: Ralf Schandl
#

script_name="$(basename "$0")"

usage()
{
    echo >&2 "USAGE: $script_name index [-f glob-expr] [-i dir] root-dir... [-- ignored-dirs...]"
    echo >&2 ""
    echo >&2 "   index"
    echo >&2 "        Name of the index file. Must end with '.index' or '.index.ext'."
    echo >&2 "   -f glob-expr"
    echo >&2 "        Only include directories that match glob-expr. The glob "
    echo >&2 "        expression matches the entire file path. E.g. '*/.*' matches any"
    echo >&2 "        path that contains a hidden directory."
    echo >&2 "        See option '-wholename' of the 'find' command."
    echo >&2 "        If given multiple times it creates a or-expression."
    echo >&2 "   -i dir"
    echo >&2 "        Incremental update of the given dir. If the given dir is not one"
    echo >&2 "        of the given root-dirs or a descendant of one, nothing happens."
    echo >&2 "   root-dir..."
    echo >&2 "        One or more root directories for the index."
    echo >&2 "   ignored-dirs..."
    echo >&2 "        Directories to ignore. Glob expressions have to be quoted!"
    echo >&2 ""
    echo >&2 "   EXAMPLES:"
    echo >&2 "     Build index of home, excluding hidden dirs:"
    echo >&2 "       $script_name home.index \$HOME -- '.*'"
    echo >&2 ""
    echo >&2 "     Build index of home, only containing pathes with a hidden dir:"
    echo >&2 "       $script_name home.index -f '*/.*' \$HOME"
    echo >&2 ""
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


#---------[ MAIN ]-------------------------------------------------------------

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

if [ "$1" = "--help" ]; then
    usage
    exit 0
fi

IDX_NAME=$1
shift
case "$IDX_NAME" in
    *.index) :
        ;;
    *.index.ext) :
        ;;
    *)
        echo >&2 "ERROR: Index name invalid. Must end with '.index' or '.index.ext'"
        usage
        exit 1
        ;;
esac
if [ "$IDX_NAME" != "$(basename "$IDX_NAME")" ]; then
    echo >&2 "ERROR: Index name must be a plain filename."
    exit 1
fi

typeset -a FILTER
typeset -a INC_UPD
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
            [ "${!OPTIND}" != "--help" ] && echo >&2 "ERROR: can't parse: ${!OPTIND}" && echo >&2 ""
            usage
            exit 1
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
    usage
    exit 1
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

[ -z "$QC_DIR" ] && QC_DIR="$HOME/.qc"
[ ! -d "$QC_DIR" ] && mkdir "$QC_DIR"

INDEX_FILE=$QC_DIR/$IDX_NAME

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
            if [ ! "$QC_LIST_UPD" ]; then
                echo >&2 "ERROR: Index $IDX_NAME does not contain any of [ ${INC_UPD[*]} ]"
                exit 1
            else
                echo >&2 "Skipping $IDX_NAME: does not contain any of [ ${INC_UPD[*]} ]"
                exit 0
            fi
        fi
    else
        echo "Index $IDX_NAME does not exist -- ignoring incremental update"
    fi
fi

NEW_INDEX=$(mktemp "${INDEX_FILE}.XXXX")

# if incremental update set new ROOTS and prefill index file
if [ ${#INC_ROOTS[@]} -gt 0 ]; then
    ROOTS=( "${INC_ROOTS[@]}" )
    re=$(printf "%s|" "${ROOTS[@]}")
    re=${re:0:-1}
    grep -aEv "^($re)(/|$)" "$INDEX_FILE" > "$NEW_INDEX"
fi
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

# replace .qc/index with new content
mv -f "$NEW_INDEX" "$INDEX_FILE"

dir_count=$(wc -l < "$INDEX_FILE")

UPD=''
if [ ${#INC_ROOTS[@]} -gt 0 ]; then
    dir_diff=$((dir_count - inc_start))
    UPD=" (Updated: $dir_diff)"
fi

echo "Stored $dir_count directory names$UPD."

#---------[ END OF FILE qc-index-proc.sh ]-------------------------------------
