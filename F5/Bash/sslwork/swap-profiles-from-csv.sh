#!/bin/bash
INPUT=$1
OLDIFS=$IFS
IFS=,
[ ! $INPUT ] || [ ! -f $INPUT ] && { echo "$INPUT input file not found - please check how youre 
calling the script and try again."; exit 99; }
while read f5ip vipname oldcertprofile newcertprofile
do
   echo "Changing $f5ip $vipname:  Switching $oldcertprofile to $newcertprofile..."
   (tmsh modify ltm virtual $vipname profiles delete { $oldcertprofile } profiles add { $newcertprofile })
done < $INPUT
IFS=$OLDIFS
