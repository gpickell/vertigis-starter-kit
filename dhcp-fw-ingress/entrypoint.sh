#!/bin/bash
set -e

rm -rf /tmp/* /run/dbus/* /var/run/avahi-daemon/*
mkdir -p /data /run/dbus

# ingress firewall
iptables -F INPUT
iptables -P INPUT DROP
iptables -A INPUT -i eth0 -p tcp --dport 80  -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -j DROP
iptables -P INPUT ACCEPT

ip addr flush dev eth0
dbus-daemon --system --fork --nopidfile
avahi-daemon --daemonize --no-chroot
exec dhcpcd -B -4 -h "$DHCP_HOSTNAME" eth0
