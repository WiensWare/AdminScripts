<#
	.SYNOPSIS
		Gets list of people who can write to a file
	
	.DESCRIPTION
		Returns a list of people who have write permission to a file.  Excludes built-in type accounts
	
	.PARAMETER Path
		A description of the Path parameter.
	
	.EXAMPLE
				PS C:\> Get-Writers
	
	.NOTES
		Additional information about the function.
#>
function Get-Writers
{
	[CmdletBinding()]
	param
	(
		$Path
	)
	
	$perms = get-acl $Path | select -ExpandProperty Access | where {
		$_.IdentityReference -match "YOURDOMAINHERE" -and $_.AccessControlType -eq "Allow" -and $_.IdentityReference -notmatch "Server Admins"
	}
	
	# Create array to store SID's
	$sid = @()
	foreach ($perm in $perms)
	{
		# Split off the domain and return only the account name
		$sid += ($perm.IdentityReference -split '\\')[1]
	}
	
	$sid	
}


<#
	.SYNOPSIS
		Gets the specificed file info from a directory
	
	.DESCRIPTION
		Returns file information from a directory based on specifiec criteria
	
	.PARAMETER Path
		Path of directory to get size
	
	.PARAMETER OutputPath
		A description of the OutputPath parameter.
	
	.PARAMETER Age
		Age in years since last written to
	
	.PARAMETER Size
		Size in MB of file
	
	.EXAMPLE
		PS C:\> Get-DirectoryInfo c:\temp
	
	.NOTES
		Additional information about the function.
#>
function Get-DirectoryInfo
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		$Path,
		[Parameter(Mandatory = $true)]
		$OutputPath,
		$Age,
		$Size
	)
	
	# Cycle through all directories calling function recurisvely
	$dirs = Get-ChildItem -Path $Path -Directory
	foreach ($dir in $dirs)
	{
		Get-DirectoryInfo -Path $dir.FullName -OutputPath $OutputPath -Size $Size -Age $Age
	}
	
	# Get length of files in current directory
	$files = Get-ChildItem -Path $Path -File
	foreach ($file in $files)
	{
		$MaximumDate = (Get-Date).AddYears(-$Age)
		
		if (($file.Length -gt (1MB * $Size)) -and
			($file.LastWriteTime -lt $MaximumDate))
		{
			$object = New-Object -TypeName System.Management.Automation.PSObject
			$object | Add-Member -MemberType NoteProperty -Name "Directory" -Value $file.DirectoryName
			$object | Add-Member -MemberType NoteProperty -Name "Name" -Value $file.Name
			$object | Add-Member -MemberType NoteProperty -Name "Length" -Value $file.Length
			$object | Add-Member -MemberType NoteProperty -Name "Extension" -Value $file.Extension
			$object | Add-Member -MemberType NoteProperty -Name "LastwriteTime" -Value $file.LastWriteTime
			$object | Add-Member -MemberType NoteProperty -Name "Owner" -Value (Get-Acl $file.FullName).Owner
			$object | Add-Member -MemberType NoteProperty -Name "Writers" -Value (Get-Writers $file.FullName)
			
			$object | Export-Csv -NoTypeInformation -Path $OutputPath -Append
			Write-Verbose $object
		}
	}
}

$RootPath = Read-Host "Enter input path"
$OutputPath = Read-Host "Enter output CSV path"
$Age = Read-Host "Enter age in years"
$Size = Read-Host "Enter minimum file size in MB"


# Clean up output file if it exists
Remove-Item $OutputPath -ErrorAction SilentlyContinue

# Get directory specified
$dirs = Get-ChildItem -Path $RootPath -Directory
foreach ($dir in $dirs)
{
	# Get directory size
	Get-DirectoryInfo -Path $dir.FullName -Verbose -OutputPath $OutputPath  -Size $Size -Age $Age
}