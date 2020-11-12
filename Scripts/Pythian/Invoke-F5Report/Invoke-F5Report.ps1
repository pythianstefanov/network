<#
.SYNOPSIS
  Get events and filter them
.DESCRIPTION
  The script creates an XLSX and HTML report for all query-able F5 load balancers, covering the below fields for each VIP.
.INPUTS
  .\Input\VIPReportTemplate.xlsx <An xlsx template with Dashboard, Pivot Tables and Graphics. This file is used as template to generate the xlsx output report>
  .\Input\LoadBalancerList.csv <A csv with the list of Load Balancers to query>
  .\Input\svc-orion-password-secure.txt < text file with the encrypted password for the service account to use>

.OUTPUTS
  .\Output\$date - VIP Report.html <A HTML file with the result output>
  .\Output\$date - VIP Report.xlsx <An xlsx file with the result output>
.NOTES
  Version:        2.0
  Author:         Alastair Shapley, Ramon Ornelas
  Creation Date:  10/14/2019
  Update Date:    5/14/2020
  Purpose/Change: Reorganized code, added module. Changed exports from CSV to XLSX.
  
.EXAMPLE
  ./Invoke-F5Report.ps1
#>

#---------------------------------------------------------[Initializations]--------------------------------------------------------

Add-PSSnapIn -Name iControlSnapIn
Import-Module ".\Modules\F5Report_Module.psm1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#General section
$date = Get-Date -format M.d.yyyy
$Username = "TCPROD\svc-orion"
$Password = Get-Content -Path .\Input\svc-orion_password_as_system_20201103.txt | ConvertTo-SecureString
$Credentials = New-Object System.Management.Automation.PSCredential $Username,$Password
$LB = Import-Csv -Path .\Input\LoadBalancerList.csv
$HTMLReport = ".\Output\$date - VIP Report.html"
$XLSReport = ".\Input\VIPReportTemplate.xlsx"
$ReportTitle = "VIP Report"
#Email section
$From = "VIP_Report@travelclick.com"
$To = "Neteng@travelclick.com"
$Cc = "team46@pythian.com"
$Subject = "TravelClick VIP Summary Report"
$Body = "<h2>TravelClick VIP Summary Report</h2><br><br>"
$Body += “Hello, This Email contains the TravelClick Load Balancer and Virtual Server Report.<br><br>” 
$Body += “Note: please open the sheet in edit mode to allow the graphics to update, and click YES on any warnings” 
$SMTPServer = "mtallm01.tcprod.local"
$SMTPPort = "25"
#Arrays section
$entirelist = @()
$certentirelist = @()
$style = @'
<style type="text/css">
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 11px; padding: 5px 20px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
'@

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#LoadBalancers Iteration
foreach($F5LTM in $LB){
    #Connecting to Load Balancer
    Initialize-F5.iControl -Hostname $F5LTM.IP -Credentials $Credentials
    $ic = get-f5.iControl
    
    #Get VIP Name, VIP IP, Service Port
    $allinfo=@()
    $VSList =  $ic.LocalLBVirtualServer.get_list()
    $AddressPortList =  $ic.LocalLBVirtualServer.get_destination_v2($VSList)
    $F5LTMIP = $F5LTM.IP
    
    #Virtual Servers Iteration
    for($i=0; $i -lt $AddressPortList.length; $i++) { 
        $virtual = $VSList[$i];
        write-output "checking VIP: $virtual on LB: $F5LTMIP"
        $vaddr = $AddressPortList[$i].address;
        $vport = $AddressPortList[$i].port;
        $pool = ($ic).LocalLBVirtualServer.get_default_pool_name( ($VSList[$i]) )
        #travelclick only uses the common partition, so lets remove it.
        $virtual = $virtual -replace "/Common/"
        $vaddr = $vaddr -replace "/Common/"
        $pool = $pool -replace "/Common/"
        $TotalConns = $ic.LocalLBVirtualServer.get_statistics($virtual) | % {$_.statistics.statistics | ? {$_.type -eq "STATISTIC_CLIENT_SIDE_TOTAL_CONNECTIONS"} | %{$_.value.low} }
        $status = ($ic).LocalLBVirtualServer.get_object_status($VSList[$i])
        [string]$vipenabled = $status.enabled_status
        [string]$availability_status =  $status.availability_status
        [string]$availability_status_desc = $status.status_Description
        [string]$irules = ($ic.LocalLBVirtualServer.get_rule( (,"$virtual") ) ).rule_name

        #Get SSL Profiles
        try{
            $profiles = $ic.LocalLBVirtualServer.get_profile($VSList[$i])
            $profileerror = $false
        }
        catch{
            $profiles = ''
            $profileerror = $true
            write-output "unable to retrieve profile for $virtual"
        }
        #SSL Profiles Iteration
        Foreach($profile in $profiles){
            $ClientSSLProfile = $profile | where { $_.profile_type -eq "PROFILE_TYPE_CLIENT_SSL" }
        }
        if($ClientSSLProfile){
            $sslprofile = $ClientSSLProfile.profile_name
            $sslprofile = $sslprofile -replace "/Common/"
            #certificate
            $certfile = ((get-f5.icontrol).LocalLBProfileClientSSL.get_certificate_file_v2($sslprofile)).value
            $certfile = $certfile -replace "/Common/"
            #ciphers
            [string]$ciphers = ((get-f5.icontrol).LocalLBProfileClientSSL.get_cipher_list($sslprofile)).values
        }
        elseif($profileerror -eq $true){
            $sslprofile = "unable to retrieve"
            $certfile = "unable to retrieve"
            $ciphers = "unable to retrieve"
        }
        elseif($profileerror -eq $false){
            $sslprofile = ""
            $certfile = ""
            $ciphers = ""
        }
        #create the object with the classifications into a nice usable object
        $result = New-Object PSObject
        $result | Add-Member -type NoteProperty -Name 'LoadBalancer' -Value $F5LTM.ALIAS
        $result | Add-Member -type NoteProperty -Name 'LoadBalancer IP' -Value $F5LTM.IP
        $result | Add-Member -type NoteProperty -Name 'VirtualServer' -Value "$virtual"
        $result | Add-Member -type NoteProperty -Name 'VirtualServer Status' -Value "$vipenabled"
        $result | Add-Member -type NoteProperty -Name 'Availability Status' -Value "$availability_status"
        $result | Add-Member -type NoteProperty -Name 'Status Description' -Value "$availability_status_desc"
        $result | Add-Member -type NoteProperty -Name 'VirtualServer IP' -Value "$vaddr"
        $result | Add-Member -type NoteProperty -Name 'Virtual Server Port' -Value "$vport"
        $result | Add-Member -type NoteProperty -Name 'Total Connections' -Value "$TotalConns"
        $result | Add-Member -type NoteProperty -Name 'Default Pool' -Value "$pool"
        $result | Add-Member -type NoteProperty -Name 'SSLProfile' -Value "$sslprofile"
        $result | Add-Member -type NoteProperty -Name 'Certificate File' -Value "$certfile"
        $result | Add-Member -type NoteProperty -Name 'Ciphers' -Value "$ciphers"
        $result | Add-Member -type NoteProperty -Name 'Irules' -Value "$irules"
        $allinfo += $result
}

    #Get Certificates
    $allcerts = @()
    $certs = ($ic).ManagementKeyCertificate.get_certificate_list(0)

    #Certificates Iteration
    for($i=0; $i -lt $certs.count; $i++) {
        $hash = @{
            certfile = $certs[$i].file_name
            certexpirationdate =  [string]$certs[$i].certificate.expiration_string
            Certificate_Common_name = [string]$certs[$i].certificate.subject.common_name
            Certificate_Issuer =  [string]$certs[$i].certificate.issuer.common_name
            Certificate_Issuer_org =  [string]$certs[$i].certificate.issuer.organization_name
        }
        $tempobj = New-Object PSObject -Property $hash
        $allcerts += $tempobj
}

    #Get Pool Lists, Statuses, Nodes
    $allpoolinfo = @()
    $PoolList = $ic.LocalLBPool.get_list()

    #Pools Iteration
    for($i=0; $i -lt $PoolList.length; $i++){
        $Poolmember = $ic.LocalLBPool.get_member_v2($PoolList[$i])
        $poolname =  ($PoolList[$i])
        write-output "checking pool: $poolname on LB: $F5LTMIP"
        if($poolmember){
            $Poolmembername = $poolMember.get_address()
            $PoolMemberstatuses = $ic.LocalLBPool.get_member_object_status($PoolList[$i], $Poolmember)
            $memberstatus = ($PoolMemberstatuses.availability_status)
            $poolname = $poolname -replace "/Common/"
            $Poolmembername = $Poolmembername -replace "/Common/"
        }
        else{
            $Poolmembername = "no pool members"
            $memberstatus = "no pool members"
        }
        #create the object with the classifications into a nice usable object
        $poolresult = New-Object PSObject
        $poolresult | Add-Member -type NoteProperty -Name 'Poolname' -Value "$poolname"
        $poolresult | Add-Member -type NoteProperty -Name 'PoolMembers' -Value "$Poolmembername"
        $poolresult | Add-Member -type NoteProperty -Name 'PoolMembersstatus' -Value "$memberstatus"
        $allpoolinfo += $poolresult
}

    #Join objects together before looping.
    $joined = Join-Object -Left $allinfo -Right $allpoolinfo -LeftJoinProperty DefaultPool -RightJoinProperty Poolname -RightProperties 'PoolMembers','PoolMembersstatus'
    $entirelist += $joined
    $certentirelist += $allcerts
}

#Write Content to Report.
$ResultSet = $entirelist|  ConvertTo-Html -head $style -Title $ReportTitle -Body "<h1>$ReportTitle</h1>`n<h5>Updated: on $(Get-Date)</h5>"
Add-Content $HTMLReport $ResultSet
write-output "Exporting to Excel"
$entirelist | Export-Excel -WorksheetName "VIPRawData" -ClearSheet -Path $XLSReport
$certentirelist | Export-Excel -WorksheetName "CertRawData" -ClearSheet -Path $XLSReport
Copy-Item -Path $XLSReport -Destination ".\Output\$date - VIP Report.xlsx"

#Send report by email
Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort -Credential $Credentials -Attachments ".\Output\$date - VIP Report.xlsx"