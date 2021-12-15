#!/bin/bash
set -o pipefail

testcase=$1

p27=$(cat $testcase | python2.7 2>&1)
if [[ $? -gt 0 ]]; then
    echo "${testcase} ... FAILED (python interpreter)"
    exit 1
fi

p2p=$(cat $testcase | raku python2.raku 2>&1 | perl 2>&1)
if [[ $? -gt 0 ]]; then
    echo "${testcase} ... FAILED (raku/perl interpreter)"
    exit 1
fi

if [[ "X${p27}" = "X${p2p}" ]]; then
    echo "${testcase} ... OK"
    exit 0
else
    echo "${testcase} ... FAILED"
    exit 1
fi
