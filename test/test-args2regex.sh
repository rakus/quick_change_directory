#!/bin/bash
#
# FILE: test-args2regex.sh
#
# ABSTRACT: test qc regular expression creation
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-10
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

tmp_arg2regex="${script_dir}/qc_args2regex.shinc"

# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

sed -n '/^function args2regex/,/^}/p' ../qc-selector > "${tmp_arg2regex}"
if [ ! -s "${tmp_arg2regex}" ]; then
    echo >&2 "ERROR: Function args2regex not found in ../qc-selector"
    exit 1
fi

# shellcheck disable=SC1090
.   "${tmp_arg2regex}"

TEST_STATUS=0

g2re()
{
    expected="$1"
    shift
    printf "%s" "$* -> $expected"
    actual="$(args2regex "$@")"


    if [ "$actual" = "$expected" ]; then
        OK
    else
        ERROR
        echo "   Expected: >>$expected<<"
        echo "   Actual:   >>$actual<<"
    fi
}

#---------[ TESTS ]------------------------------------------------------------

startTest "args2regex"

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
