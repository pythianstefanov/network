# SSL Client Swap script - prototype/in progress


function remove-f5vipsslprofile {
    param(
    $f5ltm,
    $cred,
    $vipname,
    $profilename
    )
        
    #Initialize snap-in
    Add-PSSnapIn -Name iControlSnapIn
    Initialize-F5.iControl -Hostname $f5 -Credentials $cred
    $ic = Get-F5.iControl

    if ($ic.LocalLBVirtualServer.get_list() |where {$_ -match "$vipname"}){
            
        $VirtualServerExistProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
        $VirtualServerExistProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
        $VirtualServerExistProfile.profile_name = $profilename
        $VirtualServerExistProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
        $VirtualServerExistProfiles[0][0] = $VirtualServerExistProfile


        try{
            $ic.LocalLBVirtualServer.remove_profile( (,"$vipname"), $VirtualServerExistProfiles )
                    write-host "success removing $profilename from $vipname"
            }
        catch{
            write-host -message "error removing $profilename from $vipname"
            write-host -message "$_"
            }
    }
    else{
        write-output "could not retrieve vip named $vipname"
        write-output $_
    }
}

function add-f5vipsslprofile {
    param(
    $f5ltm,
    $cred,
    $vipname,
    $profilename
    )
        
    #Initialize snap-in
    Add-PSSnapIn -Name iControlSnapIn
    Initialize-F5.iControl -Hostname $f5 -Credentials $cred
    $ic = Get-F5.iControl

    if ($ic.LocalLBVirtualServer.get_list() |where {$_ -match "$vipname"}){
            
        $VirtualServerExistProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
        $VirtualServerExistProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
        $VirtualServerExistProfile.profile_name = $profilename
        $VirtualServerExistProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
        $VirtualServerExistProfiles[0][0] = $VirtualServerExistProfile


        try{
            $ic.LocalLBVirtualServer.remove_profile( (,"$vipname"), $VirtualServerExistProfiles )
                    write-host "success adding $profilename to $vipname"
            }
        catch{
            write-host -message "error adding $profilename to $vipname"
            write-host -message "$_"
            }
    }
    else{
        write-output "could not retrieve vip named $vipname"
        write-output $_
    }
}



$cred = get-credential
$f5 = '10.30.64.38'
$testvip = 'vs_api-test_443'
#This is the names of your ssl profiles
$exist_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_RestrictCiphers_NoRC4'
$new_profile = 'profile_wildcard.travelclick.com_exp_09_06_2020_infosec_compliant'

remove-f5vipsslprofile -f5ltm $f5 -cred $cred -vipname $testvip -profilename $new_profile




















#Initialize snap-in
Add-PSSnapIn -Name iControlSnapIn
Initialize-F5.iControl -Hostname $f5 -Credentials $cred
$ic = Get-F5.iControl

### this part won't actually work, so we're leaving out for now.  (not sure how to walk SSL profile(s) for associated VirtServers.. is there a way??)
#here we think were trying to grab the profiles using existing profile, hoping to avoid looping through every object.  <----????
$result = $ic.LocalLBVirtualServer.get_profile( (,"$exist_profile",'*') ) 

#name filter for vip selection -- this may not be honoring the $result above once we get into things below, need to figure this out  <----????
$allvips = $ic.LocalLBVirtualServer.get_list() |where {$_ -match '_443'}

$allvips = $allvips -replace '/common/'

$allvips | where {$_ -match $testvip}

# Allocate and populate parameters
        $VirtualServerExistProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
        $VirtualServerExistProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
        $VirtualServerExistProfile.profile_name = $exist_profile
        $VirtualServerExistProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
        $VirtualServerExistProfiles[0][0] = $VirtualServerExistProfile

        $VirtualServerNewProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
        $VirtualServerNewProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
        $VirtualServerNewProfile.profile_name = $new_profile
        $VirtualServerNewProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
        $VirtualServerNewProfiles[0][0] = $VirtualServerNewProfile


        $ic.LocalLBVirtualServer.remove_profile( (,"$testvip"), $VirtualServerExistProfiles )

               $ic.LocalLBVirtualServer.add_profile( (,"$testvip"), $VirtualServerNewProfiles )

#if rule exists on the f5, loop through everything, remove the old profile first to avoid conflicts, and apply the new profile:
if($result){
    $allvips| ForEach-Object {
        $obj = $_ -replace '/common/', "" #get back to a plain string
        $obj
        # Allocate and populate parameters
        $VirtualServerExistProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
        $VirtualServerExistProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
        $VirtualServerExistProfile.profile_name = $exist_profile
        $VirtualServerExistProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
        $VirtualServerExistProfiles[0][0] = $VirtualServerExistProfile
              
        $VirtualServerNewProfile = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerProfile
        $VirtualServerNewProfile.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
        $VirtualServerNewProfile.profile_name = $new_profile
        $VirtualServerNewProfiles = New-Object -TypeName "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1,1
        $VirtualServerNewProfiles[0][0] = $VirtualServerNewProfile

        #remove the existing profile
        try{
            $ic.LocalLBVirtualServer.remove_profile( (,"$obj"), $VirtualServerExistProfiles )
                 write-host "success removing $exist_profile from $obj"
            }
        catch{
            write-host -message "error removing $exist_profile from $obj"
            write-host -message "$_"
            }
                
        #add the replacement profile
        try{
            $ic.LocalLBVirtualServer.add_profile( (,"$obj"), $VirtualServerNewProfiles )
                 write-host "success applying $new_profile to $obj"
            }
        catch{
            write-host -message "error applying $new_profile to $obj"
            write-host -message "$_"
            }
        }
    }