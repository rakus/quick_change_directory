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

__qc()
{
    [ -n "${rst_f:-}" ] && set +f
    local PATH="${QC_DIR:-$HOME/.qc}:$PATH"
    local __qc_target
    __qc_target="$(quick-change-directory "$@")"
    if [ -n "$__qc_target" ]; then
        # shellcheck disable=SC2164 # returning with exit code below
        "cd" "$__qc_target"
        return
    fi
    return 0
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

if [ -z "$BASH" ]; then
    return
fi
# the following lines are bash-specific

__qc_complete()
{
    local PATH="${QC_DIR:-$HOME/.qc}:$PATH"
    local cur words

    # special handling for :*
    _get_comp_words_by_ref -n : cur

    words=( "${COMP_WORDS[@]:1}" )

    case "$cur" in
        ':'*)
            mapfile -d$'\n' -t COMPREPLY < <( quick-change-directory --complete "$cur" )
            ;;
        *)
            mapfile -d$'\n' -t COMPREPLY < <( quick-change-directory --complete "${words[@]}" )
            ;;
    esac
}

complete -o nospace -F __qc_complete qc

# vim:ft=sh:et:ts=4:sw=4
