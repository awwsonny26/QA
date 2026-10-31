#!/bin/sh
# Restore this experiment's own client link and scoped NAT on the VM router.
set -eu
ip netns list | awk '{print $1}' | grep -qx nv4-client || ip netns add nv4-client
if ! ip link show nv4-lan >/dev/null 2>&1; then
    ip link add nv4-lan type veth peer name nv4-client0
    ip link set nv4-client0 netns nv4-client
fi
ip address replace 10.35.14.1/24 dev nv4-lan
ip link set nv4-lan up
ip -n nv4-client link set lo up
ip -n nv4-client link set nv4-client0 up
ip -n nv4-client address replace 10.35.14.100/24 dev nv4-client0
ip -n nv4-client route replace default via 10.35.14.1
sysctl -w net.ipv4.ip_forward=1
iptables -C FORWARD -i nv4-lan -o enp0s3 -s 10.35.14.0/24 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i nv4-lan -o enp0s3 -s 10.35.14.0/24 -j ACCEPT
iptables -C FORWARD -i enp0s3 -o nv4-lan -d 10.35.14.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i enp0s3 -o nv4-lan -d 10.35.14.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -C POSTROUTING -s 10.35.14.0/24 -o enp0s3 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.35.14.0/24 -o enp0s3 -j MASQUERADE
