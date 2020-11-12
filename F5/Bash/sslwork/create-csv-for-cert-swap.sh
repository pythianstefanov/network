#!/bin/bash
F5=10.80.0.38
INPUT=vipslist.csv
PROFILES=profiles.csv
OLDIFS=$IFS
IFS=,
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
[ ! -f $PROFILES ] && { echo "$PROFILES file not found"; exit 99; }
while read vipname
do
output=$(tmsh list ltm virtual $vipname |grep "ltm virtual" | awk -F" " '{ print $3 }')
clientssl=$(tmsh show ltm virtual $vipname profiles |grep ClientSSL |awk -F" " '{ print $4 }')

      if [ -n "${clientssl}" ]; then
         OLDIFS2=$IFS2
         IFS2=,
         while read oldprofile newprofile
         do
         if [ "${clientssl}" == "$oldprofile" ]; then
                echo "$F5,$vipname,$clientssl,$newprofile";
         fi
      done < $PROFILES
      IFS2=$OLDIFS2
      fi

done < $INPUT
IFS=$OLDIFS

