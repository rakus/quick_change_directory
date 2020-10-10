# shellcheck shell=bash
#

# Directory for qc index files
[ -z "${QC_DIR:-}" ] && QC_DIR=$HOME/.qc

# Manual index file storing directory names and bookmarked directories. This
# file is managed using the command 'dstore'.
QC_DSTORE_INDEX=$QC_DIR/index.dstore

# qc completion function
function __qc_complete
{
    #qc_debug "_qc_complet ============================"
    typeset cur prev opts
    COMPREPLY=()
    if [ "${BASH_VERSION:0:1}" -ge 4 ]; then
        _get_comp_words_by_ref -n : cur
    else
        # shellcheck disable=SC2001,SC2086
        cur=$(echo ${COMP_LINE:0:$COMP_POINT}|sed "s/^.* //")
    fi
    prev="${COMP_WORDS[*]}"
    #qc_debug "cur >>$cur<<"
    #qc_debug "prev >>$prev<<"
    #qc_debug "CL >>$COMP_LINE<<"

    if echo "$prev" | grep " -[^ ]*u" >/dev/null 2>&1 ; then
        mapfile -d$'\n' -t COMPREPLY < <(compgen -o dirnames -- "$cur")
        return 0
    fi
    if echo "$prev" | grep " -[^ ]*S" >/dev/null 2>&1 ; then
        return 0
    fi
    if echo "$prev" | grep " -[^ ]*l" >/dev/null 2>&1 ; then
        return 0
    fi

    typeset ic
    typeset sedIC
    if echo "$prev" | grep " -[^ ]*i" >/dev/null 2>&1 ; then
        ic='-i'
        sedIC="i"
    fi
    typeset searchExtIdx
    if echo "$prev" | grep " -[^ ]*e" >/dev/null 2>&1 ; then
        searchExtIdx="1"
    fi
    #qc_debug "CW >>${COMP_WORDS[@]}<<"

    typeset -a parts=( "${COMP_WORDS[@]}" )
    unset parts["0"]
    parts=( "${parts[@]}" )
    #qc_debug "XX ${parts[0]}"
    while [[ ${parts[0]} = -* ]]; do
        #qc_debug "unsetting ${parts[0]}"
        unset parts["0"]
        parts=( "${parts[@]}" )
    done
    #qc_debug "parts >>${parts[@]}<<"

    case "$cur" in
        \~ | \~/*)
            _filedir -d;
            return 0;
            ;;
        . | .. | ../* | ./*)
            _filedir -d;
            return 0;
            ;;
        ':'*)
            #qc_debug "LABEL"
            opts=$(grep -a "^${cur}[^ ]* " "$QC_DSTORE_INDEX" | cut "-d " -f1 | sort | uniq)
            #qc_debug "$opts"
            mapfile -d$'\n' -t COMPREPLY < <(compgen "-S " -W "${opts[*]}" -- "$cur")
            typeset i
            for ((i=0; i < ${#COMPREPLY[@]}; i++)); do
                COMPREPLY[$i]=$(printf "%q" "${COMPREPLY[$i]:1}")
                if [ "${BASH_VERSION:0:1}" -lt 4 ]; then
                    COMPREPLY[$i]="${COMPREPLY[$i]} "
                fi
            done
            #qc_debug "COMPREPLY >>${COMPREPLY[*]}<<"
            ;;
        ?*)
            cur=$(eval echo "$cur" 2>/dev/null || eval echo "$cur'" 2>/dev/null || eval echo "$cur\"" 2>/dev/null || "")
            #qc_debug "cur >>$cur<<"
            cur=${cur#/} # remove leading '/'
            # curRE: Regular expression to find dir in index
            typeset curRE=$(__qc_args2regex "${parts[@]}")
            # shellcheck disable=SC2001
            typeset curRE=$(echo "$curRE" | sed "s%\([^*]\)\$$%\1/[^/]*$%")
            # cleanRE: RE to delete unneeded part from result
            # shellcheck disable=SC2001
            typeset cleanRE=$(echo "$curRE" | sed "s%\[^/\]\*.$%%")
            #qc_debug "curRE >>$curRE<<"
            #qc_debug "cleanRE >>$cleanRE<<"
            typeset IFS=$'\n'
            typeset -a idxFiles
            mapfile -d$'\n' -t idxFiles < <(__qc_get_indexes "$searchExtIdx")
            if [ ${#idxFiles[@]} = 0 ]; then
                echo >&2  "qc: No index file found! Use 'qc -u' or 'dstore' to create it."
                return 1
            fi
            mapfile -d$'\n' -t opts < <(grep -a --no-filename $ic -o -- "/$curRE" "${idxFiles[@]}" | sort | uniq  | sed "s|^.*/${cleanRE}|/${cur}|$sedIC" | cut -c2-)
            #qc_debug "OPTS >>${opts[*]}<<"
            mapfile -d$'\n' -t COMPREPLY < <(compgen -o nospace -S/ -W "${opts[*]}" -- "$cur" )
            #COMPREPLY=( "${opts[@]}")
            if [ "${BASH_VERSION:0:1}" -ge 4 ]; then
                compopt -o nospace
            fi
            #qc_debug "COMPREPLY >>${COMPREPLY[*]}<<"
            for ((i=0; i < ${#COMPREPLY[@]}; i++)); do
                COMPREPLY[$i]=$(printf "%q" "${COMPREPLY[$i]}")
            done
            ;;
        *)
            # do Nothing
            ;;
    esac
    #qc_debug "COMPREPLY >>${COMPREPLY[*]}<<"

    return 0
}
if [ "${BASH_VERSION:0:1}" -ge 4 ]; then
    complete  -F __qc_complete qc
else
    complete -o nospace -F __qc_complete qc
fi

