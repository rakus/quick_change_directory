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
    echo -n "Version $1"
    if [ -n "$2" ]; then
        OK
    else
        ERROR
    fi
}

TEST_STATUS=0

startTest "Version Number"

make_version="$(grep "^QC_VERSION " ./Makefile | sed 's/^.* = //')"
script_version="$(./quick-change-directory --version 2>&1 | sed 's/^.* v//')"
dstore_version="$(./dstore --version | sed 's/^.* v//')"
build_idx_version="$(./qc-build-index --version | sed 's/^.* v//')"

test_set "in Makefile" "$make_version"
test_set "from quick-change-directory --version" "$script_version"
test_set "from quick_change_directory.sh --version" "$dstore_version"
test_set "from qc-build-index --version" "$build_idx_version"

typeset -A version
version[$make_version]=1
version[$script_version]=1
version[$dstore_version]=1
version[$build_idx_version]=1

echo -n "All versions same"
if [ ${#version[@]} -eq 1 ]; then
    OK
else
    ERROR
    echo >&2 "    Makefile:                  $make_version"
    echo >&2 "    quick_change_directory.sh: $dstore_version"
    echo >&2 "    quick-change-directory:    $script_version"
    echo >&2 "    qc-build-index:            $build_idx_version"
fi

script_version_lbl="$(./quick-change-directory --version 2>&1 | sed 's/^[^ ]*//')"
dstore_version_lbl="$(./dstore --version | sed 's/^[^ ]*//')"
build_idx_version_lbl="$(./qc-build-index --version | sed 's/^[^ ]*//')"

typeset -A version_lbl
version_lbl[$script_version_lbl]=1
version_lbl[$dstore_version_lbl]=1
version_lbl[$build_idx_version_lbl]=1

echo -n "Test product name"
if [ ${#version_lbl[@]} -eq 1 ]; then
    OK
else
    ERROR
    echo >&2 "    quick_change_directory.sh: $dstore_version_lbl"
    echo >&2 "    quick-change-directory:    $script_version_lbl"
    echo >&2 "    qc-build-index:            $build_idx_version_lbl"
fi

endTest $TEST_STATUS

exit $TEST_STATUS

