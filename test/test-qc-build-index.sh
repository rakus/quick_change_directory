#!/usr/bin/env bash
#
# FILE: test-qc-build-index.sh
#
# ABSTRACT: Test qc-build-index
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2023-11-23
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

export BUILD_TEST_DIRS=true
# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

build_index()
{
    echo "Calling: qc-build-index $*"
    if ! "$script_dir/../qc-build-index" "$@"; then
        ERROR
    fi

}

clear_test_dirs()
{
    if [ -d "$TEST_DIRECTORY" ]; then
        rm -rf "${TEST_DIRECTORY:?}"/.* "${TEST_DIRECTORY:?}"/*
    fi
}
create_dirs()
{
    for d in "$@"; do
        mkdir -p "$TEST_DIRECTORY/$d"
    done
    mkdir -p "$TEST_DIRECTORY/.qc"
}

check_lines()
{
    local msg="$1"
    local file="$TEST_DIRECTORY/.qc/$2"
    local lines="$3"

    local cnt=0

    echo -n "Check $msg (expect $lines entries)"
    if [ -e "$file" ]; then
        cnt="$(wc -l < "$file")"
    fi

    if [ "$lines" -eq "$cnt" ]; then
        OK
    else
        ERROR
        echo >&2 "     - actual count: $cnt"
    fi
}

startTest "qc-build-index"

typeset -l LC_HOSTNAME="$HOSTNAME"

do_test()
{
    clear_test_dirs
    create_dirs a/{a,b,c}/{a,b,c} h/{a,.b,.c}/{a,.b,.c,ignore}/s d/t/x a/N$'\n'L
    cat <<EOF > "$TEST_DIRECTORY/.qc/qc-index.cfg"
test.index "$TEST_DIRECTORY" -- ignore
test.index.hidden "$TEST_DIRECTORY" -- .qc ignore
test.index.ext "$TEST_DIRECTORY"
test-with-hidden.index.ext -h "$TEST_DIRECTORY"
ignore.index -f '*/ignore' -f '*/ignore/*'  "$TEST_DIRECTORY"
host-local.index.ext.host.\$HOSTNAME -h "$TEST_DIRECTORY"
host-local.index.hidden.host.\$HOSTNAME "$TEST_DIRECTORY" -- .qc ignore
EOF


    # delete all indexes (if they exist)
    rm -f "$TEST_DIRECTORY/.qc/"*.index*

    echo
    echo "Build index"
    build_index
    check_lines "normal index" "test.index" 21
    check_lines "hidden index" "test.index.hidden" 18
    check_lines "extended index" "test.index.ext" 23
    check_lines "extended index with hidden" "test-with-hidden.index.ext" 46
    check_lines "filtered index" "ignore.index" 2
    check_lines "host-local extended index" "host-local.index.ext.host.$LC_HOSTNAME" 46
    check_lines "host-local hidden index" "host-local.index.hidden.host.$LC_HOSTNAME" 18

    echo
    echo "Incremental update index"
    create_dirs h/.b/X h/a/.b/X
    build_index -i "$TEST_DIRECTORY/h/a"
    check_lines "normal index" "test.index" 21
    check_lines "hidden index" "test.index.hidden" 19
    check_lines "extended index" "test.index.ext" 23
    check_lines "extended index with hidden" "test-with-hidden.index.ext" 47
    check_lines "filtered index" "ignore.index" 2

    echo
    echo "Don't update extended index"
    rm   "$TEST_DIRECTORY/.qc/"*.index.ext*
    build_index -E
    echo -n "Extended index not created"
    if [ -e "$TEST_DIRECTORY/.qc/test.index.ext" ]; then
        ERROR
    else
        OK
    fi
    echo -n "Host-local extended index not created"
    if [ -e "$TEST_DIRECTORY/.qc/host-local.index.ext.host.$LC_HOSTNAME" ]; then
        ERROR
    else
        OK
    fi

    echo
    echo "Don't create hidden index"
    rm   "$TEST_DIRECTORY/.qc/"*.index.hidden*
    build_index -H
    echo -n "Hidden index not created"
    if [ -e "$TEST_DIRECTORY/.qc/test.index.hidden" ]; then
        ERROR
    else
        OK
    fi
    echo -n "Host-local hidden index not created"
    if [ -e "$TEST_DIRECTORY/.qc/host-local.index.hidden.host.$LC_HOSTNAME" ]; then
        ERROR
    else
        OK
    fi

    echo
    echo "Only create create index by name 'ignore'"
    rm   "$TEST_DIRECTORY/.qc/"*.index*
    build_index ignore
    echo -n "Only ignore.index created"
    if [ "$(ls "$TEST_DIRECTORY/.qc/"*.index*)" = "$TEST_DIRECTORY/.qc/ignore.index" ]; then
        OK
    else
        ERROR
    fi

    if [ -z "${QC_USE_FIND:-}" ]; then

        echo
        echo "Test with fd and .gitignore"
        # Ignore sub-tree 'a/'
        echo "a" > "$TEST_DIRECTORY/.gitignore"
        mkdir -p "$TEST_DIRECTORY/.git"
        build_index
        check_lines "normal index" "test.index" 5
        check_lines "hidden index" "test.index.hidden" 12
        check_lines "extended index" "test.index.ext" 5
        check_lines "extended index with hidden" "test-with-hidden.index.ext" 22
        check_lines "filtered index" "ignore.index" 2

        echo
        echo "Test with fd and ignoring .gitignore"

        sed -i "s/ / -I /" "$TEST_DIRECTORY/.qc/qc-index.cfg"

        build_index
        check_lines "normal index" "test.index" 21
        check_lines "hidden index" "test.index.hidden" 21
        check_lines "extended index" "test.index.ext" 23
        check_lines "extended index with hidden" "test-with-hidden.index.ext" 49
        check_lines "filtered index" "ignore.index" 2
    fi
}

FD_CMD="$(command -v fdfind)"
if [ -z "$FD_CMD" ]; then
    FD_CMD="$(command -v fd)"
    if ! "$FD_CMD" -X 2>&1 | grep -q -- '--help'; then
        # fd seems to be from FDclone - clear FD_CMD to use 'find'
        FD_CMD=
    fi
fi

if [ -n "$FD_CMD" ]; then
    echo
    echo "====[ Testing with fd ]======================================================"
    # Test with fd
    unset QC_USE_FIND
    do_test
fi

echo
echo "====[ Testing with find ]===================================================="
# Force using find
export QC_USE_FIND=true
do_test

endTest






