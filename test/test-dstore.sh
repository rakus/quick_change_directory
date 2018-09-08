#!/bin/bash
#
# FILE: test-dstore.sh
#
# ABSTRACT: test dstore
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-11
#

script_dir=$(cd "$(dirname "$0")" 2>/dev/null; pwd)

BUILD_TEST_DIRS=true
. "${script_dir}/defines.shinc"


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




#    mkdir -p testDirectory/.config/localhost
#    mkdir -p testDirectory/Customer/YoYoDyne/Admin
#    mkdir -p testDirectory/Customer/YoYoDyne/docs
#    mkdir -p testDirectory/Customer/YoYoDyne/src
#    mkdir -p testDirectory/Customer/YoYo/MyProject/Admin
#    mkdir -p testDirectory/Customer/ACME/Admin

cd "${script_dir}/testDirectory"
touch .qc/home.index

startTest "dstore"

echo "Adding Content"
dstore :loc .config/localhost
dstore :D Customer/YoYoDyne/docs
dstore Customer/YoYoDyne/src
dstore :A Customer/ACME

checkSize 4
labelExists ":loc"
labelExists ":D"
labelExists ":A"

echo "Delete label :D"
dstore -d :D
labelGone ":D"
checkSize 3

echo "Try adding not existing dir"
dstore :A hallo
labelExists ":A"
entryExists "^:A .*Customer/ACME"
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


#---------[ END OF FILE test-dstore.sh ]---------------------------------------
