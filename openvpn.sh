#!/usr/bin/env bash

echo "Creating tun device"
mkdir -p /dev/net
[[ -c /dev/net/tun ]] || mknod /dev/net/tun c 10 200

query_prefix='https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations&filters=%7B%22country_id%22:'
query_suffix=',%22servers_groups%22:%5B11%5D,%22servers_technologies%22:%5B3%5D%7D'
country_code=${NVPN_COUNTRY_CODE:-228}

if [ -z ${NVPN_HOST} ] ; then
    echo "Determining best server for ${country_code}"
    NVPN_HOST=$(curl -s "${query_prefix}${country_code}${query_suffix}" | jq -r '.[0]["hostname"]')
fi

case ${NVPN_PORT_TYPE} in
    TCP) NVPN_PORT_NAME=tcp443 ;;
    *) NVPN_PORT_NAME=udp1194 ;;
esac

echo "Server selected: ${NVPN_HOST} using ${NVPN_PORT_NAME}, retrieving config"
curl -s "https://downloads.nordcdn.com/configs/files/ovpn_legacy/servers/${NVPN_HOST}.${NVPN_PORT_NAME}.ovpn" > /etc/openvpn/config.opvn

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

if [ -n ${LOCAL_NETWORKS} ] ; then
    gateway="$(ip route show 0.0.0.0/0 dev eth0 | cut -d ' ' -f 3)"
    for network in ${LOCAL_NETWORKS//;/ }; do
        echo "Adding route for ${network}"
        ip route add to ${network} via ${gateway} dev eth0
    done
fi

echo "Running OpenVPN"
exec openvpn /etc/openvpn/config.opvn
