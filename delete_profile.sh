#!/bin/bash

NAME_PROFILE=$1
IP_PROFILE=$(awk "{if(\$1== \"Address\"){print \$3}}" ./clients/$NAME_PROFILE.conf | cut -d/ -f1)
if [[ -n $IP_PROFILE ]]; then 
  echo удаляю из wg0 peer $IP_PROFILE
else
  echo что то пошло не так 
  exit 1
fi
# закидываем список подлежащих удалению строки в массив
number_array=( $(cat -n wg0.conf | grep -B2 $IP_PROFILE | awk '{print $1}') )
#извлекаем последний , он же и наибольший элемент в массиве
max=${number_array[2]}
#извлекаем первый , он же и наименьший элемент в массиве
min=${number_array[0]}
#полчаем список строк в уменьшающемся порядке от (( наибольший + 1)) до (( наименьший -1 ))
for (( i = $max+1; i > $min-1; i-- )) ; do
  #удаляляем полученные в списке строки
  sed -i "${i}d" wg0.conf
  #сохраняем статус последней итерации скрипта
  STATUS=$?
done
if [[ $STATUS == 0 ]]; then
  # при успешном выполнении посленей команды удаляем профиль 
  rm ./clients/$NAME_PROFILE.conf
 else 
  echo нечего удалять
fi
# Wireguard перечитывает обновленый конфиг wg0.conf
wg syncconf wg0 <(wg-quick strip wg0)
