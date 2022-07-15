#!/bin/bash

cd /etc/openvpn

found=$( find . -name "*.ovpn" )
if [[ -n $found ]]; then
	if  [ "$START_SLEEP" != "" ]; then
        sleep $START_SLEEP
    fi
    echo "Starting OpenVpn..."
else
    echo 'Nessun file ovpn trovato!'
    exit 1
fi

files_different(){
    local C1=$(cat "$1" 2>/dev/null)
    local C2=$(cat "$2" 2>/dev/null)
	if  [ "$C1" == "$C2" ]; then
		return $(false)
    else
		return $(true)
    fi
}

stop() {
    export EXITING="true"
    echo "Received SIGINT or SIGTERM. Shutting down OpenVPN"

    /app/services/services.sh stop
    /app/services/openvpn_autokill.sh stop
		rm /tmp/currentvpn/* 2>/dev/null

    # Get PID
    local pid=$(cat /var/run/deamons/openvpn.pid)
    # Set TERM
    kill -SIGTERM "${pid}" 2>/dev/null
    # Wait for exit
    wait "${pid}" 2>/dev/null

    # All done.
    echo "Done."
    exit 0
}
#trap stop SIGINT SIGTERM

arrConfs=()
arrIndex=-1

while true; 
do 
	((arrIndex=arrIndex+1))
	
	if  [ "$arrIndex" -ge "${#arrConfs[@]}" ]; then
		arrConfs=()
		arrIndex=0
	fi
	    
	if  [ "${#arrConfs[@]}" == "0" ]; then
		unset arrConfs
		for f in *.ovpn; do arrConfs+=("$f"); done
	fi
	
	#echo "AVVIA!"
    #echo "ciclo index incrementato $arrIndex"
	file="${arrConfs[$arrIndex]}"	
	
	if [ -f "${file}" ]; then
        file=$(realpath "${file}")
        filedir=$(dirname "${file}")
		echo "Starting VPN config [$file] in dir [$filedir]"
		
        killall /usr/sbin/openvpn 2>/dev/null		
        /app/services/services.sh stop
        /app/services/openvpn_autokill.sh stop
		
		rm /tmp/currentvpn/* 2>/dev/null
		rm /tmp/current.config 2>/dev/null

        if [ -f "common_begin.conf" ]; then
            cat "common_begin.conf" >> /tmp/current.config
        fi

        if  [ "$OVPN_SHARED_SETTINGS" != "" ]; then                
            echo "$OVPN_SHARED_SETTINGS" >> /tmp/current.config
            #for i in $(echo "$OVPN_SHARED_SETTINGS" | tr ";" "\n")
            #do
            #  echo "$i" >> /tmp/current.config
            #done
        fi
		
		cat "$file" >> /tmp/current.config

        if [ -f "common_end.conf" ]; then
            cat "common_end.conf" >> /tmp/current.config
        fi

        #cp -f "$file" /tmp/file.tmp

		#cp /tmp/current.config /tmp/currentvpn/config.ovpn
        filefixed=${file}
        if files_different "$filefixed" "/tmp/current.config" ; then
            filefixed="$file.tmp"
            if files_different "$filefixed" "/tmp/current.config" ; then
                cp -f /tmp/current.config "$filefixed" 2>/dev/null
            fi
            if files_different "$filefixed" "/tmp/current.config" ; then
                filefixed=/tmp/currentvpn/current.ovpn
                cp -f /tmp/current.config "$filefixed"
            fi
        fi
        
        export OVPN_FILE="${file}"
        export OVPN_FILE_DIR="${filedir}"
        export OVPN_FILE_FIXED="${filefixed}"
        export OVPN_CONNECTED="false"
        export OVPN_LOG_PREFIX="[OVPN]"


        /app/services/openvpn_autokill.sh start
        CMD_PFX="$OVPN_LOG_PREFIX"
        /usr/sbin/openvpn  \
            --script-security 2 --up /app/on_vpn_up.sh --down /app/on_vpn_down.sh \
            --cd "${filedir}" --config "${filefixed}" --connect-retry-max 5 & # \
            #1> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g") 2> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g" >&2) &
        pid="$!"
        mkdir -p /var/run/deamons && echo "${pid}" > /var/run/deamons/openvpn.pid
        wait "${pid}" 2>/dev/null

        /app/services/services.sh stop
        /app/services/openvpn_autokill.sh stop
		rm /tmp/currentvpn/* 2>/dev/null

		#cattura questo evento ed esce anche se non deve!
        #if  [ "$EXITING" == "$true" ]; then
        #    exit 0            
        #fi

	fi
done
