<#
.SYNOPSIS
  Delete files older than 6 months in a given list of paths
.DESCRIPTION
  Delete files older than 6 months in a given list of paths
.INPUTS
  .\Input\TargetPaths.txt <A TXT with the list of target paths>
.OUTPUTS
  .\Output\$date - ACS-deletedlog.txt <A Log File containing the list of deleted files>
.NOTES
  Version:        2.0
  Author:         Byron Felts, Ramon Ornelas
  Creation Date:  8/5/2020
  Update Date:    8/21/2020
  Purpose/Change: Reorganized code, added read from file.
  
.EXAMPLE
  ./Remove-OldLogFiles.ps1
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#General section
$date = Get-Date -format M.d.yyyy
$LogFile = ".\Output\$date - ACS-deletedlog.txt"
$FolderList = Get-Content -Path .\Input\TargetPaths.txt
#-----------------------------------------------------------[Execution]------------------------------------------------------------
ForEach($Folder in $FolderList){
    #Delete files older than 6 months
    Get-ChildItem $Folder -Recurse -Force -ea 0 |
    ? {!$_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-180)} |
    ForEach-Object {
        $_ | del -Force
        $_.FullName | Out-File $LogFile -Append
    }
    #Delete empty folders and subfolders
    Get-ChildItem $Folder -Recurse -Force -ea 0 |
    ? {$_.PsIsContainer -eq $True} |
    ? {$_.getfiles().count -eq 0} |
    ForEach-Object {
        $_ | del -Force
        $_.FullName | Out-File $LogFile -Append
    }
}