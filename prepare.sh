if [[ ! -e /usr/bin/wg ]]; then 
  echo Please, install rireguard tools
  exit 1
fi

if ! [[ -d ./clients ]]; then 
  mkdir ./clients
fi

if ! [[ -e /usr/sbin/resolvconf ]]; then
  echo Please, install resolvconf tools
  exit 1
fi

if [[ ! -e /usr/bin/qrencode ]]; then
  echo Please, install qrencode
  exit 1
fi

PRIVKEY_SERVER=$(wg genkey)
REAL_IP=$(curl -s 2ip.ru)
num_line=$(grep -n -B2 Endpoint create_profile.sh | head -n1 | cut -d- -f1)
USED_IFACE=$(ip r g 8.8.8.8 | awk -- 'NR==1{print $5}')

sed -i -r "s|^PrivateKey =.*|PrivateKey = "${PRIVKEY_SERVER}"|" ./wg0.conf 2> /dev/null
if [[ $? == 0 ]]; then
  echo Secret key successfully registered 
fi
sed -i "${num_line}s|^PublicKey =.*|PublicKey = "$(echo ${PRIVKEY_SERVER} | wg pubkey)"|" ./create_profile.sh 2>/dev/null
if [[ $? == 0 ]]; then
  echo Public key successfully registered 
fi

sed -i "s/EXTERNAL_IP/$REAL_IP/" ./create_profile.sh

sed -i "s/USED_IFACE/${USED_IFACE}/g" wg0.conf



sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1
