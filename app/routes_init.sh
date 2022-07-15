#!/bin/bash

[ "$DEBUG" == 'true' ] && set -x

#lo forzo perchè altrimenti mi ritrovo il search del dominio, che dopo la connessione della vpn non va piu internet!
if [ "$USE_GOOGLE_DNS_IF_NEED" != 'false' ] ; then
    if grep -q "search " "/etc/resolv.conf"; then
        USE_GOOGLE_DNS='true'
    fi    
fi

if [ "$USE_GOOGLE_DNS" == 'true' ]; then
    echo "Setting nameserver 8.8.8.8/8.8.4.4 for /etc/resolv.conf"
#   cp /etc/resolv.conf /etc/resolv.conf.bak
    echo nameserver 8.8.8.8 > /etc/resolv.conf
    echo nameserver 8.8.4.4 >> /etc/resolv.conf
fi




if [ "${HOST_IF_NAME}" == "" ]; then
    export HOST_IF_NAME=$(ip -4 route ls | grep default | cut -d\  -f5)
fi
if [ "${HOST_IF_GATEWAY}" == "" ]; then
    export HOST_IF_GATEWAY=$(ip route show 0.0.0.0/0 dev "${HOST_IF_NAME}" | cut -d\  -f3)
fi

#permetto il traffico dalla vpn all'host
if [ "${VPN_ROUTE_ALLOW_VPN_TO_HOST}" != "false" ]; then
    iptables -t nat -A POSTROUTING -o "${HOST_IF_NAME}" -j MASQUERADE
fi

if [ "${HOST_ROUTES}" == "" ]; then
    if [ "${PORT_FORWARD_HOST}" != "" ]; then
        HOST_ROUTES="${PORT_FORWARD_HOST}/32"
    fi
fi

#dopo la connessione alla vpn non c'è la route per il 192.168.99.0, quindi aggiungo le routes al gateway
if [ -n "${HOST_ROUTES}" ]; then
    ROUTES=$(echo $HOST_ROUTES | tr "," "\n")
    for U in $ROUTES; do
        _ROUTE=$(echo "${U}" | xargs)
        echo ">> Add route $_ROUTE su ${HOST_IF_GATEWAY}"
        route add -net "${_ROUTE}" gw "${HOST_IF_GATEWAY}"
    done
fi

if [ "${PORT_FORWARD_HOST}" == "" ]; then
    PORT_FORWARD_HOST="${HOST_IF_GATEWAY}"
fi

if [ -n "${PORT_FORWARD_PORTS}" ]; then
    PORTS=$(echo $PORT_FORWARD_PORTS | tr "," "\n")
    for U in $PORTS; do
        HOST="${PORT_FORWARD_HOST}"
        PORT=$(echo "${U}" | xargs)
        LOCAL_PORT="${PORT}"
        oIFS="$IFS"; IFS=':'; arrStr=($PORT); IFS="$oIFS"; unset oIFS;
        if  [ "${#arrStr[@]}" == "2" ]; then
            HOST="${arrStr[0]}"
            PORT="${arrStr[1]}"
            LOCAL_PORT="${arrStr[1]}"
        fi
        if  [ "${#arrStr[@]}" == "3" ]; then
            LOCAL_PORT="${arrStr[0]}"
            HOST="${arrStr[1]}"
            PORT="${arrStr[2]}"
        fi
        
        echo ">> Add port forward from ${LOCAL_PORT} to ${HOST}:${PORT}"
        iptables -A PREROUTING -t nat -p tcp --dport "${LOCAL_PORT}" -j DNAT --to "${HOST}:${PORT}"
        iptables -A PREROUTING -t nat -p udp --dport "${LOCAL_PORT}" -j DNAT --to "${HOST}:${PORT}"
        iptables -A FORWARD -p tcp -d "${HOST}" --dport "${PORT}" -j ACCEPT
        iptables -A FORWARD -p udp -d "${HOST}" --dport "${PORT}" -j ACCEPT
    done
fi