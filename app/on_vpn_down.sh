#!/bin/bash
#set -e

echo "VPN DOWN"

[ -f /etc/openvpn/down.sh ] && /etc/openvpn/down.sh "$@"

#killall /usr/sbin/sockd 2>/dev/null &
#killall /usr/sbin/sshd 2>/dev/null &

/app/services/services.sh stop

exit 0
