# Simple OpenVPN Client Docker Image for Nord VPN

This docker image contains an OpenVPN client for use with Nord VPN credentials. It provides a simple way to set up a VPN tunnel for use by other containers, for example, to run a a Selenium client so that it can simulate requests from a remote locations.

It automatically selects a server using the recommendation from this page: https://nordvpn.com/servers/.

By default it uses a host in the US, but this can be altered by passing a different country code in the `NVPN_COUNTRY_CODE` environment variable.


## Standalone Usage

Replace the `OVPN_USERNAME` and `OVPN_PASSWORD` values in the commands below with your credentials supplied by Nord VPN.

Basic usage (US server):

```
docker run -it --cap-add=NET_ADMIN -e OVPN_USERNAME=... -e OVPN_PASSWORD=... noelsmith/nvpn-client
```

Basic usage (UK server):

```
docker run -it --cap-add=NET_ADMIN -e OVPN_USERNAME=... -e OVPN_PASSWORD=.... -e NVPN_COUNTRY_CODE=227 noelsmith/nvpn-client
```

You can verify it's working correctly you can exec into the container and use curl to check it's IP details:

```
$ docker run -d --cap-add=NET_ADMIN --name nvpnc -e OVPN_USERNAME=... -e OVPN_PASSWORD=... noelsmith/nvpn-client

$ docker exec -it nvpnc bash
bash-4.4# curl ipinfo.io
{
  "ip": "185.217.69.149",
  "city": "New York",
  "region": "New York",
  "country": "US",
  "loc": "40.7214,-74.0052",
  "postal": "10013",
  "phone": "212",
  "org": "AS9009 M247 Ltd"
}
```


## With Docker Compose

Usually you'd want to run this alongside one or more other containers that need to make requests over a VPN. To do this you can set up a `docker-compose.yml` file that provides the VPN as a network for use by other containers.

This example runs a Selenium Chrome browser debug mode (i.e. with a VNC desktop):

```
version: '3.4'
services:
  nvpn-client:
    image: noelsmith/nvpn-client
    cap_add:
      - NET_ADMIN
    restart: always
    environment:
      - OVPN_USERNAME=...
      - OVPN_PASSWORD=...
      - NVPN_COUNTRY_CODE=228
    ports:
      - "4444:4444"  # Selenium port
      - "5901:5900"  # VNC port

  selenium:
    image: selenium/standalone-chrome-debug
    network_mode: "service:nvpn-client"

```

Example output using VNC:

![Screenshot of Chrome browser using VPN via VNC](https://noel-smith.github.io/images/nvpn-client-vnc.png)

