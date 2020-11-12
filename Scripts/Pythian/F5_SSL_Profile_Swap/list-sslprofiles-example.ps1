#list ssl profiles example

#Say we want to get all the vips on 10.80.64.38 that have the following ssl profile "profile_wildcard.travelclick.com_exp_09_06_2020_infosec_compliant"

#import the module
import-module 'C:\Pythian\cert swapping\modules\swap-f5certs.psm1'

#populate the following vars:
$f5ltm = "10.80.64.38"
$cred = get-credential
$sslclientprofile = "profile_wildcard.travelclick.com_exp_09_06_2020_infosec_compliant"

#then just run the function

get-vipssslclientprofile -f5ltm $f5ltm -cred $cred -sslclientprofile $sslclientprofile

#you can export this straight to text as needed:
get-vipssslclientprofile -f5ltm $f5ltm -cred $cred -sslclientprofile $sslclientprofile|out-file viplist.txt


# you can then use the output of this to swap profiles for the given list.. see next example.