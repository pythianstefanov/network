function Get-ScriptDirectory {
    if ($psise) {
        Split-Path $psise.CurrentFile.FullPath
    }
    else {
        $global:PSScriptRoot
    }
}


function Switch-SslProfile {
    param(
    $f5ltm,
    $cred,
    $vipname,
   # $existingprofile,
    $newprofile,
    $logfile
    )

<#
        .SYNOPSIS
        For a given Virtual Server or list of Virtual Servers on an F5 LTM, replaces an F5 Client SSL profile

        .DESCRIPTION
         For a given Virtual Server, or list of them, on an F5 LTM, removes then replaces an F5 Client SSL profile

        .PARAMETER f5ltm
        IP/Name of Load Balancer instance

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
    
    
        #$cred = get-credential
        #$f5 = '10.80.64.38'
        #$vipname  = 'vs_res-t4.ihotelier.com_443'
            #This is the names of your ssl profiles to swap out

        #$newprofile = 'profile_wildcard.ihotelier.com_exp_09_23_2022_infosec_compliant'
        #$logfile =  "C:\pythian\test.log"
    
    
    #Initialize snap-in



    Add-PSSnapIn -Name iControlSnapIn
    Initialize-F5.iControl -Hostname $f5 -Credentials $cred
    $ic = Get-F5.iControl
    "
    "|Out-File $logfile -append
    "$((Get-Date).ToString('yyyyMMddhhmmss')) - switch-f5vipsslprofile initialized" | Out-File $logfile -append
    "Executing user: $($env:UserName)"|Out-File $logfile -append
    foreach ($vip in $vipname){
        
        "Processing $vip on $f5ltm"| Out-File $logfile -append

        if ($ic.LocalLBVirtualServer.get_list() | where {$_ -match "$vip"}){

            "FOUND $vip on $f5ltm"| Out-File $logfile -append

            #1st, get the profile for the vip. 
            try {
                $profiles = ($ic.LocalLBVirtualServer.get_profile($vip))
                $existingsslprofilestring = ((($profiles | Out-String -Stream) | where {$_ -match "PROFILE_TYPE_CLIENT_SSL"}).split(" ")| ? {$_.trim() -ne "" })[2] -replace "/Common/"
                #then create the representation of it.
                $VirtualServerExistProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
                $VirtualServerExistProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
                $VirtualServerExistProfile.profile_name = $existingsslprofilestring
                $VirtualServerExistProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
                $VirtualServerExistProfiles[0][0] = $VirtualServerExistProfile
                }
            catch{
                Write-Output "UNABLE to retrieve SSL profile for vip $VIP. Attempting to add the new one in..."
                "UNABLE to retrieve ssl profile for vip $VIP. Attempting to add the new one in..." | Out-File $logfile -append
                try {
                        $VirtualServerNewProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
                        $VirtualServerNewProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
                        $VirtualServerNewProfile.profile_name = $newprofile
                        $VirtualServerNewProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
                        $VirtualServerNewProfiles[0][0] = $VirtualServerNewProfile

                        $ic.LocalLBVirtualServer.add_profile( (,"$vip"), $VirtualServerNewProfiles )
                        Write-Output "ADDED $newprofile to $vip"
                        "ADDED $newprofile to $vip" | Out-File $logfile -append
                        }
                    catch{
                        Write-Output -message "ERROR adding $newprofile to $vip"
                        "ERROR adding $newprofile to $vip" | Out-File $logfile -append
                        Write-Output -message "$_"
                        "$_" | Out-File $logfile -append
                        }
                }

            if($existingsslprofilestring -match $newprofile){
                Write-Output "MATCH FOUND - new profile already in place and matches the previous existing profile"
                "MATCH FOUND - new profile already in place and matches the previous existing profile" | Out-File $logfile -append
                continue
            }
            elseif($existingsslprofilestring){
                
                #if the existing ones there, try to remove, if that fails, error, move on to next, then try add

                try{
                    $ic.LocalLBVirtualServer.remove_profile( (,"$vip"), $VirtualServerExistProfiles )
                    Write-Output "REMOVED $existingsslprofilestring FROM $vip"
                    "REMOVED $existingsslprofilestring FROM $vip" | Out-File $logfile -append
                            
                    try {
                        $VirtualServerNewProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
                        $VirtualServerNewProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
                        $VirtualServerNewProfile.profile_name = $newprofile
                        $VirtualServerNewProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
                        $VirtualServerNewProfiles[0][0] = $VirtualServerNewProfile

                        $ic.LocalLBVirtualServer.add_profile( (,"$vip"), $VirtualServerNewProfiles )
                        Write-Output "ADDED $newprofile to $vip"
                        "ADDED $newprofile to $vip"|Out-File $logfile -append
                        }
                    catch{
                        Write-Output -message "ERROR adding $newprofile to $vip"
                        "ERROR adding $newprofile to $vip" | Out-File $logfile -append
                        Write-Output -message "$_"
                        "$_" | Out-File $logfile -append
                        }
                    }
            
                catch{
                    Write-Output "ERROR removing $existingsslprofilestring from $vip"
                    "ERROR removing $existingsslprofilestring from $vip" | Out-File $logfile -append
                }
            
            
            }

        }
        
            
    else{
        Write-Output "Could not retrieve vip $vipname"
        "Could not retrieve vip $vipname" | Out-File $logfile -append
        Write-Output $_
        "$_" | Out-File $logfile -append
    }
}
}


