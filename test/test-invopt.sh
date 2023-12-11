#!/usr/bin/env bash
#
# FILE: test-invopt.sh
#
# ABSTRACT: check detection of invalid options
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2021-03-12
#
# shellcheck disable=SC2059
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

export PATH="$QC_DIR:$PATH"

# just check if the option was detected as unknown
# $*: the command line to execute
check_inv_opt_detected()
{
    printf "%s " "$@"
    if "$@" 2>&1 | grep -q "Try '[^ ]* --help' for more information."; then
        OK
    else
        ERROR
    fi
}

startTest "Invalid option detection"

check_inv_opt_detected qc-backend -Z
check_inv_opt_detected dstore -Z
check_inv_opt_detected qc-build-index -Z
check_inv_opt_detected qc-backend --wrong
check_inv_opt_detected dstore --wrong
check_inv_opt_detected qc-build-index --wrong

endTest
