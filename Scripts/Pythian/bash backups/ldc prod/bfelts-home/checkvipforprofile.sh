#!/bin/bash

SEARCH=$1

VIRTUAL=$(tmsh list / ltm virtual $1 one-line | grep -o -P '(?<={ } ).*(?={ context clientside })')
for PROFILE in $VIRTUAL;
do
  echo -n $PROFILE
  echo
done

