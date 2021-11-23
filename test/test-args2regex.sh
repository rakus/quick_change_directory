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

set -u

# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

tmp_arg2regex="$TEST_DIRECTORY/args2regex"

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

printf "Extracting function arg2regex"
echo "#!/usr/bin/env bash" > "$tmp_arg2regex"
sed -n '/^args2regex()/,/^}/p' ../qc-backend >> "${tmp_arg2regex}"
if [ "$(wc -l <"$tmp_arg2regex")" -gt 1 ]; then
    echo 'args2regex "$@"' >> "$tmp_arg2regex"
    chmod +x "$tmp_arg2regex"
    OK
    export PATH="$TEST_DIRECTORY:$PATH"
else
    ERROR
    rm -f "${tmp_arg2regex}"
    echo >&2 "ERROR: Function args2regex not found in ../qc-backend"
    endTest
fi

# shellcheck disable=SC1090
#.   "${tmp_arg2regex}"

g2re '[^/]*$' '*'
g2re '[^/]*$' '*/'
g2re '.*$' '**'
g2re '.*$' '**/'
g2re '[^/]$' '?/'

g2re 'dir[^/]*$' 'dir'
g2re 'dir/subdir[^/]*$' 'dir/subdir'
g2re 'dir/subdir[^/]*$' dir/ subdir
g2re 'dir[^/]*/subdir[^/]*$' dir subdir
g2re 'dir[^/]*/subdir$' dir subdir/

g2re 'dir/\(.*/\)*subdir$' dir//subdir/
g2re 'dir/\(.*/\)*subdir$' dir///subdir/
g2re 'dir/\(.*/\)*subdir$' dir////////subdir/
g2re 'dir/\(.*/\)*subdir[^/]*$' dir/ // subdir
g2re 'dir/\(.*/\)*subdir[^/]*$' dir/ //subdir

g2re 'dir/[^/]*/subdir$' 'dir/*/subdir/'
g2re 'dir/\(.*/\)*subdir$' 'dir/**/subdir/'
g2re 'dir/\(.*/\)*subdir$' 'dir/***/subdir/'
g2re 'dir/\(.*/\)*subdir$' 'dir/********/subdir/'

g2re 'a\*b$' a\\\*b/
g2re 'a\*b$' 'a\*b/'
g2re 'a[^/]b$' 'a?b/'
g2re 'a?b$' 'a\?b/'
g2re 'a\.b$' 'a.b/'

g2re  'Admin[^/]*$'                             'Admin'
g2re  'T[^/]*/\(.*/\)*Admin[^/]*$'             'T' '//' 'Admin'

g2re  'Admin[^/]*$'                            '/Admin'
g2re  'Admin[^/]*$'                            '//Admin'
g2re  'Admin[^/]*$'                            '/////Admin'
g2re  'Admin$'                                 'Admin/'
g2re  'Admin$'                                 'Admin//'
g2re  'Admin$'                                 'Admin/////'
g2re  'T[^/]*/Admin[^/]*$'                     'T' 'Admin'
g2re  'X[^/]*/T[^/]*/Admin[^/]*$'              'X' 'T' 'Admin'
g2re  'A[^/]*/B[^/]*/C[^/]*/Admin[^/]*$'       'A' 'B' 'C' 'Admin'
g2re  'X[^/]*/\(.*/\)*Admin[^/]*$'             'X' '//Admin'
g2re  'X[^/]*/\(.*/\)*Admin[^/]*$'             'X' '///////Admin'
g2re  'X[^/]*/\(.*/\)*Admin[^/]*$'             'X' '///////' 'Admin'
g2re  'T[^/]*/[^/]*Admin[^/]*$'                'T' '*Admin'
g2re  'T[^/]*/.*Admin[^/]*$'                   'T' '**Admin'
g2re  'T[^/]*/\(.*/\)*Admin[^/]*$'             'T' '**' 'Admin'

g2re  'X/\(.*/\)*Admin[^/]*$'                  'X//Admin'
g2re  'T/[^/]*Admin[^/]*$'                     'T/*Admin'
g2re  'T/.*Admin[^/]*$'                         'T/**Admin'
g2re  'T/\(.*/\)*Admin[^/]*$'                  'T/**/Admin'
g2re  'Admin[^/]*$'                            '**/Admin'
g2re  'Admin[^/]*$'                            '*/Admin'
g2re  'Admin[^/]*$'                            '*******/Admin'

#------------------------------------------------------------------------------
rm -f "${tmp_arg2regex}"
endTest

