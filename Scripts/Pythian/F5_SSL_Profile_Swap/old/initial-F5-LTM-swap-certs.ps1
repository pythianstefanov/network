# SSL Client Swap script for F5 LTMs utilizing iControlSnapIn - prototype/in progress
# Alastair Shapley - Byron Felts - Pythian SRE Team

#$cred = get-credential

$username = "bfelts"
$password = Get-Content -path .\bfelts-storedPassword.txt | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential $username,$password

$VIPS = import-csv “rolloutplan2.csv” -header F5IP, VIPName, ExistProfile, NewProfile

ForEach ($VIP in $VIPS){
     $f5 = $VIP.F5IP
     
     if (!$session) {
     import-module f5-ltm
     $session = New-F5Session -LTMName $f5 -LTMCredentials $cred -PassThru
     }            
     
     $name = $VIP.VIPName
     $exist_profile = $VIP.ExistProfile
     $new_profile = $VIP.NewProfile
     $obj = $name
        
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

     
     #add the replacement profile
     try{
        $session.LocalLBVirtualServer.add_profile( (,"$obj"), $VirtualServerNewProfiles )
        write-host "success applying $new_profile to $obj"
        }
     catch{
          write-host -message "error applying $new_profile to $obj"
	  write-host -message "$_"
          }

     #remove the existing profile
     try{
	$session.LocalLBVirtualServer.remove_profile( (,"$obj"), $VirtualServerExistProfiles )
	write-host "success removing $exist_profile from $obj"
        }
     catch{
          write-host -message "error removing $exist_profile from $obj"
          write-host -message "$_"
          }                 
}