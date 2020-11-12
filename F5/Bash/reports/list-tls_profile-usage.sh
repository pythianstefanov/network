#!/bin/bash

echo VIP, CERTIFICATE, PROFILE, CIPHER
CERTIFICATES=$(tmsh list sys one-line | grep "sys file ssl-cert" | grep "O=TravelClick" | cut -d" " -f4)
for CERTIFICATE in $CERTIFICATES; do
	PROFILES=$(tmsh list ltm profile one-line | grep $CERTIFICATE | awk '{for(i=1;i<=NF;i++)if($i~/client-ssl/)print $(i+1)}')
	if [ -n "$PROFILES" ]; then
		for PROFILE in $PROFILES; do
			CIPHERS=$(tmsh list ltm profile one-line | grep "$PROFILE {" | awk '{for(i=1;i<=NF;i++)if($i~/ciphers/)print $(i+1)}')
			VIPS=$(tmsh list ltm virtual one-line | grep "$PROFILE {" | cut -d" " -f3)
			if [ -n "$VIPS" ]; then
				for VIP in $VIPS; do
					echo -n $VIP,
					echo -n $CERTIFICATE,
					echo -n $PROFILE,
					echo $CIPHERS,
				done
			else
				echo -n NONE,
				echo -n $CERTIFICATE,
				echo -n $PROFILE,
				echo $CIPHERS,
			fi
		done
	else
		echo -n NONE,
		echo -n $CERTIFICATE,
		echo -n NONE,
		echo NONE,
	fi
done

