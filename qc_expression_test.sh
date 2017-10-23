#!/bin/bash
#
# FILE: qc_expression_test.sh
#
# ABSTRACT:
#
# AUTHOR: Ralf Schandl
#
#

script_dir=$(dirname $(readlink -f "$0"))
script_name=$(basename $0)

unset -f __qc_args2regex
source $script_dir/_quick_change_dir

#type __qc_args2regex

testExp()
{
    expected="$1"
    shift

    act="$(__qc_args2regex "$@")"

    if [ "$act" != "$expected" ]; then
        echo "ERROR: $@ -> $act   expected: $expected"
    else
        echo "OK:    $@ -> $act"
    fi
}

testExp  'Admin[^/]*$'                             "Admin"
testExp  "T[^/]*/\(.*/\)*Admin[^/]*\$"             "T" "//" "Admin"

testExp  "Admin[^/]*\$"                            "/Admin"
testExp  "Admin[^/]*\$"                            "//Admin"
testExp  "Admin[^/]*\$"                            "/////Admin"
testExp  "Admin\$"                                 "Admin/"
testExp  "Admin\$"                                 "Admin//"
testExp  "Admin\$"                                 "Admin/////"
testExp  "T[^/]*/Admin[^/]*\$"                     "T" "Admin"
testExp  "X[^/]*/T[^/]*/Admin[^/]*\$"              "X" "T" "Admin"
testExp  "A[^/]*/B[^/]*/C[^/]*/Admin[^/]*\$"       "A" "B" "C" "Admin"
testExp  "X[^/]*/\(.*/\)*Admin[^/]*\$"             "X" "//Admin"
testExp  "X[^/]*/\(.*/\)*Admin[^/]*\$"             "X" "///////Admin"
testExp  "X[^/]*/\(.*/\)*Admin[^/]*\$"             "X" "///////" "Admin"
testExp  "T[^/]*/[^/]*Admin[^/]*\$"                "T" "*Admin"
testExp  "T[^/]*/[^/]*Admin[^/]*\$"                "T" "+Admin"
testExp  "T[^/]*/.*Admin[^/]*\$"                   "T" "**Admin"
testExp  "T[^/]*/.*Admin[^/]*\$"                   "T" "++Admin"
testExp  "T[^/]*/\(.*/\)*Admin[^/]*\$"             "T" "**" "Admin"
testExp  "T[^/]*/\(.*/\)*Admin[^/]*\$"             "T" "++" "Admin"


testExp  "X/\(.*/\)*Admin[^/]*\$"                  "X//Admin"
testExp  "T/[^/]*Admin[^/]*\$"                     "T/*Admin"
testExp  "T/[^/]*Admin[^/]*\$"                     "T/+Admin"
testExp  "T/.*Admin[^/]*$"                         "T/**Admin"
testExp  "T/.*Admin[^/]*$"                         "T/++Admin"
testExp  "T/\(.*/\)*Admin[^/]*\$"                  "T/**/Admin"
testExp  "T/\(.*/\)*Admin[^/]*\$"                  "T/++/Admin"
testExp  "Admin[^/]*\$"                            "**/Admin"
testExp  "Admin[^/]*\$"                            "*/Admin"
testExp  "Admin[^/]*\$"                            "*******/Admin"


#---------[ END OF FILE qc_expression_test.sh ]--------------------------------
