#!/usr/bin/env bash
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

g2re()
{
    expected="$1"
    shift
    printf "%s" "$* -> $expected"
    actual="$("$QC_DIR"/qc-backend --print-expr "$@" 2>&1 | tail -n1)"

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

g2re 'dir[^/]*/subdir[^/]*$' dir /subdir
g2re 'dir[^/]*/subdir$' dir /subdir/

g2re 'dir/\(.*/\)*subdir$' dir//subdir/
g2re 'dir/\(.*/\)*subdir$' dir///subdir/
g2re 'dir/\(.*/\)*subdir$' dir////////subdir/
g2re 'dir/\(.*/\)*subdir[^/]*$' dir/ // subdir
g2re 'dir/\(.*/\)*subdir[^/]*$' dir/ //subdir
g2re 'dir[^/]*/\(.*/\)*subdir[^/]*$' dir // subdir
g2re 'dir[^/]*/\(.*/\)*subdir[^/]*$' dir //subdir

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

curDir="${PWD#/}"
curDir="${curDir/./\\.}"
g2re  "${curDir}"'/Admin[^/]*$'                './Admin'
g2re  "${curDir}"'/Ad[^/]*/\(.*/\)*test[^/]*$' './Ad' '//test'
g2re  "${curDir}"'/\(.*/\)*test[^/]*$' './' '//test'

#------------------------------------------------------------------------------
endTest

