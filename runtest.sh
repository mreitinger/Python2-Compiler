#!/bin/bash
set -o pipefail

testcase=$1

echo "1..3"
p27=$(python2.7 $testcase 2>&1)
if [[ $? -gt 0 ]]; then
    echo "not ok 1 # ${testcase} ... FAILED (python interpreter)"
    exit 1
else
    echo "ok 1"
fi

p2p=$(raku python2.raku $testcase 2>&1 | perl 2>&1)
if [[ $? -gt 0 ]]; then
    echo "not ok 2 # ${testcase} ... FAILED (raku/perl interpreter)"
    exit 1
else
    echo "ok 2"
fi

if [[ "X${p27}" = "X${p2p}" ]]; then
    echo "ok 3 # ${testcase}"
    exit 0
else
    echo "not ok 3 # ${testcase}"
    exit 1
fi
