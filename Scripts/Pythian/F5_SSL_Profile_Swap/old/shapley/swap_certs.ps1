# SSL Client Swap script - prototype/in progress
# consists of a single function that must currently be fed one vip's details at a time, this appears to be working OK.
# this can be changed to a loop later, likely the loop should stay within the function, 
# there are historical problems around SNI here that I'm currently unable to reproduce ... has firmware upgrades removed our issue?
# two working examples below.
function Get-ScriptDirectory {
    if ($psise) {
        Split-Path $psise.CurrentFile.FullPath
    }
    else {
        $global:PSScriptRoot
    }
}

function switch-f5vipsslprofile {
    param(
    $f5ltm,
    $cred,
    $vipname,
    $existingprofile,
    $newprofile,
    $logfile="$(Get-ScriptDirectory)\$((Get-Date).ToString('yyyyMMdd'))-switch-f5sslprofile.log"
    )
    <#
        .SYNOPSIS
        For a given Virtual Server, or list of them, on an F5 LTM, replaces an F5 Client SSL profile

        .DESCRIPTION
         For a given Virtual Server, or list of them, on an F5 LTM, replaces an F5 Client SSL profile

        .PARAMETER f5ltm
        IP/Name of Load balancer instance

        .PARAMETER cred
        powershell credential object
        (Get-Date).ToString('yyyyMMdd')
        .PARAMETER vipname
        vip name on F5 load balancer. A list is accepted.

        .PARAMETER existingprofile
        ssl client profile to remove

        .PARAMETER newprofile
        ssl client profile to add

        .PARAMETER logfile
        log file to append to.
    #>    
    #Initialize snap-in
    Add-PSSnapIn -Name iControlSnapIn
    Initialize-F5.iControl -Hostname $f5 -Credentials $cred
    $ic = Get-F5.iControl
    "
    "|out-file $logfile -append
    "$((Get-Date).ToString('yyyyMMddhhmmss')) - switch-f5vipsslprofile initialized"|out-file $logfile -append
    "executing user: $($env:UserName)"|out-file $logfile -append
    foreach ($vip in $vipname){
        "processing $vip on $f5ltm"|out-file $logfile -append

        if ($ic.LocalLBVirtualServer.get_list() |where {$_ -match "$vip"}){

            "$vip was found on $f5ltm"|out-file $logfile -append

            $VirtualServerExistProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
            $VirtualServerExistProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
            $VirtualServerExistProfile.profile_name = $existingprofile
            $VirtualServerExistProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
            $VirtualServerExistProfiles[0][0] = $VirtualServerExistProfile

            $VirtualServerNewProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
            $VirtualServerNewProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
            $VirtualServerNewProfile.profile_name = $newprofile
            $VirtualServerNewProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
            $VirtualServerNewProfiles[0][0] = $VirtualServerNewProfile

            try{
                $ic.LocalLBVirtualServer.remove_profile( (,"$vip"), $VirtualServerExistProfiles )
                        write-output "success removing $existingprofile from $vip"
                        "success removing $existingprofile from $vip"|out-file $logfile -append
                        

                $ic.LocalLBVirtualServer.add_profile( (,"$vip"), $VirtualServerNewProfiles )
                        write-output "success adding $newprofile to $vip"
                        "success adding $newprofile to $vip"|out-file $logfile -append
                }
            catch{
                write-output -message "error updating $vip"
                "error updating $vip"|out-file $logfile -append
                write-output -message "$_"
                "$_"|out-file $logfile -append
                }
        }
    else{
        write-output "could not retrieve vip named $vipname"
        "could not retrieve vip named $vipname"|out-file $logfile -append
        write-output $_
        "$_"|out-file $logfile -append
    }
    }
}

function get-vips-sslclientprofile {
    param(
    $f5ltm,
    $cred,
    $sslclientprofile
    )
        
    #Initialize snap-in
    Add-PSSnapIn -Name iControlSnapIn
    Initialize-F5.iControl -Hostname $f5 -Credentials $cred
    $ic = Get-F5.iControl

    $allvips = $ic.LocalLBVirtualServer.get_list()
    $allsslclientprofiles = $ic.LocalLBProfileClientSSL.get_list()
    $viplist = @()
        foreach($vip in $allvips){      
            #get the SSL profile for a particular VIP.
            $profiles = ($ic.LocalLBVirtualServer.get_profile($vip))
            
            if($profiles |select-string "PROFILE_TYPE_CLIENT_SSL"){
                write-verbose "ssl profile found"
                $sslprofilestring = (($profiles|out-string -Stream)|where {$_ -match "PROFILE_TYPE_CLIENT_SSL"}).split(" ")[2]
                
                if($sslprofilestring -eq $sslclientprofile){
                    $viplist += $vip
                    write-verbose "match found"
                    }
                elseif(($sslprofilestring -replace "/Common/") -eq $sslclientprofile){
                    $viplist += $vip
                    write-verbose "match found (/Common/)"
                    }
                else{
                    write-verbose "no match found"
                    }
                }
            
            
        }
    return $viplist

}



 $sslclientprofile = $new_profile     
 get-vips-sslclientprofile -f5ltm $f5 -cred $cred -sslclientprofile $new_profile       

