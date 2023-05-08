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
    alias 'dstore=${QC_DIR:-$HOME/.qc}/dstore'
fi

if [ -z "${BASH_VERSION:-}${ZSH_VERSION:-}" ]; then
    return
elif [ -n "${BASH_VERSION:-}" ]; then
# the following lines are bash-specific

    if declare -F "_get_comp_words_by_ref" > /dev/null; then
        qc_use_get_comp_words_by_ref=true
    else
        unset qc_use_get_comp_words_by_ref
    fi

    __qc_complete()
    {
        local PATH="${QC_DIR:-$HOME/.qc}:$PATH"
        local cur words

        if [ -n "$qc_use_get_comp_words_by_ref" ]; then
            _get_comp_words_by_ref -n : cur
        else
            # fallback if _get_comp_words_by_ref is not available:
            cur="${COMP_WORDS[COMP_CWORD]}"
            if [ "${COMP_WORDS[COMP_CWORD-1]}" = ":" ]; then
                cur=":$cur"
            fi
        fi


        words=( "${COMP_WORDS[@]:1}" )

        case "$cur" in
            ':'*)
                mapfile -d$'\n' -t COMPREPLY < <(compgen -W "$(qc-backend --complete "$cur")" -- "$cur")
                COMPREPLY=( "${COMPREPLY[@]#:}" )
                ;;
            *)
                #mapfile -d$'\n' -t COMPREPLY < <( qc-backend --complete "${words[@]}" )
                mapfile -d$'\n' -t COMPREPLY < <(compgen -W "$(qc-backend --complete "${words[@]}")" --  "$cur")
                ;;
        esac
    }

    complete -o nospace -F __qc_complete qc

elif [ -n "${ZSH_VERSION:-}" ]; then

    __qc_complete()
    {
        local PATH="${QC_DIR:-$HOME/.qc}:$PATH"
        local cur="$PREFIX"
        local -a comp

        case "$cur" in
            ':'*)
                # shellcheck disable=SC2296 # weird ZSH syntax copies from stackoverflow
                comp=("${(@f)$(qc-backend --complete "$cur")}")
                ;;
            *)
                # shellcheck disable=SC2296 # weird ZSH syntax copies from stackoverflow
                comp=("${(@f)$( qc-backend --complete "${words[@]:1}" )}")
                ;;
        esac
        compadd "${comp[@]}"

        return 0
    }

    compdef __qc_complete __qc qc
fi

# vim:ft=sh:et:ts=4:sw=4
