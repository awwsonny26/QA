#!/bin/sh
set -eu
case "${reason:-}" in
    PREINIT)
        ip link set "$interface" up
        ;;
    BOUND|RENEW|REBIND|REBOOT)
        ip address flush dev "$interface" scope global
        ip address add "$new_ip_address/24" dev "$interface"
        set -- $new_routers
        ip route replace default via "$1" dev "$interface"
        : > /run/nv4-resolv.conf
        for dns in $new_domain_name_servers; do
            printf 'nameserver %s\n' "$dns" >> /run/nv4-resolv.conf
        done
        ;;
    EXPIRE|FAIL|RELEASE|STOP)
        ip address flush dev "$interface" scope global
        ;;
esac
