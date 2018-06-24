#Requires -Modules ActiveDirectory

### This script creates a user's home directory on a remote file server.
### It assumes that the script is run with sufficient permissions to
###    1. Create the Directory
###    2. Change the permissions and ownership of the directory

# Read configuration from CSV file (expected to be in same directory as this script)
$Config = Import-Csv "$PSScriptRoot\CreateHomeDirectory.csv"

# Path to use when creating a home directory.  *** CUSTOMIZE FOR YOUR NEEDS IF NOT USING CSV FILE ***
$ServerPath = $Config.ServerPath

# Domain to search for username in.  *** CUSTOMIZE FOR YOUR NEEDS IF NOT USING CSV FILE ***
$Domain = $Config.Domain

# Ask for the username of the directory be created
$Username = Read-Host -Prompt "Please enter the user name in the format first.last"

# Change the case of the username to this format:  "First.Last"
# This makes the home directory look a bit nicer.
$Username = (Get-Culture).TextInfo.ToTitleCase($Username)

# Create the full directory path
$FullDirPath = "$ServerPath\$Username"

# Validate the username by attemping to read it from the active directory
Write-Verbose "Validating that $Domain\$Username exists in the active directory"
$User = Get-ADUser -Identity "$Domain\$Username"
if ($User-eq $null) 
{
    Write-Error "User $Username doesn't exist in the active directory.  No directory created."
}

# Validate that the directory doesn't already exist
if (Test-Path $FullDirPath)
{
    Write-Error "Path $FullDirPath already exists.  No changes were made." -ErrorAction Stop
}

# Attempt to create the directory
Write-Verbose "Attempting to create $FullDirPath for $Domain\$Username"
New-Item -Path $FullDirPath -ItemType Directory -Confirm -ErrorAction Stop

# Create an acess rule
$FileSystemAccessRights = [System.Security.AccessControl.FileSystemRights]::FullControl
$InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::"ContainerInherit", "ObjectInherit"
$PropagationFlags = [System.Security.AccessControl.PropagationFlags]::None
$AccessControl =[System.Security.AccessControl.AccessControlType]::Allow
$NewAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($User, $FileSystemAccessRights, $InheritanceFlags, $PropagationFlags, $AccessControl)

# Get current ACL on directory, modify it, and write it back
$CurrentACL = Get-ACL -path $FullDirPath
$CurrentACL.SetAccessRule($NewAccessrule)
$CurrentACL.SetOwner($User)
Set-ACL -path $FullDirPath -AclObject $currentACL

# Notify user everything is done
Write-Verbose "Directory $FullDirPath was created and permissions set appropriately."