#!/bin/bash

echo VIP NAME, DESTINATION, POOL
VIRTUALS=$(tmsh list / ltm virtual one-line |grep "$1 " | grep "ltm virtual" | cut -d" " -f3)
for VS in $VIRTUALS; do
	echo -n $VS,
	
	DEST=$(tmsh list ltm virtual $VS | grep destination | cut -d" " -f6)
	echo -n $DEST,
	
	POOL=$(tmsh list ltm virtual $VS | grep " pool " | cut -d" " -f6)
	if [ -n "$POOL" ]; then
		echo -n $POOL
	else
		echo -n N/A
	fi
	
	echo
done

