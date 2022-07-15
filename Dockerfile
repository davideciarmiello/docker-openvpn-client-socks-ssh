#mix di 
# https://github.com/kizzx2/docker-openvpn-client-socks
# https://github.com/panubo/docker-sshd

# OpenVPN client + SOCKS proxy
# Usage:
# Create configuration (.ovpn), mount it in a volume
# docker run --volume=something.ovpn:/ovpn.conf:ro --device=/dev/net/tun --cap-add=NET_ADMIN
# Connect to (container):1080
# Note that the config must have embedded certs
# See `start` in same repo for more ideas

FROM alpine

#COPY sockd.sh /usr/local/bin/
#RUN apk update

RUN apk add --update-cache dante-server openvpn bash openresolv openrc iptables && \
    cp -a /etc/openvpn /etc/openvpn.cache 
    ##&& \
    #&& rm -rf /var/cache/apk/* \
    #&& chmod a+x /usr/local/bin/sockd.sh \
    #&& true

COPY /app/sockd.conf /etc/

RUN apk add bash git openssh rsync augeas shadow rssh && \
    deluser $(getent passwd 33 | cut -d: -f1) && \
    delgroup $(getent group 33 | cut -d: -f1) 2>/dev/null || true && \
    mkdir -p ~root/.ssh /etc/authorized_keys && chmod 700 ~root/.ssh/ && \
    augtool 'set /files/etc/ssh/sshd_config/AuthorizedKeysFile ".ssh/authorized_keys /etc/authorized_keys/%u /etc/ssh/keys/authorized_keys/%u"' && \
    echo -e "Port 22\n" >> /etc/ssh/sshd_config && \
    cp -a /etc/ssh /etc/ssh.cache && \
    rm -rf /var/cache/apk/*

#echo 'set /files/etc/ssh/sshd_config/AuthorizedKeysFile ".ssh/authorized_keys /etc/authorized_keys/%u /etc/ssh/keys/authorized_keys/%u"' | augtool -s 1> /dev/null
#echo 'set /files/etc/ssh/sshd_config/Port 22' | augtool -s 1> /dev/null    

EXPOSE 22
EXPOSE 1080

COPY app /app
RUN chmod a+x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]
