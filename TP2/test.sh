#!/bin/bash

TESTS_REP=""
TEST="./tests/level2if1"

OUTPUTexe="output_exec"
OUTPUT3a="output_3a"

ANTLR_JAR="../antlr-3.5.2-complete.jar"
ANTLR_RUNT="../antlr-3.5.2-runtime.jar"
SRC_DIR="./src"

VSL=".vsl"
OUT=".mips_out"
IN=".test_in"
TEST_DIR="./tests/"

CLASSPATHRUN=$SRC_DIR:$ANTLR_JAR:$ANTLR_RUNT

if [ $# -eq 1 ]
then
    TEST=$1
    if [ ! -e $TEST$VSL ]
    then
        echo "File $TEST$VSL not found"
	exit 1
    fi
    

    java -cp $CLASSPATHRUN VslComp $TEST$VSL > $OUTPUT3a
    if [ 0 -eq $? ]
    then 
	cd nachos
	./asm2bin.sh output

	if [ -e ../$TEST$IN ]
	then
	    cat ../$TEST$IN | ./exec.sh output | head -n -3 > ../$OUTPUTexe
	else
	    ./exec.sh output | head -n -3 > ../$OUTPUTexe
	fi
	cd ..
	if [ -e $TEST$OUT ]
	then
	    echo "DIFF : "
	    diff -Bb $OUTPUTexe $TEST$OUT
	fi
    fi
else
for TEST in $(find tests/testlevel? -type f -name '*.vsl')
do
    TEST=${TEST%.*}
    echo "$TEST"

    java -cp $CLASSPATHRUN VslComp $TEST$VSL > $OUTPUT3a
    if [ 0 -eq $? ]
    then 
	cd nachos
	./asm2bin.sh output

	if [ -e ../$TEST$IN ]
	then
	    cat ../$TEST$IN | ./exec.sh output | head -n -3 > ../$OUTPUTexe
	else
	    ./exec.sh output | head -n -3 > ../$OUTPUTexe
	fi 
	cd ..
	echo "DIFF : "
	diff -Bb $OUTPUTexe $TEST$OUT
    fi
done
fi
