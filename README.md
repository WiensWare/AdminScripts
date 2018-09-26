# AdminScripts
This is my collection of scripts and tools that I use on a monthly basis.  It is geared towards Windows system administrators.

## Subject Matter
* User account management - Creation, modification, deletion, and audit
* Computer account management - Audit
* Windows 10 - Updating computer build images with the lastest security updates

## Scripts
* ComputerReport.ps1 - Generates a report of computer objects from active directory.  Useful for inventory and deleting stale objects.
* CreateHomeDirectory.ps1 - Creates a user's network-based home directory on a remote server.
* patch-wim.ps1 - Updates a Windows 10 WIM file with patches downloaded from Microsoft.
* UserReport.ps1 - Creates CSV of user account info.  Useful for auditing inactive accounts.
* Invoke-USMT.ps1 - Remotely runs USMT (User State Migrtion Tool) on a source and destination computer.
* Find-BigOldFiles.ps1 - Generates a report on large and old files.  (i.e. the ones that need to be cleaned up!)
* GetPathSize.ps1 - Generates a spreadsheet of specified directories and sizes
* Update-Servers.ps1 - Applies Microsoft patches to a group of servers and schedules a reboot
* Update-Computer.ps1 - Applies Microsoft patches to local computer and reboots