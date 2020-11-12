#!/bin/bash

echo PROFILE, CIPHER, CERTIFICATE, CHAIN

PROFILES=$(tmsh list / ltm profile client-ssl one-line |grep $1 | grep "ltm profile" | cut -d" " -f4)
for PROFILE in $PROFILES; do
	echo -n $PROFILE,
	
	CIPHER=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " ciphers " | cut -d" " -f6)
	echo -n $CIPHER,
	
	CERT=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " cert " | cut -d" " -f6)
	echo -n $CERT,
		
	CHAIN=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " chain " | cut -d" " -f6)
	echo -n $CHAIN
		
	echo
done

