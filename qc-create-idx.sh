#!/bin/bash
#
# FILE: qc-create-idx.sh
#
# ABSTRACT: Script to create a directory index file for qc
#
# AUTHOR: Ralf Schandl
#

script_dir=$(cd "$(dirname $0)" 2>/dev/null; pwd)
script_name="$(basename "$0")"
script_file="$script_dir/$script_name"

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
        echo >&2 "Index name invalid. Must end with '.index' or '.index.ext'"
        usage
        exit 1
        ;;
esac

FILTER=()
INC_UPD=
while getopts ":f:i:" o "$@"; do
    case $o in
        f) FILTER=( "${FILTER[@]}" "$OPTARG" )
            ;;
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
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))

ROOTS=( )
while [ $# -gt 0 ]; do
    if [ $1 == '--' ]; then
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


IGNORE_DIRS=( )
while [ $# -gt 0 ]; do
    IGNORE_DIRS=( "${IGNORE_DIRS[@]}" "$1" )
    shift
done

#echo "INDEX:  $IDX_NAME"
#echo "ROOTS:  ${ROOTS[@]}"
#echo "IGNORE: ${IGNORE_DIRS[@]}"
#echo "FILTER: ${FILTER[@]}"

if [ -z "$QC_DIR" ]; then
    QC_DIR="$HOME/.qc"
fi
[ ! -d "$QC_DIR" ] && mkdir $QC_DIR

INDEX_FILE=$QC_DIR/$IDX_NAME

if [ -n "$INC_UPD" ]; then
    if [ -e "$INDEX_FILE" ]; then
        for r in "${ROOTS[@]}"; do
            case "$INC_UPD/" in
                $r)
                    HIT=true
                    ;;
                $r/*)
                    DO_INC_UPD=true
                    ;;
            esac
        done
        if [ ! $DO_INC_UPD ]; then
            if [ ! $QC_LIST_UPD ]; then
                echo >&2 "ERROR: Index $IDX_NAME does not contain $INC_UPD"
                exit 1
            else 
                echo >&2 "Skipping $IDX_NAME: does not contain $INC_UPD"
                exit 0
            fi
        fi
    else
        echo "Index $IDX_NAME does not exist -- ignoring incremental update"
    fi
fi

NEW_INDEX=$(mktemp ${INDEX_FILE}.XXXX)

# if incremental update set new ROOT and prefill index file
if [ $DO_INC_UPD ]; then
    ROOTS=($INC_UPD)
    egrep -v "^$INC_UPD(/|$)" $INDEX_FILE > $NEW_INDEX
fi

# Build the 'find' expression for ignored dirs.
ignDirs=()
if [ ${#IGNORE_DIRS[@]} -gt 0 ]; then
    ignDirs=( '(' )
    for ign in "${IGNORE_DIRS[@]}"; do
        if [ ${#ignDirs[@]} -gt 1 ]; then
            ignDirs+=(-o)
        fi
        if [[ "$ign" =~ ^/.*$ ]]; then
            ignDirs+=(-wholename)
        elif [[ "$ign" =~ ^\./.*$ ]]; then
            ignDirs+=(-wholename)
            ign="${ROOT}${ign:1}"
        elif [[ "$ign" =~ ^.*/.*$ ]]; then
            ignDirs+=(-wholename)
            ign="*$ign"
        else
            ignDirs+=(-name)
        fi
        ignDirs+=( "$ign" )
    done
    ignDirs+=( ")" )
else
    # nothing to ignore
    ignDirs=( '-false' )
fi


filter=()
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
find "${ROOTS[@]}" -xdev -type d "${ignDirs[@]}" -prune -o -xtype d "${filter[@]}" -print >> $NEW_INDEX
# Don't check exit code.
# A "permission denied" in some subdir would kill the index

# replace .qc/index with new content
mv -f $NEW_INDEX $INDEX_FILE

echo "Stored $(wc -l < $INDEX_FILE) directory names."

#---------[ END OF FILE qc-create-idx.sh ]-------------------------------------
