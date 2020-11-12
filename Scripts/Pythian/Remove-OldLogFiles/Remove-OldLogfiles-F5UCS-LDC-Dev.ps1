$Folder = "E:\F5 Data\F5 backups\LDC_DEV"

#Delete files older than 6 months
Get-ChildItem $Folder -Recurse -Force -ea 0 |
? {!$_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-180)} |
ForEach-Object {
   $_ | del -Force
   $_.FullName | Out-File C:\Pythian\Remove-OldLogfiles\F5-LDC-Dev-deletedlog.txt -Append
}

#Delete empty folders and subfolders
Get-ChildItem $Folder -Recurse -Force -ea 0 |
? {$_.PsIsContainer -eq $True} |
? {$_.getfiles().count -eq 0} |
ForEach-Object {
    $_ | del -Force
    $_.FullName | Out-File C:\Pythian\Remove-OldLogfiles\F5-LDC-Dev-deletedlog.txt -Append
}