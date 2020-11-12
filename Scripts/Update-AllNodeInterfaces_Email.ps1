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

$outputbuffer = @()

# The node ID to discover interfaces on

#$nodes = Get-SwisData $swis "SELECT NodeID, Caption FROM Orion.Nodes where objectsubtype = 'SNMP' and Caption LIKE 'ADC%'"
$nodes = Get-SwisData $swis "SELECT NodeID, Caption FROM Orion.Nodes where objectsubtype = 'SNMP' and Caption LIKE 'ORLSV%'"
#$nodes = Get-SwisData $swis "SELECT NodeID, Caption FROM Orion.Nodes where objectsubtype = 'SNMP'"

Write-Output "`n... Performing Discovery of New Interfaces on Inventory Nodes ... "

$outputbuffer = "<H2>SolarWinds Orion Node Interfaces - Discovery Job Details</H2>`r`n<br>"

ForEach ($n in $nodes) {
    
    # Discover interfaces on the node

    # Uncomment hint below only if you want to see a reference to every existing node, regardless of discovery result.  (Good for debug perhaps, but makes the output much louder)

    Write-Output "Discovering $($n.caption) (debug mode active)"

    $discovered = Invoke-SwisVerb $swis Orion.NPM.Interfaces DiscoverInterfacesOnNode $n.nodeid
     
    If ($discovered.Result -ne "Succeed") {
        
        # Echo this remark anytime a Node's discovery failed, for awareness in the logs.

        Write-Output " Interface discovery for the Node $($n.caption) failed."

        $outputbuffer += " Interface discovery for the Node " + $($n.caption) + " failed.<br>"

    } Else {
        
        # Add the discovered interfaces

        # " Discovered Interfaces"

        $intToAdd = $discovered.DiscoveredInterfaces

        # This section removes interfaces that are down or have already been added,
        # unfortunately we can't filter against interface caption because it is simply a dummy value in the current version

        ForEach ($int in $intToAdd.DiscoveredLiteInterface) {
            
            If ($int.ifoperstatus -ne 1 -or $int.interfaceid -ne 0) {
                
                $intToAdd.RemoveChild($int) | Out-Null
            }

        }

        # If we detected new interfaces to add during our scan, echo the # amount and confirm we are doing so.  otherwise, remain silent on output.

        If ($intToAdd.DiscoveredLiteInterface.count -ne "0") {
            
            Write-Output "  Discovering new interfaces on $($n.caption) "
            Write-Output "  $($intToAdd.DiscoveredLiteInterface.count) interfaces to add"
            $outputbuffer += "  Discovering new interfaces on " + $($n.caption) + "<br>"
            $outputbuffer += "" + $($intToAdd.DiscoveredLiteInterface.count) + " interfaces to add:<br>"
        }

        $intToAdd.DiscoveredLiteInterface

        If ($intToAdd.DiscoveredLiteInterface.count -ne "0") {
            
            $outputbuffer += "" + $intToAdd.DiscoveredLiteInterface + "<br>"

        }

        Invoke-SwisVerb $swis Orion.NPM.Interfaces AddInterfacesOnNode @($n.nodeid, $intToAdd, "AddDefaultPollers") | Out-Null

        If ($intToAdd.DiscoveredLiteInterface.count -ne "0") {
            
            $outputbuffer += "....<br>"
        }

    }

}

# Setting Interface Type and Descriptions, and General Clean Up

# the addinterfacesonnode verb also doesn't set the interface typename and description so we need to do that manually
# and since there isn't a built in table to find them this method is a bit weak
# this only fixes the descriptions if an interface with the same type number has already been seen in the system through the normal methods
 
Write-Output " `n ... Cleaning Up Interface Type and Descriptions ... "

$cleanup = Get-SwisData $swis @"
    SELECT i.uri, i.fullname, i.type, t.typename, t.typedescription
    FROM orion.npm.Interfaces i
    LEFT JOIN (SELECT distinct Type, TypeName, TypeDescription FROM Orion.NPM.Interfaces WHERE typename not like '') t on t.type=i.type
    WHERE i.typename = '' and t.typename is not null
"@
 

ForEach ($uri in $cleanup) {
    
    Write-Output "Setting type for $($uri.Fullname) with type $($uri.type), $($uri.typename), $($uri.typedescription)"

    $outputbuffer +=  "Setting type for " + $($uri.Fullname) + "with type " + $($uri.type) + ", " + $($uri.typename) + ", " + $($uri.typedescription) + "<br>"

    $uri.uri | Set-SwisObject $swis -Properties @{ Type = $($uri.type); Typename = $($uri.typename); TypeDescription = $($uri.typedescription)}

}


Write-Output " `n Following Cleanup attempts, note the following Interfaces still have blank or generic type descriptions:"

$outputbuffer += " Following Cleanup attempts, note the following Interfaces still have blank or generic type descriptions:<br>"

$problems = Get-SwisData $swis "SELECT uri,fullname FROM orion.npm.interfaces WHERE typename is null or typename LIKE ''"

$problems = $problems | out-string

Write-Output $problems

$problems = "`r`n<pre>" + $problems + "</pre>"

$outputbuffer = $outputbuffer + $problems

$outputbuffer = $outputbuffer | out-string

$reportspath = ".\reports"

If (!(test-path $reportspath)) {
    New-Item -Force -Path $reportspath -ItemType Directory
}

$outputbuffer | Out-File -Force -FilePath .\reports\report-output.html

$body = [System.IO.File]::ReadAllText(".\reports\report-output.html")
$MailMessage = @{ 
    To = "stefanov@pythian.com"
    From = "no-reply@orion.travelclick.net"
    Subject = "SolarWinds Orion Node Interface Discovery Report" 
    Body = "$body" 
    Smtpserver = 'mtallm01.tcprod.local'
    ErrorAction = "SilentlyContinue" 
}
Send-MailMessage @MailMessage -bodyashtml

Write-Output "Sending an email with report to preset recipients"