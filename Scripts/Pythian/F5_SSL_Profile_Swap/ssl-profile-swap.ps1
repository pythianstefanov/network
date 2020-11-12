# Move to working directory
cd "C:\Scripts\F5_SSL_Profile_Swap\"

# Import module
Import-Module "C:\Scripts\F5_SSL_Profile_Swap\modules\replace-sslprofiles.psm1" -Verbose

# Get user name and password
$cred = Get-Credential

# Specify the Load Balancer you're working on.
$f5 = '10.30.64.38' #ADC Dev F5
$f5 = '10.80.64.38' #LDC Dev F5

$f5 = '10.30.0.38' #ADC Prod F5
$f5 = '10.80.0.38' #LDC Prod F5

# Specify the new SSL profile for the domain you're working on.
$new_profile = 'profile_wildcard.travelclick.com_exp_09_23_2022_infosec_compliant'
$new_profile = 'profile_wildcard.ihotelier.com_exp_09_23_2022_infosec_compliant'
$new_profile = 'profile_wildcard.travelclick.net_exp_09_23_2022_infosec_compliant'

$new_profile = 'profile_wildcard.zdirect.com_exp_08_26_2022_infosec_compliant'
$new_profile = 'profile_wildcard.roomrez.com_exp_08_24_2022_infosec_compliant'
$new_profile = 'profile_wildcard.ezyield.com_exp_08_24_2022_infosec_compliant'

$new_profile = 'profile_wildcard.travelclickhosting.com_exp_11_07_2021_infosec_compliant'

# Update the list of VIPs depending on what domain and F5 you're working on.
$viplist = (Get-Content "C:\Scripts\F5_SSL_Profile_Swap\viplist.txt")

# Removes unused iRules from VIPs before you do the swap..
# Errors here don't really matter, it will certainly error if the vip doesn't have the rule attached.we can replace the error with a nicer message by implementing a try/catch and checking if the irule is attached before removing it.
# These iRules are ok to remove because they are based on old bugs or outdated ciphers that we block with these updated profiles.
$irulestoremove = 'irule_detect_TLS1.0_loglocal', 'iRule_TLS_renegotiation_Bug_Tracker_36935', 'rule_TLS-regnotiation_Bug_Tracker_36935', 'irule_detect_weak_ciphers_SSLv3_or_anyRC4', 'rule_TLS-renegotiation_Bug_Tracker_36935'
foreach ($rule in $irulestoremove){
    Remove-iRule -cred $cred -f5 $f5 -viplist $viplist -rule_name $rule
}

# Swap SSL profiles using text file with VIPs list as input. (we can specify log path with -logfile parameter.)
$logfile = "$(Get-ScriptDirectory)\logs\$((Get-Date).ToString('yyyyMMdd'))-Replace-SSL-Profile-$new_profile.log"
Switch-SslProfile -f5ltm $f5 -cred $cred -vipname $viplist -newprofile $new_profile -logfile  $logfile


