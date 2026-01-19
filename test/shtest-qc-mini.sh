#!/usr/bin/env bash
#
# FILE: shtest-qc-mini.sh
#
# ABSTRACT: Basic tests for qc_mini
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2023-12-10
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

SKIP_QC_INSTALL=true
# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

# shellcheck source=./../qc_mini
. "${script_dir}/../qc_mini"

tmp_arg2regex="$(mktemp -t "qc-mini-arg2regex.XXXX")"
# shellcheck disable=SC2064  # should expand now
#trap "rm -f '$tmp_arg2regex'" EXIT

g2re()
{
    expected="$1"
    shift
    printf "%s" "$* -> $expected"
    actual="$("$tmp_arg2regex" "$@" 2>&1 | tail -n1)"

    if [ "$actual" = "$expected" ]; then
        OK
    else
        ERROR
        echo "   Expected: >>$expected<<"
        echo "   Actual:   >>$actual<<"
    fi
}

startTest "qc_mini"

if [ "$(uname)" = "Darwin" ]; then
    echo "qc_mini not compatible with MacOS/Darwin"
    skipTest
fi

if [ -z "${TEST_SHELL:-}" ]; then
    if [ -n "${BASH_VERSION:-}" ]; then
        TEST_SHELL="bash"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        TEST_SHELL="zsh"
    elif [ -n "${KSH_VERSION:-}" ]; then
        TEST_SHELL="ksh"
    else
        echo "Can't identify shell that runs this script -- test skipped"
        skipTest
    fi
fi

# Extract pattern creation code
printf "Extracting pattern creation code"
echo "#!/usr/bin/env $TEST_SHELL" > "$tmp_arg2regex"
sed -n '/^ *## PATTERN_BUILD-START/,/^ *## PATTERN_BUILD-END/p' "$script_dir/../qc_mini" >> "$tmp_arg2regex"
echo '__qc_create_pattern "$@"' >> "$tmp_arg2regex"

chmod +x "$tmp_arg2regex"

if [[ "$("$tmp_arg2regex" "TEST/")" = *'TEST'* ]]; then
    OK
else
    ERROR
    echo "Invalid script:"
    cat "$tmp_arg2regex"
    echo "========"
    $tmp_arg2regex "TEST/"
    endTest
fi

g2re '^:label' ":label"

g2re '/TEST$' "TEST/"

g2re '/dir[^/]*$' 'dir'
g2re '/dir/subdir[^/]*$' 'dir/subdir'
g2re '/dir/subdir[^/]*$' dir/ subdir
g2re '/dir[^/]*/subdir[^/]*$' dir subdir
g2re '/dir[^/]*/subdir$' dir subdir/

g2re '/dir[^/]*/subdir[^/]*$' dir /subdir
g2re '/dir[^/]*/subdir$' dir /subdir/

g2re '/dir/\(.*/\)*subdir$' dir//subdir/
g2re '/dir/\(.*/\)*subdir$' dir///subdir/
g2re '/dir/\(.*/\)*subdir$' dir////////subdir/
g2re '/dir/\(.*/\)*subdir[^/]*$' dir/ // subdir
g2re '/dir/\(.*/\)*subdir[^/]*$' dir/ //subdir
g2re '/dir[^/]*/\(.*/\)*subdir[^/]*$' dir // subdir
g2re '/dir[^/]*/\(.*/\)*subdir[^/]*$' dir //subdir

g2re '/dir/[^/]*/subdir$' 'dir/*/subdir/'


g2re '/[^/]*$' '*'
g2re '/[^/]*$' '*/'
g2re '/[^/]$' '?/'

g2re '/dir[^/]*$' 'dir'
g2re '/dir/subdir[^/]*$' 'dir/subdir'
g2re '/dir/subdir[^/]*$' dir/ subdir
g2re '/dir[^/]*/subdir[^/]*$' dir subdir
g2re '/dir[^/]*/subdir$' dir subdir/

g2re '/dir[^/]*/subdir[^/]*$' dir /subdir
g2re '/dir[^/]*/subdir$' dir /subdir/

g2re '/dir/\(.*/\)*subdir$' dir//subdir/
g2re '/dir/\(.*/\)*subdir$' dir///subdir/
g2re '/dir/\(.*/\)*subdir$' dir////////subdir/
g2re '/dir/\(.*/\)*subdir[^/]*$' dir/ // subdir
g2re '/dir/\(.*/\)*subdir[^/]*$' dir/ //subdir
g2re '/dir[^/]*/\(.*/\)*subdir[^/]*$' dir // subdir
g2re '/dir[^/]*/\(.*/\)*subdir[^/]*$' dir //subdir

g2re '/dir/[^/]*/subdir$' 'dir/*/subdir/'

g2re '/a[^/]b$' 'a?b/'

g2re  '/Admin[^/]*$'                             'Admin'
g2re  '/T[^/]*/\(.*/\)*Admin[^/]*$'             'T' '//' 'Admin'

g2re  '/Admin[^/]*$'                            '/Admin'
g2re  '/Admin$'                                 'Admin/'
g2re  '/Admin$'                                 'Admin//'
g2re  '/Admin$'                                 'Admin/////'
g2re  '/T[^/]*/Admin[^/]*$'                     'T' 'Admin'
g2re  '/X[^/]*/T[^/]*/Admin[^/]*$'              'X' 'T' 'Admin'
g2re  '/A[^/]*/B[^/]*/C[^/]*/Admin[^/]*$'       'A' 'B' 'C' 'Admin'
g2re  '/X[^/]*/\(.*/\)*Admin[^/]*$'             'X' '//Admin'
g2re  '/X[^/]*/\(.*/\)*Admin[^/]*$'             'X' '///////Admin'
g2re  '/X[^/]*/\(.*/\)*Admin[^/]*$'             'X' '///////' 'Admin'
g2re  '/T[^/]*/[^/]*Admin[^/]*$'                'T' '*Admin'

g2re  '/X/\(.*/\)*Admin[^/]*$'                  'X//Admin'
g2re  '/T/[^/]*Admin[^/]*$'                     'T/*Admin'
g2re  '/Admin[^/]*$'                            '*/Admin'


endTest

