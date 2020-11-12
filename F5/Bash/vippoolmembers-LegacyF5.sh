#!/bin/bash
# This script prints VIP name, VIP IP, associated Pool, associated Pool members as (nodename:port and {IP address})
echo vs name, vs ip, pool, pool members
VIRTUALS=$(tmsh list ltm virtual | grep "ltm virtual" | cut -d" " -f3)
for VS in $VIRTUALS;
do
 echo -n $VS,
 DEST=$(tmsh list ltm virtual $VS | grep destination | cut -d" " -f6)
 echo -n $DEST,
 POOL=$(tmsh list ltm virtual $VS | grep " pool " | cut -d" " -f6)
   if [ -n "$POOL" ];
 then
   echo -n $POOL,
 else
   echo -n N/A,
 fi
   if [ -n "$POOL" ];
 then
   MBRS=$(tmsh list ltm pool "$POOL" one-line | grep -o -P '(?<=members {).*(?=\} monitor)')
   MEMBER_INFO=$(echo $MBRS | sed 's/address //'g | sed 's/session //'g | sed 's/monitor-enabled //'g | sed 's/state //'g | sed 's/up //'g | sed 's/down //'g)
   MEMBER_INFO=$(echo $MEMBER_INFO | sed 's/webcache/8080/'g | sed 's/smtp/25/'g)
     if [ -n "$MEMBER_INFO" ]
   then 
     echo -n $MEMBER_INFO
   else
     echo -n N/A
   fi
 else
   echo -n N/A
 fi
 echo
done
