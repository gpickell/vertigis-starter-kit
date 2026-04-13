#!/bin/bash
set -e

export PASSWORD=$(cat /run/secrets/admin-password)

/usr/bin/entrypoint.sh /config \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    --disable-telemetry \
    --disable-workspace-trust > /dev/null 2> /dev/null &

if [ "$#" -gt 0 ]; then
    exec "$@"
fi

trap exit INT TERM
wait
