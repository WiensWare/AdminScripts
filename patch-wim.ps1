# Applies all patches in a directory to the specified WIM file.
# The intent is to keep your Windows 10 image up-to-date so that when it is applied, it's already fully patched.

$WIMPath = Read-Host "Enter full path to the WIM file"
if (!(Test-Path $WIMPath)) { Write-Host "File path is incorrect.  File does not exist."; exit; }

$MountPoint = Read-Host "Enter full path to mount point"
if (!(Test-Path $MountPoint)) { Write-Host "The mount point directory doesn't exist."; exit; }

$PatchPath = Read-Host "Enter full path to patches directory"
if (!(Test-Path $PatchPath)) { Write-Host "The patches directory doesn't exist."; exit; }

Write-Host "Mounting image..."
Mount-WindowsImage -Path $MountPoint -ImagePath $WIMPath -Index 1 | Out-Null

# Apply latest patches
Write-Host "Applying latest patches..."
$Patches = Get-ChildItem -Path $PatchPath -Filter "*.msu"
foreach($Patch in $Patches)
{
    $Patch.Name
    Add-WindowsPackage -Path $MountPoint -PackagePath $Patch.FullName | Out-Null
}

# Close WIM file and commit changes
Write-Host "Closing WIM file and commiting changes..."
Dismount-WindowsImage -Path $MountPoint -Save