#get the SSL profile for a particular VIP.
$vipprofiles = ($ic.LocalLBVirtualServer.get_profile($testvip))

#split the awkward output and filter it so you get the CLIENT SSL profile only.
$sslprofilestring = (($vipprofiles|out-string -Stream)|where {$_ -match "PROFILE_TYPE_CLIENT_SSL"}).split(" ")[2]
            }
        catch{

            write-output -message "$_"
            }
    }
    else{
        write-output "could not retrieve SSL client profiles"
        write-output $_
    }
}








#working example A - ADC DEV


$cred = get-credential
$f5 = '10.30.64.38'
$testvip = 'vs_api-test_443'
#This is the names of your ssl profiles
$exist_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_infosec_compliant'
$new_profile = 'test_sni_automation'

# to test, check via GUI and update -newprofile and -existingprofile appropriately.
switch-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $testvip -newprofile $new_profile -existingprofile $exist_profile


<#
Process:
1. identify SSL profile(s) to swap out
2. create replacement profile(s) (manual)
3. identify vips with that profile attached (currently manual, but this could be a function)
4. confirm manually the list of vips to be addresssed and get approval.
5. run the switch-f5vipsslprofile() function against the manual list to swap the profiles.
#>

# switch-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $testvip -newprofile $exist_profile -existingprofile $new_profile

#working example B - LDC DEV

$cred = get-credential
$f5 = '10.80.64.38'
$testvip = 'test_vs_partner-portal.travelclick.com'
#This is the names of your ssl profiles
$exist_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_RestrictCiphers_NoRC4_No3DES'
$new_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_infosec_compliant'

# to test, check via GUI and update -newprofile and -existingprofile appropriately.
switch-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $testvip -newprofile $new_profile -existingprofile $exist_profile
# switch-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $testvip -newprofile $exist_profile -existingprofile $new_profile



#working example C with SNI - ADC DEV

$cred = get-credential
$f5 = '10.30.64.38'
$testvip = 'vs_api-test_443'
#This is the names of your ssl profiles
$exist_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_infosec_compliant'
$new_profile = 'test_sni_automation'

# to test, check via GUI and update -newprofile and -existingprofile appropriately.
switch-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $testvip -newprofile $new_profile -existingprofile $exist_profile 
# switch-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $testvip -newprofile $exist_profile -existingprofile $new_profile


#LDC Dev TEST

$cred = get-credential
$f5 = '10.80.64.38'
$testvip = 'test_vs_partner-portal.travelclick.com'
#This is the names of your ssl profiles
$exist_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_RestrictCiphers_NoRC4_No3DES'
$new_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_infosec_compliant'

switch-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $testvip -newprofile $exist_profile  -existingprofile $new_profile

### SNI STUFF ###


#params for testing
$f5 = '10.30.64.38'
$testvip = 'vs_api-test_443'
#This is the names of your ssl profiles
$exist_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_RestrictCiphers_NoRC4'
$new_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_infosec_compliant'

#get all the SSL profiles
$allsslclientprofiles = $ic.LocalLBProfileClientSSL.get_list()



#get the SSL profile for a particular VIP.
$vipprofiles = ($ic.LocalLBVirtualServer.get_profile($testvip))

#split the awkward output and filter it so you get the CLIENT SSL profile only.
$sslprofilestring = (($vipprofiles|out-string -Stream)|where {$_ -match "PROFILE_TYPE_CLIENT_SSL"}).split(" ")[2]

#working example. showing we can definitely gather the SNI information before a given function. 
$ic.LocalLBProfileClientSSL.get_sni_default_state($sslprofilestring)
$ic.LocalLBProfileClientSSL.get_sni_require_state($sslprofilestring)
$ic.LocalLBProfileClientSSL.get_server_name($sslprofilestring)

# next steps, we could simply use this to disable the swap and report an error (should be rare)

# or, we could asswemble a table with the gathered values and use the following methods to unset/set as either an individual function or a larger function.

$ic.LocalLBProfileClientSSL.set_server_name($profile , $value) #(unsure of exact syntax but something like this)
$ic.LocalLBProfileClientSSL.set_sni_require_state($profile , $value)
$ic.LocalLBProfileClientSSL.get_sni_default_state($profile , $value)