#!/bin/bash

SEARCH=$1

echo profile, cert, chain, cipher
PROFILES=$(tmsh list / ltm profile client-ssl one-line |grep $SEARCH | grep "ltm profile" | cut -d" " -f4)
for PROFILE in $PROFILES;
do
  echo -n $PROFILE,
  CERT=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " cert " | cut -d" " -f6)
  echo -n $CERT,
  CHAIN=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " chain " | cut -d" " -f6)
  echo -n $CHAIN,
  CIPHER=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " ciphers " | cut -d" " -f6)
  echo -n $CIPHER
  echo
done

