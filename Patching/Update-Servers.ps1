#Requires -module ActiveDirectory

<#
.Synopsis
   Lists all computers in an AD OU
.DESCRIPTION
   Searches the specified OU for all computer names that match the provided filter
.EXAMPLE
   Get-ComputerFromOU -OU "OU=Servers,OU=Computers,OU=2034,OU=PWA,OU=ARS,OU=Agencies,DC=usda,DC=net" -Filter "ARSCAPAR3*"
.EXAMPLE
   Get-ComputerFromOU -OU "OU=Servers,OU=Computers,OU=2034,OU=PWA,OU=ARS,OU=Agencies,DC=usda,DC=net"
.INPUTS
   AD OU Path
.OUTPUTS
   String array of computer names   
#>
function Get-ComputerFromOU
{
    [CmdletBinding()]
    [OutputType([string[]])]
    Param
    (
        # Org Unit to get computers from
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $OU,

        # Filter of computer names
        [string]
        $Filter="*"
    )

    Get-ADComputer -SearchBase $OU -Filter {Name -like $Filter} | Select-Object @{N='ComputerName'; E={$_.DNSHostName}} | Sort-Object ComputerName
}


<#
.Synopsis
   Is computer online?
.DESCRIPTION
   Tests to see if a computer is online.
.INPUTS
   The computer name or piped computer names
.OUTPUTS
   Array of computer name and boolean status if online or offline
.EXAMPLE
   Test-ComputerOnline ComputerA
.EXAMPLE
   Get-ComputerFromOU -OU "OU=Servers,OU=Computers,OU=2034,OU=PWA,OU=ARS,OU=Agencies,DC=usda,DC=net" -Filter "ARSCAPAR3*" | Test-ComputerOnline   
#>
function Test-ComputerOnline
{
    [CmdletBinding()]
    Param
    (
        # Computer Name or Array of Names
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$True,
                   Position=0)]
        [string]
        $ComputerName
    )

    begin
    {
    }

    process
    {
        $Result = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
        
        $props = @{ComputerName=$ComputerName
                   Online=$Result }
        $obj = New-Object -TypeName PSObject -Property $props
        Write-Output $obj
    }

    end
    {
    }
}


<#
.Synopsis
   Remotely installs a module
.DESCRIPTION
   Installs a module that exists on the local system, to the remote system
.EXAMPLE
   Install-Module -Module PSWindowsUpdate -ComputerName ComputerX
.EXAMPLE
   Install-Module -Module PSWindowsUpdate -ComputerName ComputerX -Destination "C$\Program Files\WindowsPowerShell\Modules"
#>
function Install-Module
{
    [CmdletBinding()]
    Param
    (
        # Computer name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ComputerName,

        # Module name
        [Parameter(Mandatory=$true)]
        $Module,

        # Destination for where to install module
        [string]
        $Destination = "C$\Program Files\WindowsPowerShell\Modules"
    )

    Process
    {
        if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)
        {
            # Import module so we can get info
            Import-Module $Module
        
            # Create path to directory containing module
            $ModuleObject = Get-Module -Name $Module
            $ModulePath = $ModuleObject.Path -split "\\"
            $Length = $ModulePath.Length -1
            $fullpath = ""
            for($x=0; $x -lt $Length; $x++)
            {
                $fullpath += $ModulePath[$x] + "\"
            }
            Write-Verbose "Path of Module $Module is $fullpath"
        
            $DestDirectory = "\\$ComputerName\$Destination"
            Write-Verbose "Destination directory is $DestDirectory"

            Copy-Item -Path $fullpath -Destination $DestDirectory -Recurse -Force
        }
    }
}


<#
.Synopsis
   Registers Microsoft Update
.DESCRIPTION
   Reigsters the Microsoft Update source on the remote computer so it can receive all Microsoft updates (not just Windows updates)
.EXAMPLE
   Set-MicrosoftUpdate -ComputerName ComputerA
#>
function Set-MicrosoftUpdate
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ComputerName
    )

    Begin
    {
        $Script = {Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -Confirm:$false}
    }
    Process
    {
        if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)
        {
            Write-Verbose "Registering remote system $ComputerName with Microsoft Update..."
            $job = Invoke-Command -ComputerName $ComputerName -ArgumentList $MicrosoftUpdate -ScriptBlock $Script -AsJob -JobName $ComputerName
        }
    }
    End
    {
        Write-Verbose "Waiting for all jobs to complete..."
        while(Get-Job -State Running)
        {
            Start-Sleep -Seconds 1
        }
        Write-Verbose "All jobs complete!"
    }
}


<#
.Synopsis
   Updates a remote computer
.DESCRIPTION
   Performs a full Microsoft update on a remote computer and reboots
.EXAMPLE
   Update-Computer -ComputerName ComputerA
#>
function Update-Computer
{
    [CmdletBinding()]
    Param
    (
        # Name of remote computer
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $ComputerName
    )

    Begin
    {
    }
    Process
    {
        if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)
        {
            Write-Verbose "Invoking windows update on $ComputerName"
            $Script = { Import-Module PSWindowsUpdate; Get-WUInstall -AcceptAll -MicrosoftUpdate | Out-File "c:\PSWindowsUpdate.log"}
            Invoke-WUInstall -ComputerName $ComputerName -Script $Script -Confirm:$false            
        }
        else
        {
            Write-Error "Computer $ComputerName was offline.  Not updated."
        }
    }
    End
    {
    }
}


<#
.Synopsis
   Schedules a remote computer reboot
.DESCRIPTION
   Creats a job on a remote computer to reboot at a specificed time
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-Reboot
{
    [CmdletBinding()]
    Param
    (
        # Computer Name or Array of Names
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$True,
                   Position=0)]
        [string]
        $ComputerName,

        # Date and Time to reboot the computer
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$False,
                   Position=1)]
        [DateTime]
        $RebootTime
    )

    process
    {
        $Now = Get-Date
        $span = ([TimeSpan]($RebootTime - $Now)).TotalSeconds
        [Int32]$Seconds = $span
        Write-Verbose "Rebooting $ComputerName at $RebootTime (in $Seconds seconds)"
        shutdown /r /m $ComputerName /t $Seconds
    }
}





# Get list of all computers in Server OU
$Computers = Get-ComputerFromOU -OU "OU=Servers,OU=Computers,OU=XXXX,DC=example,DC=com"

$SelectedComputers = $Computers | Test-ComputerOnline | Out-GridView -Title "Select Computers to Update" -OutputMode Multiple | Select ComputerName

# Install PSWindowsUpdate on all computers
$SelectedComputers | Install-Module -Module PSWindowsUpdate

# Register Microsoft Update
$SelectedComputers | Set-MicrosoftUpdate

# Do updates
$SelectedComputers | Update-Computer -Verbose

# Schedule reboot
$SelectedComputers | Set-Reboot -RebootTime "11:00pm" -Verbose