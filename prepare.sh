#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Проверка наличия необходимых пакетов
REQUIRED_PACKAGES=("qrencode" "wg" "resolvconf" "curl")

echo "Проверяем наличие необходимых пакетов:"
for package in "${REQUIRED_PACKAGES[@]}"; do
  if ! command -v "$package" &> /dev/null; then
    echo "Error: Команда '$package' не найдена. Установите её перед продолжением."
    exit 1
  fi
done

# Создание директории для клиентов, если не существует
CLIENTS_DIR="./clients"
[[ -d $CLIENTS_DIR ]] || mkdir -p "$CLIENTS_DIR"
echo "Директория для клиентов ($CLIENTS_DIR) подготовлена."

# Генерация приватного ключа сервера
PRIVKEY_SERVER=$(wg genkey)
REAL_IP=$(curl -s ifconfig.me)  # Используем более стандартный сервис для получения IP
if [[ -z $REAL_IP ]]; then
  echo "Error: Не удалось получить реальный IP-адрес. Проверьте подключение к интернету."
  exit 1
fi
USED_IFACE=$(ip r g 8.8.8.8 | awk 'NR==1 {print $5}')
if [[ -z $USED_IFACE ]]; then
  echo "Error: Не удалось определить активный сетевой интерфейс."
  exit 1
fi

# Обновление конфигурации WireGuard
WG_CONFIG="./wg0.conf"
if [[ ! -f $WG_CONFIG ]]; then
  echo "Error: Конфигурационный файл WireGuard ($WG_CONFIG) не найден."
  exit 1
fi

sed -i -r "s|^PrivateKey =.*|PrivateKey = $PRIVKEY_SERVER|" "$WG_CONFIG" \
  && echo "Приватный ключ успешно зарегистрирован в $WG_CONFIG."

sed -i "s/USED_IFACE/${USED_IFACE}/g" "$WG_CONFIG" \
  && echo "Интерфейс ($USED_IFACE) успешно обновлён в $WG_CONFIG."

# Обновление скрипта создания профиля
CREATE_PROFILE_SCRIPT="./create_profile.sh"
if [[ ! -f $CREATE_PROFILE_SCRIPT ]]; then
  echo "Error: Скрипт создания профиля ($CREATE_PROFILE_SCRIPT) не найден."
  exit 1
fi

PUBLIC_KEY=$(echo "$PRIVKEY_SERVER" | wg pubkey)
num_line=$(grep -n -B2 "Endpoint" "$CREATE_PROFILE_SCRIPT" | head -n1 | cut -d- -f1 || true)
if [[ -n $num_line ]]; then
  sed -i "${num_line}s|^PublicKey =.*|PublicKey = $PUBLIC_KEY|" "$CREATE_PROFILE_SCRIPT" \
    && echo "Публичный ключ успешно зарегистрирован в $CREATE_PROFILE_SCRIPT."
else
  echo "Warning: Не удалось обновить публичный ключ в $CREATE_PROFILE_SCRIPT (строка не найдена)."
fi

sed -i "s/EXTERNAL_IP/$REAL_IP/" "$CREATE_PROFILE_SCRIPT" \
  && echo "Реальный IP ($REAL_IP) успешно обновлён в $CREATE_PROFILE_SCRIPT."

# Настройка системных параметров для маршрутизации
echo "Включаем форвардинг IP..."
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1
echo "Маршрутизация IP включена."

echo "Скрипт успешно выполнен."
