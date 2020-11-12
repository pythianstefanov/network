
$cred = get-credential
$f5 = '10.30.64.38'
$irule = 'irule_detect_TLS1.0_loglocal'
#$vip = 'vs_ota2-perf.ihotelier.com_443'


Add-PSSnapIn -Name iControlSnapIn

#start
Initialize-F5.iControl -Hostname $f5 -Credentials $cred

$ic = Get-F5.iControl

#need to loop through the below for each VIP
#grab the rule
#$rule = $ic.LocalLBRule.query_rule( (,"$irule") ) 

#get all vips that have 443 in the name, thereby selecting only ssl vips. (doing this by way of checking ssl profiles is way more effort than is required in this case)
$allvips = $ic.LocalLBVirtualServer.get_list() |where {$_ -match '443'}

$allvips| ForEach-Object {
    $obj = $_ -replace '/common/', ""
    $obj
    # Allocate and populate parameters
    $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
    $VirtualServerRule.rule_name = $irule
    $VirtualServerRule.priority = 500
    $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
    $VirtualServerRules[0][0] = $VirtualServerRule

    #add the rule
    $ic.LocalLBVirtualServer.add_rule( (,"$obj"), $VirtualServerRules )
    }