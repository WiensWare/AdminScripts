#Requires -module ActiveDirectory

# Generates a report of computer account info.
# Mostly useful to make sure that inactive computer accounts are removed from active directory.
# Could also be used to see OS version inventory.

<#
.Synopsis
   Lists all users in an AD OU
.DESCRIPTION
   Searches the specified OU for all user names that match the provided filter
.EXAMPLE
   Get-ComputerFromOU -OU "OU=Computers,OU=HR,DC=example,DC=net" -Filter "ARSCAPAR3*"
.EXAMPLE
   Get-ComputerFromOU -OU "OU=Computers,OU=HR,DC=example,DC=net"
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

    Get-ADComputer -SearchBase $OU -Filter {Name -like $Filter} -Properties *
}




# Get list of all computers in Server OU
$Computers = Get-ComputerFromOU -OU "OU=Computers,OU=HR,DC=example,DC=net"

# Export list to csv file
$Computers | select Name, DistinguishedName, LastLogonDate, Enabled, Created, OperatingSystemVersion | sort LastLogonDate | Export-Csv -NoTypeInformation -Path "computers.csv"

# Now open the csv file (usually in Excel)
Invoke-Item "computers.csv"
