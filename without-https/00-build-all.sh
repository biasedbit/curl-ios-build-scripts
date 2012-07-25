#!/bin/sh
SCRIPTS="01-build-libcurl2.sh"

for SCRIPT in ${SCRIPTS}
do
    sh ${SCRIPT}

    rc=$?
    if [[ $rc != 0 ]] ; then
        echo "! Error while running script ${SCRIPT}; aborted."
        exit $rc
    fi
done
