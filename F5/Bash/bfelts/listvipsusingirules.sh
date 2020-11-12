#!/bin/sh
echo irule name, usage count, associated vips using rule
IRULES=$(tmsh list ltm rule | grep "ltm rule" | cut -d" " -f3)
for IRULE in $IRULES;
do
  echo -n $IRULE,
  VIPS=$(tmsh list ltm virtual one-line | grep " "$IRULE" " | awk '{print $3}')
  SPACES=$(echo $VIPS | awk -F '//' '{ n = gsub(/ /, "", $1); print n }')

  #echo -n $VIPS
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

