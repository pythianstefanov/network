#!/bin/bash
# This script prints VIP name, VIP IP, associated Pool, associated Pool members as (nodename:port and {IP address})

echo vs name, vs ip, pool, pool members
VIRTUALS=$(tmsh list ltm virtual | grep "ltm virtual" | cut -d" " -f3)
for VS in $VIRTUALS; do
	echo -n $VS,
	DEST=$(tmsh list ltm virtual $VS | grep destination | cut -d" " -f6)
	echo -n $DEST,
	POOL=$(tmsh list ltm virtual $VS | grep " pool " | cut -d" " -f6)
	if [ -n "$POOL" ]; then
		echo -n $POOL,
	else
		echo -n N/A,
	fi
	if [ -n "$POOL" ]; then
		#Removing pool information and descriptions
		MBRS=$(tmsh list ltm pool "$POOL" | tr -d '\n' | grep -o -P '(?<=members {).*(?=\}    monitor)' | sed 's/description ".*" //')
		# Removing member state generic values
		MEMBER_INFO=$(echo $MBRS | sed 's/ address //'g | sed 's/ session//'g | sed 's/ monitor-enabled//'g | sed 's/ state up //'g | sed 's/ state down //'g)
		# Removing member state specific values
		MEMBER_INFO=$(echo $MEMBER_INFO | sed 's/ monitor gateway_icmp//'g | sed 's/ user-disabled//'g | sed 's/ state user-down //'g)
		# Replacing known service name with service port number
		MEMBER_INFO=$(echo $MEMBER_INFO | sed 's/webcache/8080/'g | sed 's/smtp/25/'g)	
		# Legacy Prod F5 specific states being removed
		MEMBER_INFO=$(echo $MEMBER_INFO | sed 's/ disabled//'g | sed 's/_Reservations//'g | sed 's/ monitor http//'g | sed 's/ monitor tcp//'g | sed 's/ monitor monitor_http_IMS_for_CF//'g | sed 's/ { }//'g )
		if [ -n "$MEMBER_INFO" ]; then
			echo -n $MEMBER_INFO
		else
			echo -n N/A
		fi
	else
		echo -n N/A
	fi
	echo
done


