<#
.SYNOPSIS
  Monitor partitions on F5 and alert if below the defined threshold
.DESCRIPTION
  The script will connect to a given list of F5 Load Balancers and query the partitions disk space and send an e mail if the size is below a defined threshold
.INPUTS
  .\Input\LoadBalancerList.csv <A csv with the list of Load Balancers to query>
  .\Input\svc-orion-f5.txt < txt with the encrypted password for the service account to use>
.OUTPUTS
  .\Output\$date - log.txt <A TXT file with the log output>
.NOTES
  Version:        1.0
  Author:         Ramon Ornelas
  Creation Date:  8/26/2020
  Update Date:    
  Purpose/Change: Initial draft
  
.EXAMPLE
  ./Invoke-F5DiskCheck.ps1
#>

#---------------------------------------------------------[Initializations]--------------------------------------------------------

#Add-PSSnapIn -Name iControlSnapIn
#Import-Module ".\Modules\F5Report_Module.psm1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#General section
$date = Get-Date -format M.d.yyyy
#$Username = "TCPROD\svc-orion"
#$Password = Get-Content -Path .\Input\svc-orion-f5.txt | ConvertTo-SecureString
#$Credentials = New-Object System.Management.Automation.PSCredential $Username,$Password
$LB = Import-Csv -Path .\Input\LoadBalancerList.csv
$MountPointList = Import-Csv -Path .\Input\MountPointList.csv
$Log = ".\Output\$date - log.txt"
#SNMP Section
$community = "notpublic79"
$BaseOID = ".1.3.6.1.4.1.3375.2.1.7.3.2.1"
$VolumeNameOID = ".1.3.6.1.4.1.3375.2.1.7.3.2.1.1"
$BlockSizeOID = ".1.3.6.1.4.1.3375.2.1.7.3.2.1.2"
$TotalBlocksOID = ".1.3.6.1.4.1.3375.2.1.7.3.2.1.3"
$FreeBlocksOID = ".1.3.6.1.4.1.3375.2.1.7.3.2.1.4"
#Email section
$From = "F5_Monitoring@travelclick.com"
#$To = "Neteng@travelclick.com"
#$Cc = "team46@pythian.com"
$To = "ornelas@pythian.com"
$Cc = "felts@pythian.com"
$Subject = "F5 Load Balancer Partition is low on free space"
$Body = "<h2>Monitoring Script has detected that F5 Load Balancer is low on free space</h2><br><br>"
$Body += “Hello, Please check the Load Balancer for free disk space.<br><br>” 
$Body += “Note: Test” 
$SMTPServer = "mtallm01.tcprod.local"
$SMTPPort = "25"
#Arrays section
$SNMPWalk = @()
$allinfo = @()

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#LoadBalancers Iteration
$SNMPWalk = invoke-snmpwalk -IP 10.80.64.38 -OIDStart .1.3.6.1.4.1.3375.2.1.7.3 -Community notpublic79
foreach($F5LTM in $LB){
    foreach($MountPoint in $MountPointList){
        #Connecting to Load Balancer
        #Initialize-F5.iControl -Hostname $F5LTM.IP -Credentials $Credentials
        #$ic = get-f5.iControl
        #Write-Output $F5LTM.ALIAS
        #Get Volumes
        $OID = $VolumeNameOID + $MountPoint.OID
        $VolumeName = get-snmpdata -IP $F5LTM.IP -OID $OID -Community $community
        $OID = $BlockSizeOID + $MountPoint.OID
        $BlockSize = get-snmpdata -IP $F5LTM.IP -OID $OID -Community $community
        $OID = $TotalBlocksOID + $MountPoint.OID 
        $TotalBlocks = get-snmpdata -IP $F5LTM.IP -OID $OID -Community $community
        $OID = $FreeBlocksOID + $MountPoint.OID 
        $FreeBlocks = get-snmpdata -IP $F5LTM.IP -OID $OID -Community $community
        $SizeMB = ($TotalBlocks.Data.ToInt32($Null) * $BlockSize.Data.ToInt32($Null)) / 1048576
        $FreeMB = ($FreeBlocks.Data.ToInt32($Null) * $BlockSize.Data.ToInt32($Null)) / 1048576
        $result = New-Object PSObject
        $result | Add-Member -type NoteProperty -Name 'LoadBalancer' -Value $F5LTM.ALIAS
        $result | Add-Member -type NoteProperty -Name 'VolumeName' -Value $VolumeName.Data
        $result | Add-Member -type NoteProperty -Name 'TotalSize(MB)' -Value $SizeMB
        $result | Add-Member -type NoteProperty -Name 'FreeSize(MB)' -Value $FreeMB
        $allinfo += $result
    }      
}
Write-Output $allinfo
#Send alert by email
#Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort -Credential $Credentials