#adding irules in.

$cred = get-credential
$f5 = '10.30.64.38'
$irule = 'irule_detect_TLS1.0_loglocal'
$vip = 'gmmaintenance.travelclick.com_8443_pre-prod'
import-module f5-ltm

$session = New-F5Session -LTMName $f5 -LTMCredentials $cred -PassThru

$vipobj = Get-VirtualServer -F5Session $session -Name $vip
$iruleobj = Get-iRule -F5Session $session -name $irule

Add-iRuleToVirtualServer -F5Session $session -inputobject $vipobj -

Add-iRuleToVirtualServer -F5Session $session -iRuleName $irule -Name $vip -verbose


get-help Add-iRuleToVirtualServer