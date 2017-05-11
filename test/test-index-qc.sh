#!/bin/bash
#
# FILE: test-index-qc.sh
#
# ABSTRACT: 
#
# AUTHOR: Ralf Schandl
#
# CREATED: 2017-05-10
#

script_dir=$(cd "$(dirname $0)" 2>/dev/null; pwd)
script_name="$(basename "$0")"
script_file="$script_dir/$script_name"


BUILD_TEST_DIRS=true
. ${script_dir}/defines.shinc

TEST_STATUS=0

doQC()
{
    cd ${script_dir}
    expected="$1"
    shift
    printf "qc $*"
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
    cd ${script_dir}
    expected="$1"
    num="$2"
    shift 2
    printf "qc $*"
    qc "$@" <<< $num
    if [ "$PWD" = "$expected" ]; then
        OK
    else
        ERROR
        echo   "Actual: $PWD"
    fi
}

startTest "index & qc"

qc -u

dstore :label testDirectory/Customer/ACME/Admin 

echo ""
printf "test.index"
if [ 13 -eq $(wc -l < ${script_dir}/testDirectory/.qc/test.index) ]; then
    OK
else
    ERROR
fi
printf "hidden.index.ext"
if [ 3 -eq $(wc -l < ${script_dir}/testDirectory/.qc/hidden.index.ext) ]; then
    OK
else
    ERROR
fi

printf "index.dstore"
if [ 1 -eq $(wc -l < ${script_dir}/testDirectory/.qc/index.dstore) ]; then
    OK
else
    ERROR
fi

echo ""


doQC ${script_dir}/testDirectory/Customer/YoYoDyne/Admin Yo Adm
doQC ${script_dir}/testDirectory/Customer/YoYoDyne/Admin Y A
doQC ${script_dir}/testDirectory/Customer/YoYoDyne/Admin testDirectory//Y A
doQC ${script_dir}/testDirectory/Customer/YoYoDyne/Admin t // Y A
doQC ${script_dir}/testDirectory/Customer/YoYo YoYo/
doQC ${script_dir}/testDirectory/Customer/YoYo/MyProject 'My?roject'
doQC ${script_dir}/testDirectory/Customer/YoYo/MyProject 'My*ject'
doQC ${script_dir}/testDirectory/Customer/YoYoDyne/src 'Cus*//src'

doQC ${script_dir}/testDirectory/A.B A.B

doQC ${script_dir}/testDirectory/Customer '[cC]ustomer'

doQC ${script_dir}/testDirectory/Customer/ACME/Admin :label
doQC ${script_dir}/testDirectory/Customer/ACME/Admin :l

doQC ${script_dir}/testDirectory/Customer/YoYo -i yOyO/
doQC ${script_dir}/testDirectory/.config/localhost -e local
doQC ${script_dir}/testDirectory/.config/localhost -ei LOCALHOST

doQCselect ${script_dir}/testDirectory/Customer/YoYoDyne 1 YoYo
doQCselect ${script_dir}/testDirectory/Customer/YoYo 2 YoYo


cd "${script_dir}"
rm -rf testDirectory

endTest $TEST_STATUS


#---------[ END OF FILE test-index-qc.sh ]-------------------------------------