function get-vipssslclientprofile {
    param(
    $f5ltm,
    $cred,
    $sslclientprofile
    )
        
    #Initialize snap-in
    Add-PSSnapIn -Name iControlSnapIn
    Initialize-F5.iControl -Hostname $f5 -Credentials $cred |Out-Null
    $ic = Get-F5.iControl

    $allvips = $ic.LocalLBVirtualServer.get_list()
    $allsslclientprofiles = $ic.LocalLBProfileClientSSL.get_list()
    $viplist = @()
        foreach($vip in $allvips){      
            #get the SSL profile for a particular VIP.
            $profiles = ($ic.LocalLBVirtualServer.get_profile($vip))
            
            if(($profiles|Out-String -Stream) -match "PROFILE_TYPE_CLIENT_SSL"){
                Write-Verbose "FOUND SSL profile"
                $sslprofilestring = (($profiles | Out-String -Stream)|where {$_ -match "PROFILE_TYPE_CLIENT_SSL"}).split(" ")[2]
                
                if($sslprofilestring -eq $sslclientprofile){
                    $viplist += $vip
                    Write-Verbose "FOUND mathcing SSL profile"
                    }
                elseif(($sslprofilestring -replace "/Common/") -eq $sslclientprofile){
                    $viplist += $vip
                    Write-Verbose "FOUND matching SSL proifle in (/Common/)"
                    }
                else{
                    Write-Verbose "NOT FOUND matching SSL profile"
                    }
                }
            
            
        }
    return $viplist

}

function Remove-iRule()
{

param(
$viplist,
[string]$rule_name,
$f5ltm,
$cred
)

#Initialize snap-in
    Add-PSSnapIn -Name iControlSnapIn
    Initialize-F5.iControl -Hostname $f5ltm -Credentials $cred | Out-Null
    $ic = Get-F5.iControl

foreach($virtual in $viplist){
    $virtual_servers = @($virtual)
    Write-Output "Processing $virtual and attempting to remove rule $rule_name"
    $rule = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerRule;
    $rule.rule_name = $rule_name;

    $rule.priority = 0;
    $rules = @($rule);

        if(($ic.LocalLBVirtualServer.get_rule($virtual_servers)).rule_name -match $rule_name){
            Write-Output "FOUND irule $rule_name on $virtual"
            try{
                $ic.LocalLBVirtualServer.remove_rule(
                $virtual_servers,
                $rules
                );
                Write-Output "REMOVED iRule $rule_name from $virtual"
                }
            catch{
                Write-Output "UNABLE to remove iRule $rule_name from $virtual"
                }
        } 
        else{
            Write-Output "NOT FOUND iRule $rule_name on $virtual"
        }
    }
}


Export-ModuleMember *