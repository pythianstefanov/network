#!/bin/bash

echo username, description, role, shell
USERS=$(tmsh list auth user | grep 'auth\|role' | cut -d" " -f3)
for USER in $USERS;
do
 DESCRIPTION=$(tmsh list auth user $USER | grep description | cut -d" " -f6-8)
 ROLE=$(tmsh list auth user $USER | grep role | cut -d" " -f14)
 SHELL=$(tmsh list auth user $USER | grep shell | cut -d" " -f6)
 if [ $ROLE = "admin" ]
  then  echo -n $USER,$DESCRIPTION,$ROLE,$SHELL
  echo
 fi
done

