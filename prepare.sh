#!/bin/bash

set -eu --pipefail

for package in qrencode wg resolvconf curl
do
	which $package &>/dev/null ||  echo command $package not found
done

[[ -d ./clients ]] ||  mkdir -p ./clients

PRIVKEY_SERVER=$(wg genkey)
REAL_IP=$(curl -s 2ip.ru)
num_line=$(grep -n -B2 Endpoint create_profile.sh | head -n1 | cut -d- -f1)
USED_IFACE=$(ip r g 8.8.8.8 | awk -- 'NR==1{print $5}')

sed -i -r "s|^PrivateKey =.*|PrivateKey = "${PRIVKEY_SERVER}"|" ./wg0.conf 2> /dev/null

[[ ! $? == 0 ]] || echo Secret key successfully registered 

sed -i "${num_line}s|^PublicKey =.*|PublicKey = "$(echo ${PRIVKEY_SERVER} | wg pubkey)"|" ./create_profile.sh 2>/dev/null

[[ ! $? == 0 ]] || echo Public key successfully registered 

sed -i "s/EXTERNAL_IP/$REAL_IP/" ./create_profile.sh

sed -i "s/USED_IFACE/${USED_IFACE}/g" wg0.conf



sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1
