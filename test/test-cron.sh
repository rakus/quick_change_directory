#!/bin/bash
#
# FILE: test-cron.sh
#
# ABSTRACT: test crontab handling of qc-build-index
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-11
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

if ! command -v crontab >/dev/null 2>&1; then
    echo "Test skipped: Command 'crontab' not available."
    exit 0
fi

startTest "qc-build-index --cron"


printf "Saving original crontab"
if curEntry="$(crontab -l 2>/dev/null)"; then
    OK
else
    ERROR
    echo >&2 "Exiting before we destroy something"
    endTest $TEST_STATUS
fi

printf "List cron entry"
if qc-build-index --cron >/dev/null; then
    OK
else
    ERROR
fi

printf "Remove cron entry"
qc-build-index --cron 0 >/dev/null
if [ -z "$(qc-build-index --cron >/dev/null)" ]; then
    OK
else
    ERROR
fi

printf "Fail adding 60 minutes"
if ! qc-build-index --cron 60 >/dev/null 2>&1; then
    OK
else
    ERROR
fi

printf "Add cron entry all 43 minutes"
qc-build-index --cron 43 >/dev/null
if [[ "$(qc-build-index --cron | grep -v '^#')" = '*/43 '* ]]; then
    OK
else
    ERROR
fi

# remove entry
printf "Remove cron entry again"
qc-build-index --cron 0 >/dev/null
if [ -z "$(qc-build-index --cron >/dev/null)" ]; then
    OK
else
    ERROR
fi

printf "Restore initial crontab"
if (echo "$curEntry" ) | crontab -; then
    OK
else
    ERROR
fi

endTest $TEST_STATUS


#---------[ END OF FILE test-cron.sh ]-----------------------------------------
