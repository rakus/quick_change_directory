#!/bin/bash
#
# FILE: test-cron.sh
#
# ABSTRACT: test crontab handling of qc-build-index
#
# This test is a little risky as it manipulates the users crontab. It only
# runs on GitHub Workflow or when the environment variable QC_TEST_CRON
# is set.
#
# AUTHOR: Ralf Schandl
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"


startTest "qc-build-index --cron"

if [ -z "${GITHUB_WORKFLOW:-}" ] && [ -z "${QC_TEST_CRON:-}" ]; then
    echo "Not GitHub workflow and QC_TEST_CRON not set"
    skipTest
fi

if ! command -v crontab >/dev/null 2>&1; then
    echo ""
    echo "Test skipped: Command 'crontab' not available."
    skipTest
fi


printf "Saving original crontab"
# might produce a message if user has no crontab
curEntry="$(crontab -l)"
OK

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

endTest

