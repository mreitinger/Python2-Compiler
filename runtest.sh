#!/bin/bash
set -e

testcase=$1

p27=$(cat $testcase | python2.7)
p2p=$(cat $testcase | raku python2.raku | perl)

if [[ "X${p27}" = "X${p2p}" ]]; then
    echo "${testcase} ... OK"
else
    echo "${testcase} ... FAILED"
fi
