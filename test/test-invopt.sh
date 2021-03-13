#!/bin/bash
#
# FILE: test-invopt.sh
#
# ABSTRACT: check detection of invalid options
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2021-03-12
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

startTest "Invalid option detection"

printf "qc -Z"
if qc-backend -Z 2>&1 | grep -q "Invalid option 'Z'"; then
    OK
else
    ERROR
fi
printf "dstore -Z"
if dstore -Z 2>&1 | grep -q "Invalid option 'Z'"; then
    OK
else
    ERROR
fi
printf "qc-build-index -Z"
if qc-build-index -Z 2>&1 | grep -q "Invalid option 'Z'"; then
    OK
else
    ERROR
fi

printf "qc --wrong"
if qc-backend --wrong 2>&1 | grep -q "Invalid option '--wrong'"; then
    OK
else
    ERROR
fi
printf "dstore --wrong"
if dstore --wrong 2>&1 | grep -q "Invalid option '--wrong'"; then
    OK
else
    ERROR
fi
printf "qc-build-index --wrong"
if qc-build-index --wrong 2>&1 | grep -q "Invalid option '--wrong'"; then
    OK
else
    ERROR
fi

endTest
