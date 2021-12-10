#!/bin/bash
set -e

for test in `ls t/*`; do
    echo -n "${test} ... "
    p27=$(cat $test | python2.7)
    p2p=$(cat $test | raku python2.raku | perl)
    if [[ "X${p27}" = "X${p2p}" ]]; then
        echo "OK";
    else
        echo "FAILED"
    fi
done
