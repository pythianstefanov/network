#!/bin/bash

echo PROFILE, CERTIFICATE, CIPHER, CHAIN

PROFILES=$(tmsh list / ltm profile client-ssl |grep $1 | grep "ltm profile" | cut -d" " -f4)
for PROFILE in $PROFILES; do
	echo -n $PROFILE,
	
	CERT=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " cert " | cut -d" " -f6)
	echo -n $CERT,
	
	CIPHER=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " ciphers " | cut -d" " -f6)
	echo -n $CIPHER,
	
	CHAIN=$(tmsh list / ltm profile client-ssl $PROFILE  | grep " chain " | cut -d" " -f6)
	echo -n $CHAIN
		
	echo
done

