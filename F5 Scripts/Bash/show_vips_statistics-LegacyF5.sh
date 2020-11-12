#!/bin/bash
# This script prints VIP name, VIP IP, Total Connections

echo VS Name, VS IP address, Total Connections
VIRTUALS=$(tmsh list ltm virtual | grep "ltm virtual" | cut -d" " -f3)
for VS in $VIRTUALS; do
	echo -n $VS,
	DEST=$(tmsh list ltm virtual $VS | grep destination | cut -d" " -f6)
	echo -n $DEST,
	CONNS=$(tmsh show ltm virtual field-fmt raw $VS | tr -d '\n' | sed 's/.*clientside.tot-conns\(.*\)cs-max-conn-dur.*/\1/')
	echo -n $CONNS
	echo
done

