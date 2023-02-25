#!/bin/bash

NAME=$1
PRIVATEKEY=$(wg genkey)
ENDPOINT="EXTERNAL_IP"
PORT="51820"


  COUNT=($(grep -r AllowedIPs ./wg0.conf | awk -F . '{print $4}'))
  for FREE_IP in {2..254}; do
    if [[ ! "${COUNT[*]}" =~ "$FREE_IP" ]]; then
        break
    fi
  done

cat << EOF >> ./clients/$1.conf
[Interface] 
Address = 10.0.0.$FREE_IP/24
PrivateKey = $PRIVATEKEY
DNS = 8.8.8.8

[Peer]
PublicKey = t7ZNDAdUIrwt9tsJ7foGr8/7U1ZjGrAO93zU9DRekmU=
AllowedIPs = 0.0.0.0/0
Endpoint = $ENDPOINT:$PORT
PersistentKeepalive = 20
EOF

cat << EOF >> ./wg0.conf

[Peer]
PublicKey = $(echo $PRIVATEKEY | wg pubkey)
AllowedIPs = 10.0.0.$FREE_IP
EOF


#if [[ -e ./clients/$1.conf ]]; then
#  qrencode -t ansiutf8 < ./clients/$1.conf
#  wg syncconf wg0 <(wg-quick strip wg0)  
#fi
