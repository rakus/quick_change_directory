#!/bin/sh
#
# FILE: shtest-index-qc.sh
#
# ABSTRACT: qc tests with indexes
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-10
#

script_dir="$(cd "$(dirname "$0")" && pwd)" || exit 1

set -u

if [ -n "${BASH_VERSION:-}" ]; then
    shopt -s expand_aliases
fi

export BUILD_TEST_DIRS=true
# shellcheck source=./defines.shinc
. "${script_dir}/defines.shinc"


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
    printf "qc %s" "$*"
    qc "$@" <<< "$num"
    if [ "$PWD" = "$expected" ]; then
        OK
    else
        ERROR
        echo   "Actual: $PWD"
    fi
}

chkQCfoundDirs()
{
    expected_cnt=$1
    shift
    printf "Expected %s dirs: " "$expected_cnt"
    printf "qc %s" "$*"
    real_cnt="$(qc "$@" 2>&1 </dev/null | wc -l)"
    if [ "$real_cnt" = "$expected_cnt" ]; then
        OK
    else
        ERROR
        echo   "Actual: $real_cnt"
    fi
}

startTest "index & qc"

qc -U

dstore :label "$TEST_DIRECTORY/Customer/ACME"

echo ""
printf "test.index exists"
if [ -e  "$TEST_DIRECTORY/.qc/test.index" ]; then
    OK
else
    ERROR
    echo "Can't continue"
    exit 1
fi
printf "test.index entry count"
if [ "$TEST_DIRECTORY" = "$(head -n1  "$TEST_DIRECTORY/.qc/test.index")" ]; then
    # created with find
    expected_cnt=15
else
    # created with fd
    expected_cnt=14
fi

if [ $expected_cnt -eq "$(wc -l < "$TEST_DIRECTORY/.qc/test.index")" ]; then
    OK
else
    ERROR
fi

printf "test.index.hidden exists"
if [ -e "$TEST_DIRECTORY/.qc/test.index.hidden" ]; then
    OK
else
    ERROR
    echo "Can't continue"
    exit 1
fi
printf "test.index.hidden entry count"
if [ "$TEST_DIRECTORY" = "$(head -n1  "$TEST_DIRECTORY/.qc/test.index.hidden")" ]; then
    # created with find
    expected_cnt=5
else
    # created with fd
    expected_cnt=4
fi
if [ $expected_cnt -eq "$(wc -l < "$TEST_DIRECTORY/.qc/test.index.hidden")" ]; then
    OK
else
    ERROR
fi

printf "index.dstore exists"
if [ -e  "$TEST_DIRECTORY/.qc/index.dstore" ]; then
    OK
else
    ERROR
    echo "Can't continue"
    exit 1
fi
printf "index.dstore entry count"
if [ 1 -eq "$(wc -l < "$TEST_DIRECTORY/.qc/index.dstore")" ]; then
    OK
else
    ERROR
fi

echo ""


doQC "$HOME"
doQC "$TEST_DIRECTORY"/Customer/YoYoDyne/Admin Yo Adm
doQC "$TEST_DIRECTORY"/Customer/YoYoDyne/Admin Y A
doQC "$TEST_DIRECTORY"/Customer/YoYoDyne/Admin "$(basename "$TEST_DIRECTORY")"//Y A
doQC "$TEST_DIRECTORY"/Customer/YoYoDyne/Admin t // Y A
doQC "$TEST_DIRECTORY"/Customer/YoYo YoYo/
doQC "$TEST_DIRECTORY"/Customer/YoYo/MyProject 'My?roject'
doQC "$TEST_DIRECTORY"/Customer/YoYo/MyProject 'My*ject'
doQC "$TEST_DIRECTORY"/Customer/YoYoDyne/src 'Cus*//src'

doQC "$TEST_DIRECTORY"/A.B A.B

doQC "$TEST_DIRECTORY"/Customer '[cC]ustomer'

doQC "$TEST_DIRECTORY"/Customer/ACME :label
doQC "$TEST_DIRECTORY"/Customer/ACME :l

doQC "$TEST_DIRECTORY"/Customer/ACME/Admin :label A
doQC "$TEST_DIRECTORY"/Customer/ACME/Admin :l A

doQC "$TEST_DIRECTORY"/Customer/YoYo -i yOyO/
doQC "$TEST_DIRECTORY"/.config/localhost -h local
doQC "$TEST_DIRECTORY"/.config/localhost -hi LOCALHOST
doQC "$TEST_DIRECTORY"/.config/testdir -H testd
doQC "$TEST_DIRECTORY"/testdir testd

chkQCfoundDirs 2 -h testd

case "$(printf "%s\n" "$TEST_DIRECTORY/Customer/YoYo" "$TEST_DIRECTORY/Customer/YoYoDyne" | sort | head -n1)" in
    */Customer/YoYo)
        yoyoIdx=1
        yoyoDyneIdx=2
        ;;
    */Customer/YoYoDyne)
        yoyoDyneIdx=1
        yoyoIdx=2
        ;;
esac

doQCselect "$TEST_DIRECTORY"/Customer/YoYoDyne "$yoyoDyneIdx" YoYo
doQCselect "$TEST_DIRECTORY"/Customer/YoYo "$yoyoIdx" YoYo

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
echo "Testing that command substitution in qc-index.cfg is ignored ..."
echo "test-fail.index $TEST_DIRECTORY -- '.*' \$(echo hallo)" >> "$QC_DIR/qc-index.cfg"

printf "Command substitution ignored"
if qc -u 2>&1 | grep "Possible command substitution" >/dev/null; then
    OK
else
    ERROR
fi


printf "test-fail.index NOT created"
if [ ! -e  "$TEST_DIRECTORY/.qc/test-fail.index" ]; then
    OK
else
    ERROR
fi

cd "${script_dir}" || exit 1

endTest


#---------[ END OF FILE shtest-index-qc.sh ]-----------------------------------
