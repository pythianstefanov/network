 #icontrol_add_irule_to_many_vips.ps1
 #alastair shapley @ pythian nov 2017
 
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
$logfile = "C:\scripts\f5logs\icontrol-add-irules-$f5-$date.log"
$cred = get-credential

#this is the ip of the f5 to make changes on
$f5 = '10.80.0.38'

#This is the name of your irule
$irule = 'irule_detect_TLS1.0_loglocal'



#initialize all the things.
Add-PSSnapIn -Name iControlSnapIn
Initialize-F5.iControl -Hostname $f5 -Credentials $cred
$ic = Get-F5.iControl

#grab the rule, let's ensure it exists before we loop through every object.
$rule = $ic.LocalLBRule.query_rule( (,"$irule") ) 

#name filter for vip selection. get all vips that have 443 in the name, thereby selecting only ssl vips. (doing this by way of checking ssl profiles is way more effort than is required in this case)
$allvips = $ic.LocalLBVirtualServer.get_list() |where {$_ -match 'vs_ota2.ihotelier.com_443|???????'}

#if rule exists on the f5, loop through everything and apply the irule:
if($rule){
    #if our irule exists on the box, loop through every vip and apply it.
    write-logfile -logFile $logfile -message "starting run: task: adding irule to vips: $irule"
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        write-logfile -logFile $logfile -message "modifying item : $obj . task: adding irule: $irule"
        # Allocate and populate parameters
        $VirtualServerRule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule
        $VirtualServerRule.rule_name = $irule
        $VirtualServerRule.priority = 500
        $VirtualServerRules = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerRule[][]" 1,1
        $VirtualServerRules[0][0] = $VirtualServerRule

        #add the rule
        try{
            $ic.LocalLBVirtualServer.add_rule( (,"$obj"), $VirtualServerRules )
            write-logfile -logfile $logfile -message "success applying $irule to $obj"
            }
        catch{
            write-logfile -logfile $logfile -message "error applying $irule to $obj"
            write-logfile -logfile $logfile -message "$_"
            }
        }
    }