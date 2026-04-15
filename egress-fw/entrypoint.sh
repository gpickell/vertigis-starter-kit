#!/bin/bash
set -e

iptables -F OUTPUT
iptables -P OUTPUT ACCEPT
for cidr in $ALLOW_CIDRS; do
    iptables -A OUTPUT -o $1 -d "$cidr" -j ACCEPT
done

iptables -A OUTPUT -o $1 -p tcp -j DROP

sleep infinity &

trap TERM INT
wait
