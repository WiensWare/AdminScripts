#Requires -module ActiveDirectory

# Generates a CSV file containing all user accounts and related info
# Useful to audit inactive accounts



<#
.Synopsis
   Lists all users in an AD OU
.DESCRIPTION
   Searches the specified OU for all user names that match the provided filter
.EXAMPLE
   Get-ComputerFromOU -OU "OU=Users,OU=HR,DC=example,DC=net"
.INPUTS
   AD OU Path
.OUTPUTS
   String array of computer names   
#>
function Get-UserFromOU
{
    [CmdletBinding()]
    [OutputType([string[]])]
    Param
    (
        # Org Unit to get user from
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $OU,

        # Filter of user names
        [string]
        $Filter="*"
    )

    Get-ADUser -SearchBase $OU -Filter {Name -like $Filter} -Properties *
}




# Get list of all computers in Server OU
$Users = Get-UserFromOU -OU "OU=Users,OU=HR,DC=example,DC=net"

# Export user account info to CSV file
$Users | Select DisplayName, EmailAddress, SmartcardLogonRequired, LastLogonDate, PasswordLastSet, UserPrincipalName, Enabled, Description | sort LastLogonDate | Export-Csv -NoTypeInformation -Path "Users.csv"

# Open the CSV file (usually in Excel)
Invoke-Item "users.csv"

