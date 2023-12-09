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

#
# Adjust to different versions of /bin/getopt
# Maybe it is a bad idea to check for this error messages
#
if getopt "o" -D 2>&1 | grep -q invalid; then
    # "newer version e.g 2.37.4
    invShortOpt="invalid option -- '%c'"
    invLongOpt="unrecognized option '--%s'"
else
    invShortOpt="unknown option -- %c"
    invLongOpt="unknown option -- %s"
fi




startTest "Invalid option detection"

printf "qc -Z"
if qc-backend -Z 2>&1 | grep -q "$(printf "$invShortOpt" Z)"; then
    OK
else
    ERROR
fi
printf "dstore -Z"
if dstore -Z 2>&1 | grep -q "$(printf "$invShortOpt" Z)"; then
    OK
else
    ERROR
fi
printf "qc-build-index -Z"
if qc-build-index -Z 2>&1 | grep -q "$(printf "$invShortOpt" Z)"; then
    OK
else
    ERROR
fi

printf "qc --wrong"
if qc-backend --wrong 2>&1 | grep -q "$(printf "$invLongOpt" wrong)"; then
    OK
else
    ERROR
fi
printf "dstore --wrong"
if dstore --wrong 2>&1 | grep -q "$(printf "$invLongOpt" wrong)"; then
    OK
else
    ERROR
fi
printf "qc-build-index --wrong"
if qc-build-index --wrong 2>&1 | grep -q "$(printf "$invLongOpt" wrong)"; then
    OK
else
    ERROR
fi

endTest
