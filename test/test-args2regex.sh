#!/bin/bash
#
# FILE: test-args2regex.sh
#
# ABSTRACT: 
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-10
#

script_dir=$(cd "$(dirname $0)" 2>/dev/null; pwd)
script_name="$(basename "$0")"
script_file="$script_dir/$script_name"

. ${script_dir}/defines.shinc

TEST_STATUS=0

g2re()
{
    expected="$1"
    shift
    printf "$* -> $expected"
    actual="$(__qc_args2regex "$@")"


    if [ "$actual" = "$expected" ]; then
        OK
    else
        ERROR
        echo "   Expected: >>$expected<<"
        echo "   Actual:   >>$actual<<"
    fi
}

#---------[ TESTS ]------------------------------------------------------------

startTest "__qc_args2regex"

g2re "[^/]*$" "*"
g2re "[^/]*$" "*/"
g2re ".*$" "**"
g2re ".*$" "**/"
g2re "[^/]$" "?/"

g2re "dir[^/]*$" "dir"
g2re "dir/subdir[^/]*$" "dir/subdir"
g2re "dir/subdir[^/]*$" dir/ subdir
g2re "dir[^/]*/subdir[^/]*$" dir subdir
g2re "dir[^/]*/subdir$" dir subdir/

g2re "dir/\\(.*/\\)*subdir$" dir//subdir/
g2re "dir/\\(.*/\\)*subdir$" dir///subdir/
g2re "dir/\\(.*/\\)*subdir$" dir////////subdir/
g2re "dir/\\(.*/\\)*subdir[^/]*$" dir/ // subdir
g2re "dir/\\(.*/\\)*subdir[^/]*$" dir/ //subdir

g2re "dir/[^/]*/subdir$" "dir/*/subdir/"
g2re "dir/\\(.*/\\)*subdir$" "dir/**/subdir/"

g2re "a\*b$" a\\\*b/
g2re "a\*b$" 'a\*b/'
g2re "a[^/]b$" 'a?b/'
g2re "a?b$" 'a\?b/'
g2re "a\.b$" 'a.b/'

g2re  'Admin[^/]*$'                             "Admin"
g2re  "T[^/]*/\(.*/\)*Admin[^/]*\$"             "T" "//" "Admin"

g2re  "Admin[^/]*\$"                            "/Admin"
g2re  "Admin[^/]*\$"                            "//Admin"
g2re  "Admin[^/]*\$"                            "/////Admin"
g2re  "Admin\$"                                 "Admin/"
g2re  "Admin\$"                                 "Admin//"
g2re  "Admin\$"                                 "Admin/////"
g2re  "T[^/]*/Admin[^/]*\$"                     "T" "Admin"
g2re  "X[^/]*/T[^/]*/Admin[^/]*\$"              "X" "T" "Admin"
g2re  "A[^/]*/B[^/]*/C[^/]*/Admin[^/]*\$"       "A" "B" "C" "Admin"
g2re  "X[^/]*/\(.*/\)*Admin[^/]*\$"             "X" "//Admin"
g2re  "X[^/]*/\(.*/\)*Admin[^/]*\$"             "X" "///////Admin"
g2re  "X[^/]*/\(.*/\)*Admin[^/]*\$"             "X" "///////" "Admin"
g2re  "T[^/]*/[^/]*Admin[^/]*\$"                "T" "*Admin"
g2re  "T[^/]*/.*Admin[^/]*\$"                   "T" "**Admin"
g2re  "T[^/]*/\(.*/\)*Admin[^/]*\$"             "T" "**" "Admin"

g2re  "X/\(.*/\)*Admin[^/]*\$"                  "X//Admin"
g2re  "T/[^/]*Admin[^/]*\$"                     "T/*Admin"
g2re  "T/.*Admin[^/]*$"                         "T/**Admin"
g2re  "T/\(.*/\)*Admin[^/]*\$"                  "T/**/Admin"
g2re  "Admin[^/]*\$"                            "**/Admin"
g2re  "Admin[^/]*\$"                            "*/Admin"
g2re  "Admin[^/]*\$"                            "*******/Admin"

#------------------------------------------------------------------------------
endTest $TEST_STATUS

exit $TEST_STATUS

#---------[ END OF FILE test-args2regex.sh ]-----------------------------------
