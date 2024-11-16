#!/bin/bash

set -euo pipefail  # Улучшает обработку ошибок
IFS=$'\n\t'

# Проверка аргумента
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <client_name>"
  exit 1
fi

NAME=$1
CONFIG_DIR="./clients"
WG_CONFIG="./wg0.conf"
PRIVKEY_CLIENT=$(wg genkey)
PUBKEY_CLIENT=$(echo "$PRIVKEY_CLIENT" | wg pubkey)
ENDPOINT="EXTERNAL_IP"  # Укажите IP-адрес вашего сервера
PORT="51820"

# Убедимся, что файлы существуют
if [[ ! -f $WG_CONFIG ]]; then
  echo "Error: WireGuard configuration file ($WG_CONFIG) not found!"
  exit 1
fi

# Получение публичного ключа сервера
PUBKEY_SERVER=$(awk '/^PrivateKey/ {print $3}' "$WG_CONFIG" | wg pubkey)

# Определение доступного IP-адреса
declare -A USED_IPS
while IFS= read -r ip; do
  USED_IPS["$ip"]=1
done < <(grep -oP '(?<=AllowedIPs = 10\.0\.0\.)\d+' "$WG_CONFIG")

FREE_IP=0
for ip in {2..254}; do
  if [[ -z ${USED_IPS[$ip]+x} ]]; then
    FREE_IP=$ip
    break
  fi
done

if [[ $FREE_IP -eq 0 ]]; then
  echo "Error: No available IP addresses left in the subnet."
  exit 1
fi

# Создаём директорию для конфигураций клиентов
mkdir -p "$CONFIG_DIR"

# Генерация конфигурации клиента
CLIENT_CONFIG="$CONFIG_DIR/$NAME.conf"
cat << EOF > "$CLIENT_CONFIG"
[Interface] 
Address = 10.0.0.$FREE_IP/24
PrivateKey = $PRIVKEY_CLIENT
DNS = 8.8.8.8

[Peer]
PublicKey = $PUBKEY_SERVER
AllowedIPs = 0.0.0.0/0
Endpoint = $ENDPOINT:$PORT
PersistentKeepalive = 20
EOF

# Добавление клиента в конфигурацию сервера
cat << EOF >> "$WG_CONFIG"

[Peer]
PublicKey = $PUBKEY_CLIENT
AllowedIPs = 10.0.0.$FREE_IP/32
EOF

# Перезагрузка конфигурации WireGuard
wg syncconf wg0 <(wg-quick strip wg0)

# Генерация QR-кода
if command -v qrencode &> /dev/null; then
  qrencode -t ansiutf8 < "$CLIENT_CONFIG"
  echo "QR code for $NAME generated successfully."
else
  echo "qrencode is not installed. Skipping QR code generation."
fi

echo "Client configuration saved to $CLIENT_CONFIG."
