#!/bin/sh
sh 01-build-libssl.sh && \
sh 02-build-libcurl.sh && \
rm -rf bin src log
