#import functions
. C:\Pythian\includes.ps1

#setup

Install-Module SwisPowerShell
Install-Module powerorion


#check on things

get-command -module powerorion
get-command -module SwisPowerShell

#connect
$hostname = "localhost"
$swis = Connect-Swis -Hostname $hostname -UserName ashapley -Password 

$allnodes = Get-SwisData -SwisConnection $swis -Query 'SELECT NodeID, Caption FROM Orion.Nodes'
$alldevices = $allnodes.NodeID |%{get-orionnode -SwisConnection $swis -nodeid $_}
$allcustomprops = $allnodes.NodeID |%{get-orionnode -SwisConnection $swis -nodeid $_ -customproperties}

$trimalldevices= $alldevices|select nodeid, objectsubtype, Ipaddress, ipaddresstype, dynamicip, Caption, NodeDescription, Description, DNS, Sysname, Location, contact, StatusDescription, LastBoot, Machinetype, Nodename, External, Community, RWCommunity, IP, IP_Address, Displayname, AncestorDisplaynames, uri

$joined = Join-Object -Left $trimalldevices -Right $allcustomprops -LeftJoinProperty NodeID -RightJoinProperty Nodeid

#above all works fine but node groups were missing, lets get the node groups
$nodegroups = Get-SwisData -SwisConnection $swis -Query "SELECT CoreNodeID,NodeGroup FROM Cirrus.Nodes"


$2ndjoin = Join-Object -Left $joined -Right $nodegroups -LeftJoinProperty NodeID -RightJoinProperty CoreNodeid

$date = get-date -Format ddmmyyyy
$2ndjoin |export-csv -Path "C:\pythian\output\$date - orion list.csv"

