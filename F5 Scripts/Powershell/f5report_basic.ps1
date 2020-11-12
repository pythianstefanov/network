param ( 
    [parameter(Mandatory=$true)]$F5LTM,
    [parameter(Mandatory=$true)]$outputpath
)

import-module f5-ltm

new-f5session -LTMName $f5ltm

$members = get-poolmember
$pools = get-pool
$vs = get-virtualserver

$members |export-csv -NoTypeInformation -Path "$outputpath\members.csv"
$pools |export-csv -NoTypeInformation -Path "$outputpath\pools.csv"
$vs |export-csv -NoTypeInformation -Path "$outputpath\vs.csv"