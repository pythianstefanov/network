#!/bin/sh

IRULES=$(tmsh list ltm rule | grep $1 | grep "ltm rule" | cut -d" " -f3)
for IRULE in $IRULES; do
	echo $IRULE
	echo
	VIPS=$(tmsh list ltm virtual one-line | grep $IRULE | awk '{print $3}')
	for VIP in $VIPS; do
		echo $VIP
	done
	echo
done

