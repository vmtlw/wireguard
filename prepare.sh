if [[ ! -e /usr/bin/wg ]]; then 
  echo Please, install Wireguard tools
fi

if ! [[ -d ./clients ]]; then 
  mkdir ./clients
fi

PRIVKEY=$(wg genkey)
REAL_IP=$(curl -s 2ip.ru)

sed -i -r "s|^PrivateKey =.*|PrivateKey = "${PRIVKEY}"|" ./wg0.conf 2> /dev/null
if [[ $? == 0 ]]; then
  echo Secret key successfully registered 
fi

sed -i "${num_line}s|^PublicKey =.*|PublicKey = "$(echo ${PRIVKEY} | wg pubkey)"|" ./create_profile.sh 2>/dev/null
if [[ $? == 0 ]]; then
  echo Public key successfully registered 
fi

sed -i "s/EXTERNAL_IP/$REAL_IP/" ./create_profile.sh

