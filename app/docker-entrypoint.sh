#!/bin/bash

#set -e
set -a # Enable allexport using single letter syntax

[ "$DEBUG" == 'true' ] && set -x

mkdir -p /etc/entrypoint.d /tmp/currentvpn /var/run/deamons
cd /app
find /app -type f ! -executable -iname "*.sh" -exec chmod +x {} \;
find /etc/openvpn -type f ! -executable -iname "*.sh" -exec chmod +x {} \;
find /etc/entrypoint.d -type f ! -executable -iname "*.sh" -exec chmod +x {} \;
rm /var/run/deamons/* 2>/dev/null

/app/routes_init.sh 1> >(sed "s/^/[ROUTES] /") 2> >(sed "s/^/[ROUTES] /" >&2)
/app/copy-default-configs.sh
/app/sshd_init.sh 1> >(sed "s/^/[SSHD] /") 2> >(sed "s/^/[SSHD] /" >&2)

# Run scripts in /etc/entrypoint.d

find /etc/entrypoint.d/ -name "*.sh" -print0 | while read -d $'\0' f
do
    if [[ -x ${f} ]]; then
        echo ">> Running: ${f}"
        filename=$(basename -- "$f")
        filename="${filename%.*}"
        CMD_PFX="[$filename]"
        ${f} # > >(sed "s/^/$prefix: /") 2> >(sed "s/^/$prefix (err): /" >&2)
        #${f} 1> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g") 2> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g" >&2)
    fi
done

if [ -d "/etc/openvpn/entrypoint.d" ]; then	  
	find /etc/openvpn/entrypoint.d -type f ! -executable -iname "*.sh" -exec chmod +x {} \;
	find /etc/openvpn/entrypoint.d/ -name "*.sh" -print0 | while read -d $'\0' f
	do
		if [[ -x ${f} ]]; then
			echo ">> Running: ${f}"
			filename=$(basename -- "$f")
			filename="${filename%.*}"
			CMD_PFX="[$filename]"
			${f} # > >(sed "s/^/$prefix: /") 2> >(sed "s/^/$prefix (err): /" >&2)
			#${f} 1> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g") 2> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g" >&2)
		fi
	done
fi
if [ -d "/etc/ssh/entrypoint.d" ]; then	  
	find /etc/ssh/entrypoint.d -type f ! -executable -iname "*.sh" -exec chmod +x {} \;
	find /etc/ssh/entrypoint.d/ -name "*.sh" -print0 | while read -d $'\0' f
	do
		if [[ -x ${f} ]]; then
			echo ">> Running: ${f}"
			filename=$(basename -- "$f")
			filename="${filename%.*}"
			CMD_PFX="[$filename]"
			${f} # > >(sed "s/^/$prefix: /") 2> >(sed "s/^/$prefix (err): /" >&2)
			#${f} 1> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g") 2> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g" >&2)
		fi
	done
fi

#echo "Running on $(uname -m) v1"

/app/openvpn_start.sh