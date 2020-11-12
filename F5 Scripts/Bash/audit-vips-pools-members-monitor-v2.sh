echo vs name, destination, pool, pool members, monitor
VIRTUALS=$(tmsh list ltm virtual | grep "ltm virtual" | cut -d" " -f3)
for VS in $VIRTUALS;
do
  echo -n $VS,
  DEST=$(tmsh list ltm virtual $VS | grep destination | cut -d" " -f6)
  echo -n $DEST,
  POOL=$(tmsh list ltm virtual $VS | grep " pool" | cut -d" " -f6)
    if [ -n "$POOL" ];
  then
    echo -n $POOL,
  else
    echo -n N/A,
  fi
    if [ -n "$POOL" ];
  then
    MBRS=$(tmsh list ltm pool "$POOL" | grep address | cut -d" " -f14)
    echo -n $MBRS
  else
    echo -n N/A,
  fi
    if [ -n "$POOL" ];
  then
    MONITOR=$(tmsh list ltm pool "$POOL" | grep monitor | cut -d" " -f6)
      if [ -n "$MONITOR" ];
    then
      echo -n ,$MONITOR #| sed 's/ //g'
      fi
  else 
    echo -n N/A
  fi
  echo
done
