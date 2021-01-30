#!/bin/bash
#
# FILE: test-version.sh
#
# ABSTRACT:
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2020-10-23
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1
# script_name="$(basename "$0")"
# script_file="$script_dir/$script_name"

# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

cd "$script_dir/.." || exit 1


test_set()
{
    echo -n "$1"
    if [ -n "$2" ]; then
        OK
    else
        ERROR
    fi
}

TEST_STATUS=0

startTest "Version Number"

make_version="$(grep "^QC_VERSION " ./Makefile | sed 's/^.* = //')"
script_version="$(qc-backend --version 2>&1 | sed 's/^.* v//')"
dstore_version="$(dstore --version | sed 's/^.* v//')"
build_idx_version="$(qc-build-index --version | sed 's/^.* v//')"

test_set "Version in Makefile" "$make_version"
test_set "Version from qc-backend --version" "$script_version"
test_set "Version from quick_change_directory.sh --version" "$dstore_version"
test_set "Version from qc-build-index --version" "$build_idx_version"

typeset -i count

count="$(printf '%s\n' "$make_version" "$script_version" "$dstore_version" "$build_idx_version" | sort -u | wc -l)"

echo -n "Test same version"
if [ "$count" = 1 ]; then
    OK
else
    ERROR
    echo >&2 "    Makefile:                  $make_version"
    echo >&2 "    quick_change_directory.sh: $dstore_version"
    echo >&2 "    qc-backend:                $script_version"
    echo >&2 "    qc-build-index:            $build_idx_version"
fi

script_version_lbl="$(qc-backend --version 2>&1 | sed 's/^[^ ]*//')"
dstore_version_lbl="$(dstore --version | sed 's/^[^ ]*//')"
build_idx_version_lbl="$(qc-build-index --version | sed 's/^[^ ]*//')"

test_set "Product name from qc-backend --version" "$script_version_lbl"
test_set "Product name from quick_change_directory.sh --version" "$dstore_version_lbl"
test_set "Product name from qc-build-index --version" "$build_idx_version_lbl"

count="$(printf '%s\n' "$script_version_lbl" "$dstore_version_lbl" "$build_idx_version_lbl" | sort -u | wc -l)"
echo -n "Test same product name"
if [ "$count" = 1 ]; then
    OK
else
    ERROR
    echo >&2 "    quick_change_directory.sh: $dstore_version_lbl"
    echo >&2 "    qc-backend:                $script_version_lbl"
    echo >&2 "    qc-build-index:            $build_idx_version_lbl"
fi

endTest $TEST_STATUS

exit $TEST_STATUS

