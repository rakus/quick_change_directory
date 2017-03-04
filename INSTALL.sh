#!/bin/bash
#
# FILE: INSTALL.sh
#
# ABSTRACT: 
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-03-03
#

script_dir=$(cd "$(dirname $0)" 2>/dev/null; pwd)
script_name="$(basename "$0")"
script_file="$script_dir/$script_name"

usage()
{
    echo >&2 "Installs Quick Change Directory files in your hom directory"
    echo >&2 "Usage: INSTALL.sh [-f]"
    echo >&2 "    -f  Force! Overwrite already existing files"
    echo >&2 ""
}

copy_file()
{
    typeset src="$1"
    typeset tgt="$2"

    if [ -e "$tgt" ]; then
        echo "Saving existing $tgt to $tgt.install-prev"
        [ ! $NOOP ] && mv -f "$tgt" "$tgt.install-prev"
    fi

    echo "Copying $src to $tgt..."
    [ ! $NOOP ] && cp -f "$src" "$tgt"
}

add_to_crontab()
{
    if crontab -l | grep "qc-process-idx-list.sh" >/dev/null 2>&1; then
        echo "Crontab entry exists -- skipping"
    else
        CRE="*/10 * * * * ${HOME}/.qc/qc-process-idx-list.sh >/dev/null 2>&1"
        echo "Installing crontab entry:"
        echo "    $CRE"
        [ ! $NOOP ] && (crontab -l 2>/dev/null; echo "$CRE") | crontab -
    fi
}

add_to_init_file()
{
    typeset file="$1"
    if grep "\\.quick_change_dir" "$file" >/dev/null 2>&1; then
        echo "The file .quick_change_dir seems to be already sourced from $file -- SKIPPING"
    else
        echo "Adding .quick_change_dir to $file..."
        [ ! $NOOP ] && echo ". $HOME/.quick_change_dir" >> $file
    fi
}

NOOP=
while getopts ":n" o "$@"; do
    case $o in
        n) NOOP=true
            ;;
        *)
            [ "${!OPTIND}" != "--help" ] && echo >&2 "can't parse: ${!OPTIND}" && echo >&2 ""
            usage
            ;;
    esac
done


TGT="$HOME/.qc"

# Create ~/.qc
if [ ! -d "$TGT" ]; then
    [ ! $NOOP ]mkdir "$TGT"
    [ $? -ne 0 ] && exit 1
fi

copy_file qc-create-idx.sh "$TGT/qc-create-idx.sh"
copy_file qc-process-idx-list.sh "$TGT/qc-process-idx-list.sh"
copy_file _quick_change_dir "$HOME/.quick_change_dir"

if [ ! -e "$TGT/qc-index.list" ]; then
    copy_file qc-index.list "$TGT/qc-index.list"
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

add_to_crontab 

add_to_init_file "$HOME/.bashrc"


#---------[ END OF FILE INSTALL.sh ]-------------------------------------------
