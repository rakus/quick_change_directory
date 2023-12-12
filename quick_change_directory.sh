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
    typeset qc_target
    qc_target="$(PATH="${QC_DIR:-$HOME/.qc}:$PATH" qc-backend "$@")"
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
        __qc_complete_get_cur_and_words()
        {
            _get_comp_words_by_ref -n : cur words cword
        }
    else
        # Fallback implementation if _get_comp_words_by_ref is not availabel
        # Hit that in bash from "Git for Windows", as it comes without
        # bash-completion by default.
        # This is not perfect, as ':' is only handled for the first parameter
        # and even that is guessing.
        __qc_complete_get_cur_and_words()
        {
            cur="${COMP_WORDS[COMP_CWORD]}"
            if [ "${COMP_WORDS[COMP_CWORD-1]}" = ":" ]; then
                cur=":$cur"
            fi
            cword=$COMP_CWORD
            words=( "${COMP_WORDS[@]}" )
            if [[ "${words[1]:-}" = ":" ]]; then
                words[1]=":${words[2]:-}"
                unset 'words[2]'
                if [[ $cword -ge 2 ]]; then
                    cword=$(( cword - 1 ))
                fi
            fi
        }
        # Inspired by bash-completion package
        __ltrim_colon_completions()
        {
            if [[ $1 == *:* && $COMP_WORDBREAKS == *:* ]]; then
                COMPREPLY=( "${COMPREPLY[@]#"${1%"${1##*:}"}"}" )
            fi
        }
    fi

    __qc_complete()
    {
        local PATH="${QC_DIR:-$HOME/.qc}:$PATH"
        local cur words

        __qc_complete_get_cur_and_words

        # if completion is in the middle, we need to get rid of the words after
        # the cursor
        #words=( "${words[@]:0:$((cword+1))}" )
        words=( "${words[@]:1:cword}" )

        mapfile -d$'\n' -t COMPREPLY < <(compgen -W "$(qc-backend --complete "${words[@]}")" --  "$cur")
        __ltrim_colon_completions "$cur"
    }

    complete -o nospace -F __qc_complete qc

elif [ -n "${ZSH_VERSION:-}" ]; then

    __qc_complete()
    {
        local PATH="${QC_DIR:-$HOME/.qc}:$PATH"
        local -a comp

        # if completion is in the middle, we need to get rid of the words after
        # the cursor
        words=( "${words[@]:0:$CURRENT}" )

        # shellcheck disable=SC2296 # ZSH syntax copied from stackoverflow
        comp=("${(@f)$( qc-backend --complete "${words[@]:1}" )}")

        compadd "${comp[@]}"

        return 0
    }

    compdef __qc_complete __qc qc
fi

# vim:ft=sh:et:ts=4:sw=4
