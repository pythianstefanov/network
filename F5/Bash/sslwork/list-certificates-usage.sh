#!/bin/bash

echo VIP USAGE, PROFILE, CERTIFICATE
CERTIFICATES=$(tmsh list sys crypto one-line | grep ".crt" | cut -d" " -f4)
for CERTIFICATE in $CERTIFICATES; do
	PROFILES=$(tmsh list ltm profile one-line | grep $CERTIFICATE | awk '{for(i=1;i<=NF;i++)if($i~/client-ssl/)print $(i+1)}')
	if [ -n "$PROFILES" ]; then
		for PROFILE in $PROFILES; do
			VIP_USAGE=$(tmsh list ltm virtual one-line | grep $PROFILE)
			if [ -n "$VIP_USAGE" ]; then
				echo -n YES,
			else
				echo -n NO,
			fi
			echo -n $PROFILE,
			echo -n $CERTIFICATE,
			echo
		done
	else
		echo -n NO,
		echo -n NONE,
		echo -n $CERTIFICATE,
		echo
	fi
done

