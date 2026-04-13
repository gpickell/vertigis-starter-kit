#!/bin/bash
set -e

SCEP_DIR=`cat /tmp/.dir`
SCEP_URL=`cat /tmp/.url`

cd "$SCEP_DIR"
/usr/libexec/certmonger/scep-submit -u "$SCEP_URL" -C > chain.pem
cat cert.pem chain.pem > fullchain.pem
