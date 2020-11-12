#!/bin/bash
#### OLD F5 VERSION - for TMOS that doesnt support 'one-line' ###
oldcertprofile=$1
newcertprofile=$2
OLDIFS=$IFS
IFS=,
[ ! $oldcertprofile ] || [ ! $newcertprofile ] && { echo "Profile spec not passed-in, cannot proceed"; echo "Usage example: ./swap-profiles.sh <old_profile_name> <new_profile_name>"; exit 99; }
echo "Profile Swap";
echo "-------------------------------------------------------------------------------------------------------------------------------"
echo "Switching all usage of $oldcertprofile to $newcertprofile..."
echo "-------------------------------------------------------------------------------------------------------------------------------"
OLDVIPLIST=$(tmsh list ltm virtual| tr -d "\n"|sed 's#}ltm#}\nltm#g'|grep $oldcertprofile|cut -d' ' -f3)
echo "VIPS involved in this transfer:"
echo $OLDVIPLIST
[ ! $OLDVIPLIST ] && { echo "NONE!"; echo "We didn't find any VIPs maching the old criteria you provided!"; echo "Stopping script here, before we cause any issues.";  exit 99; }
(tmsh list ltm virtual| tr -d "\n"|sed 's#}ltm#}\nltm#g'|grep $oldcertprofile|cut -d' ' -f3| xargs -I% -n1 tmsh modify ltm virtual % profiles delete { $oldcertprofile } profiles add { $newcertprofile })
echo "-------------------------------------------------------------------------------------------------------------------------------"
echo "Profile swaps completed!"
echo "-------------------------------------------------------------------------------------------------------------------------------"
NEWVIPLIST=$(tmsh list ltm virtual| tr -d "\n"|sed 's#}ltm#}\nltm#g'|grep $newcertprofile|cut -d' ' -f3)
echo "VIPS now using the new profile following transfer are:"
echo $NEWVIPLIST
IFS=$OLDIFS

