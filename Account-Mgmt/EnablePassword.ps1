#Requires -RunAsAdministrator
<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.165
	 Created on:   	9/10/2019 1:05 PM
	 Created by:   	Jeff Wiens
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Enables registry setting to allow password login.
#>

$HostName = Read-Host "Enter a computer name"
Write-Host "Confirming that computer is online..." -ForegroundColor Green
$HostUp = Test-Connection -ComputerName $HostName -Count 1 -ErrorAction SilentlyContinue
if (-not $HostUp)
{
	Write-Host "Remote computer not available.  Terminating." -ForegroundColor Red
	exit 1
}
else
{
	Write-Host "Remote computer was pinged successfully." -ForegroundColor Green
}

Write-Host "Attempting to set registry to enable password logon..."

try
{
	$reghive = [Microsoft.Win32.RegistryHive]::LocalMachine
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($reghive, $HostName)
	$key = $reg.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system", $true)
	$key.SetValue("scforceoption", 0)
	$key.Close()
	$reg.Close()
}
catch
{
	Write-Host "Failed to set registry on remote computer." -ForegroundColor Red
	exit 2	
}

Write-Host "Succesfully set registry to allow password logon." -ForegroundColor Green