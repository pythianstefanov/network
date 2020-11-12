<#------------- CONNECT TO SWIS -------------#>

# load the snappin if it's not already loaded (step 1)

#if (!(Get-PSSnapin | Where-Object { $_.Name -eq "SwisSnapin" })) {

#    Add-PSSnapin "SwisSnapin"

#}

 

#define target host and credentials

 

$hostname = 'localhost'

#$user = "admin"

#$password = "password"

# create a connection to the SolarWinds API

#$swis = connect-swis -host $hostname -username $user -password $password -ignoresslerrors

$swis = Connect-Swis -Hostname $hostname -Trusted

 

<#------------- ACTUAL SCRIPT -------------#>

 

# The node ID to discover interfaces on

$nodes = Get-SwisData $swis "SELECT NodeID, Caption FROM Orion.Nodes where objectsubtype = 'SNMP'"

 

foreach ($n in $nodes) {

    # Discover interfaces on the node

    "Discovering $($n.caption)"

    $discovered = Invoke-SwisVerb $swis Orion.NPM.Interfaces DiscoverInterfacesOnNode $n.nodeid

 

    if ($discovered.Result -ne "Succeed") {

        " Interface discovery failed."

    }

    else {

        # Add the discovered interfaces

        " Discovered Interfaces"

        $intToAdd = $discovered.DiscoveredInterfaces

 

        # this section removes interfaces that are down or have already been added, unfortunately we cant filter against interface caption because it is a just dummy value in the current version

        foreach($int in $intToAdd.DiscoveredLiteInterface) {

            if($int.ifoperstatus -ne 1 -or $int.interfaceid -ne 0) {

                $intToAdd.RemoveChild($int) | Out-Null

            }

        }

        "  $($intToAdd.DiscoveredLiteInterface.count) interfaces to add"

        $intToAdd.DiscoveredLiteInterface

        Invoke-SwisVerb $swis Orion.NPM.Interfaces AddInterfacesOnNode @($n.nodeid, $intToAdd, "AddDefaultPollers") | Out-Null

    }

}

 

# the addinterfacesonnode verb also doesn't set the interface typename and description so we need to do that manually, and since there isn't a built in table to find them this method is a bit weak, this only fixes the descriptions if an interface with the same type number has already been in the system through the normal methods

 

$cleanup = Get-SwisData $swis @"

select i.uri, i.fullname, i.type, t.typename, t.typedescription

from orion.npm.Interfaces i

left join (SELECT distinct Type, TypeName, TypeDescription

FROM Orion.NPM.Interfaces where typename not like '') t on t.type=i.type

where i.typename = '' and t.typename is not null

"@

 

ForEach ($uri in $cleanup) {

    Write-Output "Setting type for $($uri.Fullname) with type $($uri.type), $($uri.typename), $($uri.typedescription)<br>`r`n"

    $uri.uri | Set-SwisObject $swis -Properties @{ Type = $($uri.type); Typename = $($uri.typename); TypeDescription = $($uri.typedescription)}

}

 

"These interfaces still have blank type descriptions"

 

$problems = Get-SwisData $swis "SELECT uri,fullname from orion.npm.interfaces where typename is null or typename like ''"

$problems