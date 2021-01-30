# shellcheck shell=bash
#
# FILE: quick_change_directory.sh
#
# Provides the shell alias 'qc' for index based quick change directory.
# Qc searches a index file for a matching directory and then changes to it.
# If multiple directories match, the user is presented a list to choose from.
#
# See README.md for a full description.
#
# AUTHOR: Ralf Schandl
#

function __qc
{
    [ -n "${rst_f:-}" ] && set +f
    typeset PATH="${QC_DIR:-$HOME/.qc}:$PATH"
    typeset qc_target
    qc_target="$(qc-backend "$@")"
    typeset qc_rc=$?
    if [ -n "$qc_target" ]; then
        # shellcheck disable=SC2164 # returning with exit code below
        "cd" "$qc_target"
        return
    else
        return $qc_rc
    fi
}

if [ -n "${ZSH_VERSION:-}" ]; then
    alias qc='noglob __qc'
else
    # bash, ksh, mksh, pdksh
    alias qc='set -f;rst_f=true __qc'
fi

if [ -e "${QC_DIR:-$HOME/.qc}/dstore" ]; then
    # shellcheck disable=SC2139 # yes, it should expand now
    alias "dstore=${QC_DIR:-$HOME/.qc}/dstore"
fi

if [ -z "${BASH_VERSION:-}" ]; then
    return
fi
# the following lines are bash-specific

__qc_complete()
{
    local PATH="${QC_DIR:-$HOME/.qc}:$PATH"
    local cur words

    # special handling for :*
    cur="${COMP_LINE##* }"

    words=( "${COMP_WORDS[@]:1}" )

    case "$cur" in
        ':'*)
            mapfile -d$'\n' -t COMPREPLY < <( qc-backend --complete "$cur" )
            ;;
        *)
            mapfile -d$'\n' -t COMPREPLY < <( qc-backend --complete "${words[@]}" )
            ;;
    esac
}

complete -o nospace -F __qc_complete qc

# vim:ft=sh:et:ts=4:sw=4
