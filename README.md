
# [OpenVPN-client-socks-ssh](https://github.com/davideciarmiello/docker-openvpn-client-socks-ssh)
This is a docker image of an OpenVPN client based on Alpine, tied to a different services.  It is
useful to isolate network changes (so the host is not affected by the modified
routing).

This supports directory style (where the certificates are not bundled together in one `.ovpn` file) and those that contains `update-resolv-conf`


## Features:
- **OpenVpn Client with Multiple OVPN** config files support: It allows you to have multiple configuration files, and openvpn connects to the first one. When the connection fails, try again on the next one.
- **OpenVpnAutoKill**: Pooling every 60 (configurable) seconds, to ping a VPN Gateway. If ping failed, close a connection.
- **Routes and forwarding**: Allow to create a port forwarding rules, allowing the other clients of the vpn, to connect to the ports of the docker host.
- **SOCKD SOCKS proxy server**  (based on  [Openvpn-client-SOCKS](https://github.com/kizzx2/docker-openvpn-client-socks)  ): Started when VPN up, and stopped when VPN is down.
- **SSHD Server** (based on  [Docker-SSHD](https://github.com/panubo/docker-sshd)  ) with **rsync**: Started when VPN up, and stopped when VPN is down. Check link for all parameters.


## Usage
Here are some example snippets to help you get started creating a container.

### docker-compose (recommended,  [click here for more info](https://docs.linuxserver.io/general/docker-compose))

```yaml
---
version: "2.1"
services:
  openvpn-client-socks-ssh:
    image: davideciarmi/docker-openvpn-client-socks-ssh
    cap_add:
      - NET_ADMIN
    privileged: true
    environment:
      #- DEBUG=true	
      #SETTINGS ROUTING - FORWARDING:
      - HOST_ROUTES=192.168.99.0/24  #Create a route to 192.168.99.0/24, because i have a ip 172.17.0.2, and after a VPN, i can't redirect ports to ip 192.168.99.1.
      #redirect ports below to this host, VPNIP:3389 -> 192.168.99.1:3389
      - PORT_FORWARD_HOST=192.168.99.1
      - PORT_FORWARD_PORTS=5900,3389
      #SETTINGS SSHD
      #allow to edit runtime the file /etc/ssh/sshd_config (not ReadOnly!)
      - SSH_SETTINGS=StrictModes no,LogLevel INFO
      # Other all default configs in https://github.com/panubo/docker-sshd 
      - MOTD=Welcome in VPN SSH Server
      - SSH_ENABLE_ROOT=true      
    volumes:
      # entrypoint: Scripts to run on startup, each .sh file in this directory is executed.
      - ${DIR_CONFIGS}/entrypoint/:/etc/entrypoint.d/
      #OpenVpn with ovpn files
      - ${DIR_CONFIGS}/openvpn/:/etc/openvpn/:ro
      #SSHD
      - ${DIR_CONFIGS}/ssh/sshd_config:/etc/ssh/sshd_config:ro
      - ${DIR_CONFIGS}/ssh/keys:/etc/ssh/keys
    ports:
      - 22:22 #port for SSH
      - 1080:1080 #port for SOCKS5
    restart: unless-stopped
```





Then connect to SOCKS proxy through through `localhost:1080` / `local.docker:1080`. For example:

```bash
curl --proxy socks5h://local.docker:1080 ipinfo.io
```

## Solutions to Common Problems

### I'm getting `RTNETLINK answers: Permission denied`

Try adding `--sysctl net.ipv6.conf.all.disable_ipv6=0` to your docker command

### DNS doesn't work

You can put a `update-resolv-conf` as your `up` script. One simple way is to put [this file](https://gist.github.com/Ikke/3829134) as `up.sh` inside your OpenVPN configuration directory.

## HTTP Proxy

You can easily convert this to an HTTP proxy using [http-proxy-to-socks](https://github.com/oyyd/http-proxy-to-socks), e.g.

```bash
hpts -s 127.0.0.1:1080 -p 8080
```
