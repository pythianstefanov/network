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
    [String]$SNMPV2Community)


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
                ObjectSubType =$PollingMethod;
                Community = $SNMPV2Community;
                SNMPVersion = "2";
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
            ObjectSubType =$PollingMethod;
            DNS = "";
            SysName = "";
            }

        $NewNode = New-SwisObject $swis -EntityType "Orion.Nodes" -Properties $NewICMPNodeProps
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
    [ValidateSet('ICMP','SNMP')]
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



$NodeName = 'Router01'
$NodeIPAddress = '192.168.0.1' 
$PollingEngineID = '1'
$PollingMethod = 'SNMPV2'
$SNMPV2Community = 'public'
$NodeManufacturer = 'Cisco'

# Import the SwisPowerShell module
Import-Module -Name SwisPowerShell

# Assumes the Swis connection variable is called $Swis


# 1. Create the Node 
$NewNode = Orion-AddNode -SwisConnection $Swis -NodeName $NodeName -NodeIPAddress $NodeIPAddress -PollingEngineID $PollingEngineID -PollingMethod $PollingMethod -SNMPV2Community $SNMPV2Community

# 2. Get the New Node Properties
$NodeProperties = Get-SwisObject $swis -Uri $NewNode

# 3. Assign the standard pollers for ICMP/SNMP
$PollerAdds = Orion-SetStdDevicePollers -SwisConnection $Swis -NodeID  $NodeProperties.NodeID -PollingType $PollingMethod


# 4. Enable hardware health polling
$HHPolling = Orion-SetHardwareHealthSensors -SwisConnection $Swis -NodeID $NodeProperties.NodeID -Action Enable -Manufacturer $NodeManufacturer



# 5. Trigger a poll
$PollNodeID = $NodeProperties.OrionIdPrefix + $NodeProperties.NodeID
$PollNow = Invoke-SwisVerb $Swis Orion.Nodes PollNow @($PollNodeID)

