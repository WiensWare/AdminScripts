#Requires -RunAsAdministrator

# Ensure that we can find the local module PSWindowsUpdate
$env:PSModulePath = "$env:PSModulePath;$PSScriptRoot"

$MicrosoftUpdateID = '7971f918-a847-4430-9279-4a52d1efe18d'

Write-Verbose 'Making sure that Microsoft Update is registered'
$UpdateServiceManager = Get-WUServiceManager | Where-Object ServiceID -EQ $MicrosoftUpdateID
if(!$UpdateServiceManager)
{
    Write-Verbose 'Microsoft Update is NOT registered.'
    Write-Verbose 'Registering Microsoft Update provider...'
    $status = Add-WUServiceManager -ServiceID $MicrosoftUpdateID -Confirm:$false
    Write-Verbose 'Microsoft Update is now registered.'
}
else
{
    Write-Verbose 'Microsoft Update is already registered.'
}

Write-Verbose 'Downloading and installing all updates.  Will reboot if necessary.  Please wait...'
Install-WindowsUpdate -UpdateType Software -MicrosoftUpdate -AutoSelectOnly -AutoReboot