<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
	 Created on:   	4/6/2018 10:38 AM
	 Created by:   	Jeff.Wiens
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

<#
	.SYNOPSIS
		Gets the total size of files in a directory
	
	.DESCRIPTION
		Gets the total size of files in a directory
	
	.PARAMETER Path
		Path of directory to get size
	
	.EXAMPLE
				PS C:\> Get-DirectorySize c:\temp
	
	.NOTES
		Additional information about the function.
#>
function Get-DirectorySize
{
	[CmdletBinding()]
	[OutputType([long])]
	param
	(
		$Path
	)
	
	[long]$dirSize = 0L;
	
	# Write debug info
	Write-Verbose $Path
	
	# Cycle through all directories calling function recurisvely
	$dirs = Get-ChildItem -Path $Path -Directory
	foreach ($dir in $dirs)
	{
		$dirSize += Get-DirectorySize -Path $dir.FullName
	}
	
	# Get length of files in current directory
	$files = Get-ChildItem -Path $Path -File
	foreach ($file in $files)
	{
		$dirSize += $file.Length
	}
	
	$dirSize
}


$RootPath = Read-Host "Enter input path"
$OutputPath = Read-Host "Enter output CSV path"

Remove-Item -Path $OutputPath -ErrorAction Ignore
New-Item -Path $OutputPath

# Get directory specified
$dirs = Get-ChildItem -Path $RootPath -Directory
foreach ($dir in $dirs)
{
	# Get directory size
	$dirSize = Get-DirectorySize -Path $dir.FullName -Verbose
	
	# Create object 
	$object = New-Object -TypeName PSObject
	$object | Add-Member -MemberType NoteProperty -Name "Path" -Value $dir.FullName
	$object | Add-Member -MemberType NoteProperty -Name "Size" -Value $dirSize
	
	Export-Csv -NoTypeInformation -Append -InputObject $object -Path $OutputPath
}