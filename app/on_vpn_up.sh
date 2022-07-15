#!/bin/bash
#set -e

export OVPN_CONNECTED="true"

echo "$1" > /tmp/currentvpn/adapter
echo "$4" > /tmp/currentvpn/ip

echo "VPN UP"
#echo "ovpn UP!!! [$OVPN_FILE]"

[ -f /etc/openvpn/up.sh ] && /etc/openvpn/up.sh "$@"

/app/services/openvpn_autokill.sh start
/app/services/services.sh start

exit 0
