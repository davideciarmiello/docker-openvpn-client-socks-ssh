#!/bin/bash

case "$1" in 
start)

   pid=`ps -eaf | grep "/app/openvpn_autokill.sh" | grep -v grep | awk '{print $1}'`
   if [[ "" ==  "$pid" ]]; then
      CMD_PFX="[VPN_AUTOKILL]"
      echo $CMD_PFX Avvio openvpn_autokill deamon
      #/app/openvpn_autokill.sh 1> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g") 2> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g" >&2) &
      /app/openvpn_autokill.sh & # > >(sed "s/^/$CMD_PFX /") 2> >(sed "s/^/$CMD_PFX /" >&2)
      pid="$!"
      mkdir -p /var/run/deamons && echo "${pid}" > /var/run/deamons/openvpn_autokill.pid
   fi

   ;;

stop)

   pid=$(cat /var/run/deamons/openvpn_autokill.pid 2>/dev/null)
   if [[ "" !=  "$pid" ]]; then
      echo Stop openvpn_autokill deamon
      kill "${pid}" 2>/dev/null
      rm /var/run/deamons/openvpn_autokill.pid 2>/dev/null
   fi

   ;;
restart)
   $0 stop
   $0 start
   ;;
status)
   if [ -e /var/run/deamons/openvpn_autokill.pid ]; then
      echo Running, pid=`cat /var/run/deamons/openvpn_autokill.pid`
   else
      echo Not running
      exit 1
   fi
   ;;
*)
   echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0 