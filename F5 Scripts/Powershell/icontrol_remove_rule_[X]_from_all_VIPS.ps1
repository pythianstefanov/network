 #icontrol_remove_rule_fromall_VIPS.ps1
 #alastair shapley / byron felts @ pythian nov 2017
 
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
$logfile = "C:\scripts\f5logs\icontrol-remove-rule-$f5-$date.log"
$cred = get-credential

#this is the ip of the f5 to make changes on
#$f5 = '10.80.0.38'
$f5 = '10.80.64.38'
#$f5 = '10.30.0.38'
#$f5 = '10.30.64.38'

#This is the name of your irule
$irule = 'rule_universal-blocking'

#initialize all the things.
Add-PSSnapIn -Name iControlSnapIn
Initialize-F5.iControl -Hostname $f5 -Credentials $cred
$ic = Get-F5.iControl

#grab the rule, let's ensure it exists before we loop through every object.
$rule = $ic.LocalLBRule.query_rule( (,"$irule") ) 

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