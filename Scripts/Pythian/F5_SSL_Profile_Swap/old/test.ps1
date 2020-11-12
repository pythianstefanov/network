$cred = get-credential
$f5 = '192.168.6.50'
import-module f5-ltm

$session = New-F5Session -LTMName $f5 -LTMCredentials $cred -PassThru


#$vipobj = Get-VirtualServer -F5Session $session -Name $vip
#$iruleobj = Get-iRule -F5Session $session -name $irule

#Add-iRuleToVirtualServer -F5Session $session -inputobject $vipobj -

#Add-iRuleToVirtualServer -F5Session $session -iRuleName $irule -Name $vip -verbose

#get-help Add-iRuleToVirtualServer