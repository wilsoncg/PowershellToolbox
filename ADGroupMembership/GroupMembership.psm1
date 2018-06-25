Function Get-GroupMembership {
<#
  .SYNOPSIS
  Searches active directory for a user and outputs the groups the user is a member of.
  .DESCRIPTION
  Searches active directory for a user and outputs the groups the user is a member of.
  .EXAMPLE
  PS> Get-GroupMembership
  Gets the AD group membership of the current user.
  .EXAMPLE
  PS> Get-GroupMembership martin.bell
  .EXAMPLE
  PS> Get-GroupMembership martin.bell | Sort -Property 'Name' | FT -Property ('Name','GroupCategory','GroupScope')
  .EXAMPLE
  PS> Get-GroupMembership martin.bell -domain GC
  .PARAMETER username
  The user name to search for.
  .PARAMETER domain
  The domain to search.
#>

Param(
	[Parameter(Mandatory=$false)]
	[string]$username,
	[Parameter(Mandatory=$false)]
	[string]$domain
)

if (-not $username) {
    $a = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -match '(?<domain>[^\\]*)\\(?<username>.*)'
    $username = ($Matches['username'])
    $domain = ($Matches['domain'])
}

if ($domain) {
    $server = Get-Random -InputObject (Get-ADDomainController -DomainName $domain -Discover).Hostname
}


if (-not $server) {
    Get-ADUser $username -Properties @('MemberOf') | %{$_.MemberOf} | Get-ADGroup 
} else {
    Get-ADUser $username -Properties @('MemberOf') -Server $server | %{$_.MemberOf} | Get-ADGroup -Server $server
}
return
}
