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