function Invoke-USMT
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string]$SourceComputer,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$DestinationComputer,
		[Parameter(Mandatory = $true)]
		[string]$USMTFilesPath,
		[switch]$Shutdown
	)
	
	begin
	{
		#Test source and destination computers are online
		Write-Verbose "Checking if source and destination are reachable..."
		if (!(Test-Connection -ComputerName $SourceComputer -Count 2))
		{
			Write-Warning -Message "Count not ping $SourceComputer"
			Break
		}
		if (!(Test-Connection -ComputerName $DestinationComputer -Count 2))
		{
			Write-Warning -Message "Count not ping $DestinationComputer"
			Break
		}
	}
	
	process
	{
		# Clean up pre-migrated SID's
		Write-Verbose "Cleaning up pre-migration SID's..."
		Invoke-Command -ComputerName $SourceComputer -ScriptBlock {
			Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\" | Select-String -pattern "S-1-5-21-817256573" |
			foreach { $_ -replace "HKEY_LOCAL_MACHINE", "HKLM:" } | remove-item -confirm:$false -recurse
		}
		
		#Copy USMT files to remote computers
		Write-Verbose "Copy USMT files to source and destination computers..."
		Try
		{
			Copy-Item -Path $USMTFilesPath -Destination "\\$SourceComputer\C$\USMTFiles" -ErrorAction Stop -Recurse -force
			Copy-Item -Path $USMTFilesPath -Destination "\\$DestinationComputer\C$\USMTFiles" -ErrorAction Stop -Recurse -force
		}
		Catch
		{
			Write-Error $_
			Break
		}
		
		# Start startscan on source
		Write-Verbose "Running USMT on source..."
		$USMT = Invoke-Command -ComputerName $SourceComputer -Scriptblock {
			c:\USMTFiles\scanstate.exe c:\usmt-data /o /c /localonly /uel:60 /i:c:\USMTFiles\migapp.xml /i:c:\USMTFiles\migdocs.xml /i:c:\USMTFiles\migbrowsers.xml /ue:usda\rs.* /ue:renamed_admin /progress:c:\USMTFiles\progress.log
		} -AsJob -JobName USMT
		
		# Get status and update screen every second
		while ($USMT.State -eq "Running")
		{
			$cols = (Get-Content "\\$SourceComputer\c$\USMTFiles\progress.log" -Tail 1 -ErrorAction Ignore) -split ","
			$Status = "{0} - {1}" -f $cols[3], $cols[4]
			[int]$Complete = $cols[4] -as [int]
			if ($Complete -gt 100) { $Complete = 100 }
			Write-Progress -Activity "Saving settings and data on $SourceComputer" -Status $Status -PercentComplete $Complete
			Start-Sleep -Seconds 1
		}
		
		# Wait for job to be completed
		$USMT | Wait-Job | Receive-Job | select -Last 2
		
		
		# Copy USMT migration data to destination computer
		Write-Verbose "Coping migration data to destination computer"
		Copy-Item -Path "\\$SourceComputer\c$\usmt-data" -Destination "\\$DestinationComputer\C$" -ErrorAction Stop -Recurse -force -container
		
		#Start loadscan on destination
		Write-Verbose "Running USMT on destination..."
		$USMT = Invoke-Command -ComputerName $DestinationComputer -Scriptblock {
			c:\USMTFiles\loadstate.exe c:\usmt-data /i:c:\USMTFiles\migapp.xml /i:c:\USMTFiles\migdocs.xml /i:c:\USMTFiles\migbrowsers.xml /c /lac /progress:c:\USMTFiles\progress.log
		} -AsJob -JobName USMT
		
		
		# Get status and update screen every second
		while ($USMT.State -eq "Running")
		{
			$cols = (Get-Content "\\$DestinationComputer\c$\USMTFiles\progress.log" -Tail 1 -ErrorAction Ignore) -split ","
			$Status = "{0} - {1}" -f $cols[3], $cols[4]
			[int]$Complete = $cols[4] -as [int]
			if ($Complete -gt 100) { $Complete = 100 }
			Write-Progress -Activity "Restoring settings and data on $DestinationComputer" -Status $Status -PercentComplete $Complete
			Start-Sleep -Seconds 1
		}
		# Wait for job to be completed
		$USMT | Wait-Job | Receive-Job | select -Last 2
		
	}
	
	end
	{
		#Remove USMT files on remote computers
		Write-Verbose "Cleaning up USMT files on source and destination..."
		Remove-Item \\$SourceComputer\C$\USMTFiles -Force -Recurse
		Remove-Item \\$SourceComputer\C$\usmt-data -Force -Recurse
		Remove-Item \\$DestinationComputer\C$\USMTFiles -Force -Recurse
		Remove-Item \\$DestinationComputer\C$\usmt-data -Force -Recurse
		
		# Shutdown both computers if flag was set
		if ($Shutdown)
		{
			Stop-Computer $SourceComputer -Force
			Stop-Computer $DestinationComputer -Force
		}
	}
}


# Get computers from user via manual input
$SourceComputer = Read-Host "Enter source computer name"
$DestinationComputer = Read-Host "Enter destination computer name"
$ShutdownResponse = Read-Host "Shutdown computers after data is transferred? (y/n)"

if ($ShutdownResponse -eq 'y') { Invoke-USMT $SourceComputer $DestinationComputer -USMTFilesPath "\\sjvasc\files\IT\Public\USMT" -Verbose -Shutdown }
else { Invoke-USMT $SourceComputer $DestinationComputer -USMTFilesPath "\\sjvasc\files\IT\Public\USMT" -Verbose }
