#!/bin/bash

# Copy default config from cache, if required
if [ ! "$(ls -A /etc/openvpn)" ]; then
    cp -a /etc/openvpn.cache/* /etc/openvpn/
fi
if [ ! "$(ls -A /etc/sockd.conf)" ]; then
    cp -a /app/sockd.conf /etc/sockd.conf
fi
if [ ! "$(ls -A /etc/ssh)" ]; then
    cp -a /etc/ssh.cache/* /etc/ssh/
fi
