Function Orion-AddNode
{
    Param(
    [Parameter(Mandatory=$true)]
    [Validatenotnullorempty()]
    $SwisConnection,
    [Parameter(Mandatory=$true)]
    [String]$NodeName,
    [Parameter(Mandatory=$true)]
    [String]$NodeIPAddress,
    [Parameter(Mandatory=$true)]
    [String]$PollingEngineID,
    [Parameter(Mandatory=$true)]
    [ValidateSet('ICMP','SNMPV2')]
    [String]$PollingMethod,
    [Parameter(Mandatory=$False)]
    [String]$SNMPV2Community,
    [Parameter(Mandatory=$False)]
    [String]$City,
    [Parameter(Mandatory=$False)]
    [String]$Vendor)

    If ($PollingMethod -EQ 'SNMPV2')
    {
        If ($PollingMethod -EQ 'SNMPV2' -and $SNMPV2Community -EQ $Null)
        {
            Write-Host "Polling Method $($PollingMethod) Selected but no SNMP Community supplied"
            break
        }
        Else
        {
            $NewSNMPV2NodeProps = @{
                IPAddress = $NodeIPAddress;
                EngineID = $PollingEngineID;
                Caption = $NodeName;
                ObjectSubType ="SNMP";
                Community = $SNMPV2Community;
                SNMPVersion = "2";
		Vendor = $Vendor;
                DNS = "";
                SysName = "";
                }
                
            $NewNode = New-SwisObject $SwisConnection -EntityType "Orion.Nodes" -Properties $NewSNMPV2NodeProps
        }
    }
    Else
    {
        $NewICMPNodeProps = @{
            IPAddress = $NodeIPAddress;
            EngineID = $PollingEngineID;
            Caption = $NodeName;
            ObjectSubType ="ICMP";
            Vendor = $Vendor;
            DNS = "";
            SysName = "";
            }

        $NewNode = New-SwisObject $swis -EntityType "Orion.Nodes" -Properties $NewICMPNodeProps
    }

    If ($City)
	{
	$CityProperty = @{
	CITY="$City";
        }
        $nodeProps = Get-SwisObject $swis -Uri $NewNode
        $NewNodeCustom = $nodeProps.Uri + "/CustomProperties"
	Set-SwisObject $swis -Uri $NewNodeCustom -Properties $CityProperty
        }

    Return $NewNode

}

Function Orion-SetStdDevicePollers
{
    Param(
    [Parameter(Mandatory=$true)]
    [Validatenotnullorempty()]
    $SwisConnection,
    [Parameter(Mandatory=$true)]
    [String]$NodeID,
    [Parameter(Mandatory=$true)]
    [ValidateSet('ICMP','SNMPV2')]
    [String]$PollingType)


    # Orion ICMP Device Pollers
      $OrionICMPStdPollers = 
        "N.Status.ICMP.Native",
        "N.ResponseTime.ICMP.Native"

    # Orion SNMP Device Pollers
      $OrionSNMPStdPollers = 
        "N.Status.ICMP.Native",
        "N.ResponseTime.ICMP.Native",
        "N.Status.SNMP.Native",
        "N.Details.SNMP.Generic",
        "N.Uptime.SNMP.Generic",
        "N.Cpu.SNMP.CiscoGen3",
        "N.Memory.SNMP.CiscoGen4",
        "N.ResponseTime.SNMP.Native",
        "N.Routing.SNMP.Ipv4RoutingTable",
        "N.Topology_CDP.SNMP.cdpCacheTable",
        "N.Topology_Layer2.SNMP.Dot1qTpFdb",
        "N.Topology_Layer3.SNMP.ipNetToMedia",
        "N.Topology_Layer3_IpRouting.SNMP.rolesRouter",
        "N.Topology_LLDP.SNMP.lldpRemoteSystemsData",
        "N.Topology_PortsMap.SNMP.Dot1dBase",
        "N.Topology_STP.SNMP.Dot1dStp",
        "N.Topology_Vlans.SNMP.VtpVlan",
        "V.Details.SNMP.Generic",
        "V.Statistics.SNMP.Generic",
        "V.Status.SNMP.Generic",        
        "I.Rediscovery.SNMP.IfTable",
        "I.StatisticsErrors32.SNMP.IfTable",
        "I.StatisticsTraffic.SNMP.Universal",
        "I.Status.SNMP.IfTable"

    If ($PollingType -EQ 'ICMP')
    {
        $OrionDevicePollers = $OrionICMPStdPollers
    }
    ElseIf ($PollingType -EQ 'SNMP')
    {
        $OrionDevicePollers = $OrionSNMPStdPollers
    }

    ForEach ($OrionDevicePoller in $OrionDevicePollers)
    {
        $NetObjectID = $NodeID
        $NetObjectType = $OrionDevicePoller.Trim(".")[0]
        $NetObject = $NetObjectType + ":" + $NodeID
        $PollerType = $OrionDevicePoller

        $DevicePollerAdd = @{
            NetObjectID=$NetObjectID;
            NetObjectType=$NetObjectType;
            NetObject=$NetObject;
            PollerType=$PollerType;
            }

    $AddDevicePollers = New-SwisObject $SwisConnection -EntityType "Orion.Pollers" -Properties $DevicePollerAdd

    }

    Return $AddDevicePollers

}

