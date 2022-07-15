#!/bin/bash

#CMD_PFX="[VPN_AUTOKILL]"
#exec > >(trap "" INT TERM; sed 's/^/$CMD_PFX /')
#exec 2> >(trap "" INT TERM; sed 's/^/$CMD_PFX /' >&2)

ping_ip(){
    CURR_IP=$(cat "/tmp/currentvpn/ip" 2>/dev/null)
    PINGRES=$(ping -I "$1" -q -c 1 -W 1 "$2" 2>&1 | sed 's/bad address/100% packet loss - Bad Address/g' | grep '100% packet loss' )
	LAST_MSG=$(cat "/tmp/currentvpn/lastmsg" 2>/dev/null)
	if  [ "$PINGRES" != "" ]; then
		MSG="Ping Error: IP $2 - Adapter $1 - CurrentIp: $CURR_IP: $PINGRES"
		if  [ "$MSG" != "$LAST_MSG" ]; then
			echo "$MSG"
			echo "$MSG" > /tmp/currentvpn/lastmsg
		fi
        return $(false)
    else
		if [ ! -f /tmp/currentvpn/externalip ]; then
			wget -qO- http://ipecho.net/plain 2>/dev/null | xargs echo > /tmp/currentvpn/externalip
		fi
		EXTERNAL_IP=$(cat "/tmp/currentvpn/externalip" 2>/dev/null)		
		MSG="Ping OK: IP $2 - Adapter $1 - CurrentIp: $CURR_IP - ExternalIp: $EXTERNAL_IP"
		if  [ "$MSG" != "$LAST_MSG" ]; then
			echo "$MSG"
			echo "$MSG" > /tmp/currentvpn/lastmsg
		fi
        return $(true)
    fi
}

while true
do
	if  [ "$OVPN_AUTOKILL_SLEEP" == "" ]; then
		OVPN_AUTOKILL_SLEEP="60"
	fi
	#echo "avvio sleep $OVPN_AUTOKILL_SLEEP"
	sleep $OVPN_AUTOKILL_SLEEP
	#echo "fine sleep"

ADAPTER=$(cat "/tmp/currentvpn/adapter" 2>/dev/null)
if [ "$ADAPTER" == "" ]; then
	echo "Adapter non definito... verifico tun0"
	ADAPTER=tun0
fi

VALID=0
if  [ "$PING_IP" != "" ]; then
	GATEWAY=$PING_IP
	if ping_ip "$ADAPTER" "$GATEWAY" ; then
		VALID=1
	fi
else
	if [ "$LAST_PING_IP_VALID" != "" ] && ping_ip "$ADAPTER" "$LAST_PING_IP_VALID" ; then
		GATEWAY=$LAST_PING_IP_VALID
		VALID=1
	fi	
	if [ "$VALID" -eq "0" ]; then
		IP_VIA=$(ip route show | grep "$ADAPTER" | grep via | awk '{print $3}' | head -n 1 )
	fi    
	if [ "$VALID" -eq "0" ] && [ "$IP_VIA" != "" ]; then	 
		iplist=$(ip route show | grep "$ADAPTER" | grep via | grep .0/24 | sed 's/.0\/24/.1/g' | awk '{print $1}')
		for ip in $iplist; 
		do
			if [ "$VALID" -eq "0" ] && ping_ip "$ADAPTER" "$ip" ; then
				GATEWAY=$ip
				VALID=1
				LAST_PING_IP_VALID=$GATEWAY
				#echo "SETTO VALID $VALID"
			fi
		done		
		#echo " VALID value $VALID"
		if [ "$VALID" -eq "0" ] && [ "$IP_VIA" != "" ] && ping_ip "$ADAPTER" "$IP_VIA" ; then
			GATEWAY=$IP_VIA
			VALID=1
			LAST_PING_IP_VALID=$GATEWAY
		fi  
	fi
	if [ "$VALID" -eq "0" ] && ping_ip "$ADAPTER" "8.8.8.8" ; then
		GATEWAY=8.8.8.8
		VALID=1
	fi    
fi

if  [ "$VALID" -eq "0" ]; then
	echo "ERRORE PING su IP $GATEWAY... chiudo VPN! $PINGRES"
	/app/pkill.sh "/usr/sbin/openvpn"
fi
	
done

