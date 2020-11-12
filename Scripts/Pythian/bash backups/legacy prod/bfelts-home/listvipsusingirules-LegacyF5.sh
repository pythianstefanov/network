#!/bin/sh
echo irule name, usage count, associated vips using rule
IRULES=$(tmsh list ltm rule | grep "ltm rule" | cut -d" " -f3)
for IRULE in $IRULES;
do
  echo -n $IRULE,
  VIPS=$(tmsh list ltm virtual | tr -d '\n' |  sed -e 's/vlans-enabled}/vlans-enabled}\n/g' | grep " "$IRULE" " | awk '{print $3}' | sed -e 's/$//g' | tr '\n' ' ')
  SPACES=$(echo $VIPS | awk -F '//' '{ n = gsub(/ /, "", $1); print n }')

  if [ $SPACES == 0 ]; then
        if [ ${#VIPS} == 0 ]; then
           echo -n $SPACES
        else
           SPACES=1
           echo -n $SPACES,
        fi
  else
     SPACES=$((SPACES+1)) 
     echo -n $SPACES,
  fi
  echo -n $VIPS
  echo
done

