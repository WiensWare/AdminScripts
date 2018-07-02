#Requires -module ActiveDirectory

# This script adds the SIP: tag to the user's proxy address in active directory.
# It is primarily useful so that Skype for Business can autoconfigure the user's account.
# Experimental.  Not used in production.

function Get-UserFromOU
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

        # Filter of user names
        [string]
        $Filter="*"
    )

    Get-ADUser -SearchBase $OU -Filter {Name -like $Filter} -Properties *
}




# Get list of all user accounts
$Users = Get-UserFromOU -OU "OU=Admin,OU=Users,OU=TestOU1,DC=example,DC=com"

# Go through all users and add the SIP record
foreach ($User in $Users)
{
	Write-Host $User.SamAccountName
	
	$SIP = "SIP:" + $User.SamAccountName + '@example.com'
	$User.proxyAddresses += $SIP
	
	foreach ($Address in $User.proxyAddresses)
	{
		Write-Host $Address
	}
	Write-Host $SIP
	
	Set-ADUser -Instance $User
}


