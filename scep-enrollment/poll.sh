#!/bin/bash
set -e

sleep 3s
getcert list-cas -c scep
getcert list

while true; do
    sleep 24h
    /app/init.ts
    update-ca-certificates
    getcert list-cas -c scep
    getcert list
done
