#!/bin/bash

case "$1" in 
start)

   pid=`ps -eaf | grep "/usr/sbin/sockd" | grep -v grep | awk '{print $1}'`
   if [[ "" ==  "$pid" ]]; then
      CMD_PFX="[SOCKD]"
      echo $CMD_PFX Avvio $CMD_PFX deamon
      /usr/sbin/sockd -D  1> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g") 2> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g" >&2) &
      pid="$!"
      mkdir -p /var/run/deamons && echo "${pid}" > /var/run/deamons/sockd.pid
   fi

   pid=`ps -eaf | grep "/usr/sbin/sshd" | grep -v grep | awk '{print $1}'`
   if [[ "" ==  "$pid" ]]; then
      CMD_PFX="[SSHD]"
      echo $CMD_PFX Avvio $CMD_PFX deamon
      /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config 1> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g") 2> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g" >&2) &
      pid="$!"
      mkdir -p /var/run/deamons && echo "${pid}" > /var/run/deamons/sshd.pid
   fi   

   ;;

stop)

   pid=$(cat /var/run/deamons/sockd.pid 2>/dev/null)
   if [[ "" !=  "$pid" ]]; then
      echo Stop sockd deamon
      kill -SIGTERM "${pid}" 2>/dev/null
      wait "${pid}" 2>/dev/null
      rm /var/run/deamons/sockd.pid 2>/dev/null
   fi
   
   pid=$(cat /var/run/deamons/sshd.pid 2>/dev/null)
   if [[ "" !=  "$pid" ]]; then
      echo Stop sshd deamon
      kill -SIGTERM "${pid}" 2>/dev/null
      wait "${pid}" 2>/dev/null
      rm /var/run/deamons/sshd.pid 2>/dev/null
   fi

   ;;
restart)
   $0 stop
   $0 start
   ;;
status)
   if [ -e /var/run/deamons/sockd.pid ]; then
      echo Running, pid=`cat /var/run/deamons/sockd.pid`
   else
      echo Not running
      exit 1
   fi
   ;;
*)
   echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0 