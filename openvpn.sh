#!/usr/bin/env bash

echo "Creating tun device"
mkdir -p /dev/net
[[ -c /dev/net/tun ]] || mknod /dev/net/tun c 10 200

query_prefix='https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations&filters=%7B%22country_id%22:'
query_suffix=',%22servers_groups%22:%5B11%5D,%22servers_technologies%22:%5B3%5D%7D'
country_code=${NVPN_COUNTRY_CODE:-228}

echo "Determining best server for ${country_code}"
vpn_host=$(curl -s "${query_prefix}${country_code}${query_suffix}" | jq -r '.[0]["hostname"]')

echo "Server selected: ${vpn_host}, retreving config"
curl -s "https://downloads.nordcdn.com/configs/files/ovpn_legacy/servers/${vpn_host}.udp1194.ovpn" > /etc/openvpn/config.opvn

# Add Alpine scripts to configure resolve.conf
sed -i \
  -e "/auth-user-pass/a script-security 2" \
  -e "/auth-user-pass/a up /etc/openvpn/up.sh" \
  -e "/auth-user-pass/a down /etc/openvpn/down.sh" \
  /etc/openvpn/config.opvn

if  [ -z ${OVPN_USERNAME} ] || [ -z ${OVPN_PASSWORD} ] ; then
    echo "OpenVPN credentials not set. Exiting"
    exit 1
else
    echo "Adding OpenVPN credentials from environment."
    echo "${OVPN_USERNAME}" > /etc/openvpn/creds.txt
    echo "${OVPN_PASSWORD}" >> /etc/openvpn/creds.txt
    chmod 600 /etc/openvpn/creds.txt

    sed -i "s:auth-user-pass:auth-user-pass /etc/openvpn/creds.txt:" /etc/openvpn/config.opvn
fi

echo "Running OpenVPN"
exec openvpn /etc/openvpn/config.opvn