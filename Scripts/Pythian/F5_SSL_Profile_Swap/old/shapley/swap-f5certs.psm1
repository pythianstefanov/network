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
            
            if(($profiles|out-string -Stream) -match "PROFILE_TYPE_CLIENT_SSL"){
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

Export-ModuleMember *
