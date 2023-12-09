#!/usr/bin/env bash
#
# FILE: test-version.sh
#
# ABSTRACT: test consistent version output
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

export PATH="$QC_DIR:$PATH"

test_set()
{
    echo -n "$1"
    if [ -n "$2" ]; then
        OK
    else
        ERROR
    fi
}

startTest "Version Output"

make_version="$(grep "^QC_VERSION " "$script_dir/../Makefile" | sed 's/^.* = //')"
script_version="$(qc-backend --version 2>&1 | sed 's/^.* v//')"
dstore_version="$(dstore --version | sed 's/^.* v//')"
build_idx_version="$(qc-build-index --version | sed 's/^.* v//')"

test_set "Version in Makefile" "$make_version"
test_set "Version from qc-backend --version" "$script_version"
test_set "Version from qc-build-index --version" "$build_idx_version"
test_set "Version from dstore --version" "$dstore_version"

typeset -i count

count="$(printf '%s\n' "$make_version" "$script_version" "$dstore_version" "$build_idx_version" | sort -u | wc -l)"

echo -n "Test same version"
if [ "$count" = 1 ]; then
    OK
    echo "  Version is \"$make_version\""
else
    ERROR
    echo >&2 "    Makefile:         $make_version"
    echo >&2 "    qc-backend:       $script_version"
    echo >&2 "    qc-build-index:   $build_idx_version"
    echo >&2 "    dstore:           $dstore_version"
fi

script_version_lbl="$(qc-backend --version 2>&1 | sed 's/^[^ ]* - //;s/ v[0-9].*$//')"
dstore_version_lbl="$(dstore --version | sed 's/^[^ ]* - //;s/ v[0-9].*$//')"
build_idx_version_lbl="$(qc-build-index --version | sed 's/^[^ ]* - //;s/ v[0-9].*$//')"

test_set "Product name from qc-backend --version" "$script_version_lbl"
test_set "Product name from qc-build-index --version" "$build_idx_version_lbl"
test_set "Product name from dstore --version" "$dstore_version_lbl"

count="$(printf '%s\n' "${script_version_lbl#* - }" "${dstore_version_lbl#* - }" "${build_idx_version_lbl#* - }" | sort -u | wc -l)"
echo -n "Test same product name"
if [ "$count" = 1 ]; then
    OK
    echo "  Product is \"${script_version_lbl#* - }\""
else
    ERROR
    echo >&2 "    qc-backend:       $script_version_lbl"
    echo >&2 "    qc-build-index:   $build_idx_version_lbl"
    echo >&2 "    dstore:           $dstore_version_lbl"
fi

endTest

