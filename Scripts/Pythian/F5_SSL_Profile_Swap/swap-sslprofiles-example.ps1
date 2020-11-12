# Move to working directory
cd "C:\Pythian\cert swapping\"

# Import module
import-module "C:\Pythian\cert swapping\modules\swap-f5certs.psm1"

# Get user name and password
$cred = get-credential

# Specify the LB you're working on.
$f5 = '10.30.64.38' #ADC Dev F5
$f5 = '10.80.64.38' #LDC Dev F5

$f5 = '10.30.0.38' #ADC Prod F5
$f5 = '10.80.0.38' #LDC Prod F5

# Specify the new profile for the domain you're working on.
$new_profile = 'profile_wildcard.travelclick.com_exp_09_23_2022_infosec_compliant'
$new_profile = 'profile_wildcard.ihotelier.com_exp_09_23_2022_infosec_compliant'
$new_profile = 'profile_wildcard.travelclick.net_exp_09_23_2022_infosec_compliant'

# Update the list of VIPs depending on what domain and F5 you're working on.
$viplist = (get-content "C:\Pythian\cert swapping\viplist.txt")

# Removes unused iRules from VIPs before you do the swap..
# errors here don't really matter, it will certainly error if the vip doesn't have the rule attached.we can replace the error with a nicer message by implementing a try/catch and checking if the irule is attached before removing it.
# These iRules are ok to remove because they are based on old bugs or outdated ciphers that we block with these updated profiles.
$irulestoremove = 'irule_detect_TLS1.0_loglocal', 'iRule_TLS_renegotiation_Bug_Tracker_36935', 'rule_TLS-regnotiation_Bug_Tracker_36935', 'irule_detect_weak_ciphers_SSLv3_or_anyRC4', 'rule_TLS-renegotiation_Bug_Tracker_36935'
foreach ($rule in $irulestoremove){
    Remove-iRule -cred $cred -f5 $f5 -viplist $viplist -rule_name $rule
}

# Swap ssl profiles example using text file as input. (we can specify log path with -logfile parameter.)
$logfile = "$(Get-ScriptDirectory)\logs\$((Get-Date).ToString('yyyyMMdd'))-switch-f5sslprofile-$new_profile.log"
switch-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $viplist -newprofile $new_profile -logfile  $logfile
