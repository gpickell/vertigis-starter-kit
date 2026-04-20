#!/bin/bash

zone=${DNS_HOST#*.}
last=""

while true; do
    sleep 5

    addrs="$(ip -4 -o addr show dev eth0 | awk '{print $4}' | cut -d/ -f1)"
    now=$(date -u +%F)

    updates=(
        "; $now"
        "server $DNS_SERVER"
        "zone $zone"
        "update delete $DNS_HOST A"
    )

    for addr in $addrs; do
        updates+=("update add $DNS_HOST 300 A $addr")
    done

    updates+=("send")
    current=$(printf "%s\n" "${updates[@]}")

    if [ -z "$addrs" ]; then
        current=""
    fi

    if [ "$current" = "$last" ]; then
        current=""
    fi

    if [ -n "$current" ]; then
        echo "$current"        
        echo "$current" > /tmp/state
        
        if [ -n "$NSUPDATE_KINIT" ]; then
            echo "; kinit"
            kinit $NSUPDATE_KINIT
            echo "; nsupdate -g"
            nsupdate -g /tmp/state
        fi

        if [ -n "$NSUPDATE_KEY" ]; then
            echo "; nsupdate -k"
            nsupdate -k "$NSUPDATE_KEY" /tmp/state
        fi

        if [ -n "$NSUPDATE_SECRET" ]; then
            echo "; nsupdate -y"
            nsupdate -y "$NSUPDATE_SECRET" /tmp/state
        fi

        if [ "$?" -ne 0 ]; then
            echo "; fail"
            last=""
        else
            echo "; done"
            last="$current"
        fi
    fi
done
