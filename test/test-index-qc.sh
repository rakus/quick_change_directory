#!/bin/bash
#
# FILE: test-index-qc.sh
#
# ABSTRACT: qc tests with indexes
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-10
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

export BUILD_TEST_DIRS=true
# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"

TEST_STATUS=0

doQC()
{
    cd "${script_dir}" || exit 1
    expected="$1"
    shift
    printf "qc %s" "$*"
    qc "$@"
    if [ "$PWD" = "$expected" ]; then
        OK
    else
        ERROR
        echo   "Actual: $PWD"
    fi
}

doQCselect()
{
    cd "${script_dir}" || exit 1
    expected="$1"
    num="$2"
    shift 2
    printf "qc %s" "$@"
    qc "$@" <<< "$num"
    if [ "$PWD" = "$expected" ]; then
        OK
    else
        ERROR
        echo   "Actual: $PWD"
    fi
}

startTest "index & qc"

qc -U

dstore :label testDirectory/Customer/ACME/Admin

echo ""
printf "test.index exists"
if [ -e  "${script_dir}/testDirectory/.qc/test.index" ]; then
    OK
else
    ERROR
    echo "Can't continue"
    exit 1
fi
printf "test.index entry count"
if [ 13 -eq "$(wc -l < "${script_dir}/testDirectory/.qc/test.index")" ]; then
    OK
else
    ERROR
fi

printf "hidden.index.ext exists"
if [ -e "${script_dir}/testDirectory/.qc/hidden.index.ext" ]; then
    OK
else
    ERROR
    echo "Can't continue"
    exit 1
fi
printf "hidden.index.ext entry count"
if [ 3 -eq "$(wc -l < "${script_dir}/testDirectory/.qc/hidden.index.ext")" ]; then
    OK
else
    ERROR
fi

printf "index.dstore exists"
if [ -e  "${script_dir}/testDirectory/.qc/index.dstore" ]; then
    OK
else
    ERROR
    echo "Can't continue"
    exit 1
fi
printf "index.dstore entry count"
if [ 1 -eq "$(wc -l < "${script_dir}/testDirectory/.qc/index.dstore")" ]; then
    OK
else
    ERROR
fi

echo ""


doQC "${script_dir}"/testDirectory/Customer/YoYoDyne/Admin Yo Adm
doQC "${script_dir}"/testDirectory/Customer/YoYoDyne/Admin Y A
doQC "${script_dir}"/testDirectory/Customer/YoYoDyne/Admin testDirectory//Y A
doQC "${script_dir}"/testDirectory/Customer/YoYoDyne/Admin t // Y A
doQC "${script_dir}"/testDirectory/Customer/YoYo YoYo/
doQC "${script_dir}"/testDirectory/Customer/YoYo/MyProject 'My?roject'
doQC "${script_dir}"/testDirectory/Customer/YoYo/MyProject 'My*ject'
doQC "${script_dir}"/testDirectory/Customer/YoYoDyne/src 'Cus*//src'

doQC "${script_dir}"/testDirectory/A.B A.B

doQC "${script_dir}"/testDirectory/Customer '[cC]ustomer'

doQC "${script_dir}"/testDirectory/Customer/ACME/Admin :label
doQC "${script_dir}"/testDirectory/Customer/ACME/Admin :l

doQC "${script_dir}"/testDirectory/Customer/YoYo -i yOyO/
doQC "${script_dir}"/testDirectory/.config/localhost -e local
doQC "${script_dir}"/testDirectory/.config/localhost -ei LOCALHOST


case "$(printf "%s\n" testDirectory/Customer/YoYo testDirectory/Customer/YoYoDyne | sort | head -n1)" in
    testDirectory/Customer/YoYo)
        yoyoIdx=1
        yoyoDyneIdx=2
        ;;
    testDirectory/Customer/YoYoDyne)
        yoyoDyneIdx=1
        yoyoIdx=2
        ;;
esac

doQCselect "${script_dir}"/testDirectory/Customer/YoYoDyne $yoyoDyneIdx YoYo
doQCselect "${script_dir}"/testDirectory/Customer/YoYo $yoyoIdx YoYo

# For ksh the '| cat' is needed. Don't know why.
NOT_EXIST_OUT="$(qc xx yy zz 2>&1 | cat)"
printf "qc xx yy zz (Check output on not existing dir)"
if [ 1 -eq "$( echo "$NOT_EXIST_OUT"| wc -l)" ]; then
    OK
else
    ERROR
    echo >&2 "Invalid output:"
    echo >&2 "$NOT_EXIST_OUT"
    echo >&2 "---------------"
fi
printf "qc xx yy zz (Check error message on not existing dir)"
if echo "$NOT_EXIST_OUT" | grep "qc: xx yy zz: No matching directory found" >/dev/null; then
    OK
else
    ERROR
    echo >&2 "Invalid output:"
    echo >&2 "$NOT_EXIST_OUT"
    echo >&2 "---------------"
fi


echo
echo "Testing that command substitution in qc-index.cfg is ignores ..."
echo "test-fail.index ${script_dir}/testDirectory -- '.*' \$(echo hallo)" >> "$QC_DIR/qc-index.cfg"

printf "Command substitution ignored"
if qc -u 2>&1 | grep "Possible command substitution" >/dev/null; then
    OK
else
    ERROR
fi


printf "test-fail.index NOT created"
if [ ! -e  "${script_dir}/testDirectory/.qc/test-fail.index" ]; then
    OK
else
    ERROR
fi

cd "${script_dir}" || exit 1

endTest $TEST_STATUS


#---------[ END OF FILE test-index-qc.sh ]-------------------------------------
