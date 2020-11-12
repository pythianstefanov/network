#!/bin/bash

echo USER NAME, ROLE, PARTITION ACCESS, SHELL ACCESS

USERS=$(tmsh list auth user all | grep "auth user" | sed 's/auth user //' | sed 's/ {//')

for USER in $USERS; do
	echo -n $USER,
	
	ROLE=$(tmsh list auth user $USER | grep "role" | sed 's/role //')
	echo -n $ROLE,
	
	PARTITION_ACCESS=$(tmsh list auth user $USER | grep "partition-access" | sed 's/partition-access //')
	echo -n $PARTITION_ACCESS,
	
	SHELL_ACCESS=$(tmsh list auth user $USER | grep "shell" | sed 's/shell //')
	echo -n $SHELL_ACCESS,
	
	echo
done

