#!/bin/bash

NAME_PROFILE=$1
IP_PROFILE=$(awk "{if(\$1== \"Address\"){print \$3}}" ./clients/$NAME_PROFILE.conf | cut -d/ -f1)
if [[ -n $IP_PROFILE ]]; then 
  echo удаляю из wg0 peer $IP_PROFILE
else
  echo что то пошло не так 
  exit 1
fi

number_array=( $(cat -n wg0.conf | grep -B2 $IP_PROFILE | awk '{print $1}') )
max=${number_array[2]}
min=${number_array[0]}
for (( i = $max+1; i > $min-1; i-- )) ; do
sed -i "${i}d" wg0.conf
STATUS=$?
done
if [[ $STATUS == 0 ]]; then
rm ./clients/$NAME_PROFILE.conf
 
else 
  echo нечего удалять
fi
wg syncconf wg0 <(wg-quick strip wg0)
