#!/usr/bin/env bash
#
# FILE: test-dstore.sh
#
# ABSTRACT: test dstore
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-11
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

BUILD_TEST_DIRS=true
# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

QC_DSTORE_INDEX=$QC_DIR/index.dstore

checkSize()
{
    printf "   Dstore size"
    if [ "$1" -eq "$(dstore -l | wc -l)" ]; then
        OK
    else
        ERROR
    fi
}

labelExists()
{
    printf "   Check lable \"%s\"" "$1"
    if grep "$1 " "$QC_DSTORE_INDEX" >/dev/null 2>&1; then
        OK
    else
        ERROR
    fi
}

labelGone()
{
    printf "   Check no lable \"%s\"" "$1"
    if ! grep "$1 " "$QC_DSTORE_INDEX" >/dev/null 2>&1; then
        OK
    else
        ERROR
    fi
}

entryExists()
{
    printf "   Check for entry \"%s\"" "$1"
    if grep "$1" "$QC_DSTORE_INDEX" >/dev/null 2>&1; then
        OK
    else
        ERROR
    fi
}

cd "$TEST_DIRECTORY" || exit 1

startTest "dstore"

echo "Adding Content"
dstore :loc .config/localhost
dstore :D Customer/YoYoDyne/docs
dstore Customer/YoYoDyne/src
dstore :A Customer/ACME

checkSize 4
labelExists ":loc"
labelExists ":d"
labelExists ":a"

echo "Delete label :D"
dstore -d :D
labelGone ":d"
checkSize 3

echo "Try adding not existing dir"
dstore :A hallo
labelExists ":a"
entryExists "^:a .*Customer/ACME"
checkSize 3

echo "Check cleanup"
echo "NIX" >> "$QC_DSTORE_INDEX"
checkSize 4
dstore -c
checkSize 3

echo "Adding directory"
mkdir HALLO
dstore HALLO
entryExists "^.*HALLO"
checkSize 4


endTest

