#!/bin/sh
sh 01-build-libgpgerror.sh && \
sh 02-build-libgcrypt.sh && \
sh 03-build-libgnutls.sh && \
sh 04-build-libcurl.sh && \
rm -rf bin src log
