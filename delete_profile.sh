#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Проверка аргументов
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <profile_name>"
  exit 1
fi

NAME_PROFILE=$1
CLIENT_CONFIG="./clients/$NAME_PROFILE.conf"
WG_CONFIG="./wg0.conf"

# Проверка существования конфигурационного файла клиента
if [[ ! -f $CLIENT_CONFIG ]]; then
  echo "Error: Client configuration file ($CLIENT_CONFIG) not found."
  exit 1
fi

# Получение IP клиента
IP_PROFILE=$(awk '/^Address/ {print $3}' "$CLIENT_CONFIG" | cut -d/ -f1)
if [[ -z $IP_PROFILE ]]; then
  echo "Error: Failed to retrieve IP address from $CLIENT_CONFIG."
  exit 1
fi

echo "Удаляю peer с IP: $IP_PROFILE из $WG_CONFIG"

# Поиск строк для удаления
LINE_NUMBERS=($(grep -B2 -n "AllowedIPs = $IP_PROFILE" "$WG_CONFIG" | cut -d: -f1))
if [[ ${#LINE_NUMBERS[@]} -eq 0 ]]; then
  echo "Error: Peer с IP $IP_PROFILE не найден в $WG_CONFIG."
  exit 1
fi

# Удаление строк в обратном порядке
for (( i=${#LINE_NUMBERS[@]}-1; i>=0; i-- )); do
  sed -i "${LINE_NUMBERS[$i]}d" "$WG_CONFIG"
done

# Удаление конфигурационного файла клиента
rm -f "$CLIENT_CONFIG"
echo "Конфигурация клиента $NAME_PROFILE удалена."

# Перезагрузка конфигурации WireGuard
wg syncconf wg0 <(wg-quick strip wg0)
echo "WireGuard конфигурация обновлена."
