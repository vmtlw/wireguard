#магия, выпоняется команда через раз, возможно мешают '+' в сгенерированном ключе
for i in {1..1000}; do 
  sed -i -r "s/^PrivateKey =.*/PrivateKey = "$(wg genkey)"/" ./wg0.conf 2> /dev/null
  if [[ $? == 0 ]]; then
  echo succsess
    break
  fi
done
