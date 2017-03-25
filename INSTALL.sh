#!/bin/bash
#
# FILE: INSTALL.sh
#
# ABSTRACT: Installes Quick Change Directory
#
# Usage:
#   INSTALL.sh
#     If called without parameter, just prints out what would be done.
#     AKA: Simulation mode.
#
#   INSTALL.sh YES
#     If called with parameter "YES" it acually does what it says.
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-03-03
#

set -u

script_dir=$(cd "$(dirname $0)" 2>/dev/null; pwd)
script_name="$(basename "$0")"
script_file="$script_dir/$script_name"


usage()
{
        echo ""
        echo "USAGE: $script_name [YES|HARD]"
        echo ""
        echo "  If called WITHOUT paramater, runs in simulation mode and just prints what"
        echo "  would be done."
        echo ""
        echo "  If called with paramater \"YES\", does the installation and creates"
        echo "  backup copies of already existing files."
        echo ""
        echo "  If called with parameter \"HARD\", does the installation and overwrites"
        echo "  existing files."
        echo "  WARNING: This will remove all local adaptations, including changes"
        echo "           to '~/.qc/qc-index.list'."
        echo ""
}

EXECUTE=''
HARD=''
if [ $# -gt 0 ]; then
    if [ $# -ne 1 ]; then
        usage
        exit 1
    elif [ "$1" = "YES" ]; then
        EXECUTE=true
    elif [ "$1" = "HARD" ]; then
        EXECUTE=true
        HARD=true
    else
        echo "ERROR: unknown parameter $1"
        usage
        exit 1
    fi
fi


simu_msg()
{
    echo "========================================================="
    echo "  S I M U L A T I O N   M O D E"
    echo ""
    echo "  No commands will be executed."
    echo ""
    echo "  For real execution run: $0 YES "
    echo ""
    echo "========================================================="
}

run_cmd()
{
    typeset RC
    if [ $EXECUTE ]; then
        $@
        return $?
    else
        echo "$@"
        return 0
    fi
}

copy_file()
{
    typeset src="$1"
    typeset tgt="$2"

    if diff "$src" "$tgt" >/dev/null 2>&1; then
        echo "SKIPPED: Identical $src already installed"
        return 0
    fi

    if [ -e "$tgt" ] && [ ! $HARD ]; then
        echo "Saving existing $tgt to $tgt.install-prev"
        run_cmd mv -f "$tgt" "$tgt.install-prev"
        [ $? -ne 0 ] && exit 1
    fi

    echo "Copying $src to $tgt..."
    run_cmd cp -f "$src" "$tgt"
    [ $? -ne 0 ] && exit 1
    if [[ "$tgt" == *.sh ]]; then
        run_cmd chmod +x "$tgt"
    fi
}

add_to_crontab()
{
    if crontab -l | grep "qc-build-index.sh" >/dev/null 2>&1; then
        echo "SKIPPED: Crontab entry seems to exist"
    else
        CRE="*/10 * * * * \${HOME}/.qc/qc-build-index.sh >\${HOME}/.qc/qc-build-index.log 2>&1"
        echo "Installing crontab entry:"
        echo "    $CRE"
        # to complex for run_cmd
        if [ $EXECUTE ]; then
            (crontab -l 2>/dev/null; echo "$CRE") | crontab -
        else
            echo "(crontab -l 2>/dev/null; echo \"$CRE\") | crontab -"
        fi
    fi
}

add_to_init_file()
{
    typeset file="$1"
    if grep "\\.quick_change_dir" "$file" >/dev/null 2>&1; then
        echo "SKIPPED: The file .quick_change_dir seems to be already sourced from $file"
    else
        echo "Adding .quick_change_dir to $file..."
        # to complex for run_cmd (because of redir)
        if [ $EXECUTE ]; then
            echo "[ -e \"\$HOME/.quick_change_dir\" ] && . \$HOME/.quick_change_dir" >> $file
        else
            echo "echo \"[ -e \"\$HOME/.quick_change_dir\" ] && . \$HOME/.quick_change_dir\" >> $file"
        fi
    fi
}

#---------[ MAIN ]-------------------------------------------------------------

[ ! $EXECUTE ] && simu_msg

cd "$script_dir"
[ $? -ne 0 ] && exit 1

TGT="$HOME/.qc"

# Create ~/.qc
if [ ! -d "$TGT" ]; then
    run_cmd mkdir "$TGT"
    [ $? -ne 0 ] && exit 1
fi

copy_file qc-index-proc.sh "$TGT/qc-index-proc.sh"
copy_file qc-build-index.sh "$TGT/qc-build-index.sh"
copy_file _quick_change_dir "$HOME/.quick_change_dir"

if [ ! -e "$TGT/qc-index.list" ] || [ $HARD ]; then
    copy_file qc-index.list "$TGT/qc-index.list"
else
    if diff qc-index.list "$TGT/qc-index.list" >/dev/null 2>&1; then
        echo "SKIPPED: Identical qc-index.list already installed"
    else
        copy_file qc-index.list "$TGT/qc-index.list.install-new"
        echo "------------------------------------------------------------"
        echo ""
        echo "New Index Definition list copied to "
        echo "      $TGT/qc-index.list.install-new"
        echo ""
        echo "Please validate the existing $TGT/qc-index.list and delete"
        echo "qc-index.list.install-new afterwards."
        echo ""
        echo "------------------------------------------------------------"
    fi
fi

add_to_crontab

add_to_init_file "$HOME/.bashrc"

# Add to .kshrc if available?

[ ! $EXECUTE ] && simu_msg

#---------[ END OF FILE INSTALL.sh ]-------------------------------------------
