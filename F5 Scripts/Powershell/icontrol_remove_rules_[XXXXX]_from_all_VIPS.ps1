 #icontrol_remove_rule_fromall_VIPS.ps1
 #alastair shapley / byron felts / igor andev @ pythian nov 2017
 
 function write-logfile {
    <#
    .DESCRIPTION
       Simplifies the logging requirements with a common function set. Appends to the file by default.
    .PARAMETER logFile
       The path to the logfile to be using.
    .PARAMETER message
       The string to be writing to the logfile.
    #>
    [CmdletBinding()]
    param(
       [Parameter(Mandatory=$true)]
       [string]$logFile,
       [Parameter(valuefrompipeline=$true,Mandatory=$true)]
       [string]$message
    )
    $dateStamp=date
    "$datestamp -- $message" |out-file -FilePath $logfile -Append
 }
 
#variables. change if this is functionalized, for now its just a script because selecting the vips is a bit of a hassle. currently just doing that with a name filter.
$date = get-date -Format M.d.yyyy
$logfile = "C:\scripts\f5logs\icontrol-remove-rules-$f5-$date.log"
$cred = get-credential

#this is the ip of the f5 to make changes on
#$f5 = '10.80.0.38'
#$f5 = '10.80.64.38'
#$f5 = '10.30.0.38'
$f5 = '10.30.64.38'

#This is the name of your irule
$irule = 'iRule_Block_JMX_ManagmentURI'
$irule2 = 'irule_block_jmx_admin_invoker'
$irule3 = 'irule_block_jmx_admin_invoker_uridecode'
$irule4 = 'irule_new_jmx_block_invoker'
$irule5 = 'rule_block_jmx_console'
$irule6 = 'rule_block_jmx_prob_host_manager_for_tomcat'
$irule7= 'rule_block_jmx_web_console'
$irule8 = 'rule_block_jmx_web_console_QA'
$irule9 = 'irule_block_invoker'

#initialize all the things.
Add-PSSnapIn -Name iControlSnapIn
Initialize-F5.iControl -Hostname $f5 -Credentials $cred
$ic = Get-F5.iControl

#grab the rule, let's ensure it exists before we loop through every object.
$rule = $ic.LocalLBRule.query_rule( (,"$irule") ) 
$rule2 = $ic.LocalLBRule.query_rule( (,"$irule2") ) 
$rule3 = $ic.LocalLBRule.query_rule( (,"$irule3") ) 
$rule4 = $ic.LocalLBRule.query_rule( (,"$irule4") ) 
$rule5 = $ic.LocalLBRule.query_rule( (,"$irule5") ) 
$rule6 = $ic.LocalLBRule.query_rule( (,"$irule6") ) 
$rule7 = $ic.LocalLBRule.query_rule( (,"$irule7") ) 
$rule8 = $ic.LocalLBRule.query_rule( (,"$irule8") ) 
$rule9 = $ic.LocalLBRule.query_rule( (,"$irule9") ) 


#name filter for vip selection. get all vips that have 443 in the name, thereby selecting only ssl vips. (doing this by way of checking ssl profiles is way more effort than is required in this case)
$allvips = $ic.LocalLBVirtualServer.get_list()

#if rule exists on the f5, loop through everything and remove the irule:
if($rule){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }
if($rule2){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule2"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule2"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule2
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }
if($rule3){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule3"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule3"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule3
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }
if($rule4){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule4"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule4"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule4
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }
if($rule5){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule5"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule5"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule5
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }
if($rule6){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule6"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule6"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule6
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }
if($rule7){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule7"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule7"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule7
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }
if($rule8){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule8"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule8"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule8
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }
if($rule9){
    #if our irule exists on the box, loop through every vip and remove it.
    write-logfile -logFile $logfile -message "starting run: task: removing irule from vips: $irule9"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: removing irule: $irule9"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule9
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #remove the rule
        try{
            $ic.LocalLBVirtualServer.remove_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success removing $irule from $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error removing $irule from $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }