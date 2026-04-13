#!/bin/bash
set -e

passwd_file=~/.admin-password
[ -z "$PASSWORD" ] && export PASSWORD=$(cat "$passwd_file")
[ -f "$passwd_file" ] || echo "$PASSWORD" > "$passwd_file"

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
