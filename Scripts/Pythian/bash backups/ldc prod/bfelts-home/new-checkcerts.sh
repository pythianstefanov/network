#!/bin/bash

### set acceptable threshold in seconds (86400 = 1 day, 172800 seconds = 2 days, etc)
##25920000 = 300 days
#threshold=25920000
threshold=35920000

### get today's date
this_date=`date +%s`

##echo "This date: "$this_date

(IFS='
'

### loop through the stored certificates
##output=`tmsh list / sys crypto one-line |grep "sys crypto cert"`
output=`tmsh list / sys all-properties one-line |grep "sys crypto cert"`


for f in ${output}
do
    cert=`echo $f |awk -F" " '{ print $4 }'`
    certdate=`expr match "$f" '.*\(expiration.*organization\)' |sed s/expiration// | sed s/organization//`
    expires=`date -d $certdate +%s`

    if [ $this_date -ge $(($expires - $threshold)) ]
    then
        expires_when=$(((expires - $this_date) / 60 / 60 / 24))
        echo "$cert is about to expire in $expires_when days"
    fi
done)