Function Orion-SetHardwareHealthSensors
{
    Param(
    [Parameter(Mandatory=$true)]
    [Validatenotnullorempty()]
    $SwisConnection,
    [Parameter(Mandatory=$true)]
    [String]$NodeID,
    [Parameter(Mandatory=$true)]
    [ValidateSet('Enable','Disable','Check','DeleteCollectedData')]
    [String]$Action,
    [Parameter(Mandatory=$False)]
    [String]$Manufacturer)

    $NetObjectID = ("N:" + $NodeID)


    Switch -Wildcard ($Action)
    {
        "Enable"    {
                    $Verb = 'EnableHardwareHealth'
                    break
                    }
        "Disable"   {
                    $Verb = 'DisableHardwareHealth'
                    break
                    }
        "Check"     {
                    $Verb = 'IsHardwareHealthEnabled'
                    break
                    }
        "DeleteCollectedData" {
                    $Verb = 'DeleteHardwareHealth'
                    break
                    }
    }

    Switch -Wildcard ($Manufacturer)
    {
        "*Cisco*"   {
                    $HHPollingMethod = '9'
                    break
                    }
        "*Juniper*" {
                    $HHPollingMethod = '10'
                    break
                    }
        "*HP*"      {
                    $HHPollingMethod = '11'
                    break
                    }
        "*Hewlett*" {
                    $HHPollingMethod = '11'
                    break
                    }
        "*F5*"      {
                    $HHPollingMethod = '12'
                    break
                    }
        "*Arista*"  {
                    $HHPollingMethod = '18'
                    break
                    }
        Default     {
                    $HHPollingMethod = '0'
                    break
                    }
    }

    If ($Action -EQ 'Enable')
    {
        $Output = Invoke-SwisVerb -SwisConnection $Swis -EntityName Orion.HardwareHealth.HardwareInfoBase -Verb $Verb -Arguments @($NetObjectID,$HHPollingMethod) 
    }
    Else
    {
        $Output = Invoke-SwisVerb -SwisConnection $Swis -EntityName Orion.HardwareHealth.HardwareInfoBase -Verb $Verb -Arguments @($NetObjectID) 
    }

    Return $Output

}


# Import the SwisPowerShell module
Import-Module -Name SwisPowerShell

Write-Host "Enter your password to continue."

$username = "bfelts"
$password = Read-Host -AsSecureString
$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
$swis = Connect-Swis -cred $cred

# Assumes the Swis connection variable is called $Swis

#$Nodes = import-csv -path ".\addNodes.csv"

$Nodes = import-csv -path .\testAdd.csv

Foreach ($Node in $Nodes)

{

$NewNode = Orion-AddNode -SwisConnection $Swis -NodeName $Node.NodeName -NodeIPAddress $Node.NodeIPAddress -PollingEngineID $Node.PollingEngineID -PollingMethod $Node.PollingMethod -SNMPV2Community $Node.SNMPV2Community -City $Node.City -Vendor $Node.NodeManufacturer

$NodeProperties = Get-SwisObject $swis -Uri $NewNode

$PollerAdds = Orion-SetStdDevicePollers -SwisConnection $Swis -NodeID  $NodeProperties.NodeID -PollingType $Node.PollingMethod

$HHPolling = Orion-SetHardwareHealthSensors -SwisConnection $Swis -NodeID $NodeProperties.NodeID -Action Enable -Manufacturer $Node.NodeManufacturer

$PollNodeID = $NodeProperties.OrionIdPrefix + $NodeProperties.NodeID

$PollNow = Invoke-SwisVerb $Swis Orion.Nodes PollNow @($PollNodeID)

}

