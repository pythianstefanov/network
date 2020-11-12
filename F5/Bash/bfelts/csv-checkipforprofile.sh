#!/bin/bash
INPUT=$1
OLDIFS=$IFS
IFS=,
[ ! $INPUT ] || [ ! -f $INPUT ] && { echo "$INPUT input file not found - please check how youre calling the script and try again."; exit 99; }
while read ip
do
  NARROWDOWN=$(tmsh list / ltm virtual one-line | grep "$ip:https" | cut -d" " -f3)
  if [ "${NARROWDOWN}" != "" ]; then
          VIRTUAL=$(tmsh list / ltm virtual $NARROWDOWN one-line | grep -o -P '(?<={ } ).*(?={ context clientside })')
          for PROFILE in $VIRTUAL;
          do
            echo -n $ip,$NARROWDOWN,$PROFILE
            echo
          done
  fi
done < $INPUT
IFS=$OLDIFS
