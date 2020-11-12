#!/bin/bash

for SSL_PROFILE in $(tmsh list ltm profile client-ssl one-line |awk -F" " '{ print $4 }') ; do
	VIP=$(tmsh list ltm virtual one-line |grep $SSL_PROFILE |awk -F" " '{ print $3 }')
	if [ -z "$VIP" ]; then
		echo $SSL_PROFILE
	fi
done
