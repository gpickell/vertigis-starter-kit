#!/bin/bash
set -e

iptables -F OUTPUT
iptables -P OUTPUT DROP
for cidr in $CIDRS; do
    iptables -A OUTPUT -o eth0 -d "$cidr" -j ACCEPT
done

iptables -A OUTPUT -i eth0 -p tcp -j DROP
iptables -P OUTPUT ACCEPT

"$@" &

trap TERM INT
wait
