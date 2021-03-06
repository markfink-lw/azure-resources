<#
  .SYNOPSIS
  Installs the Lacework Data Collector on a Windows host.

  .DESCRIPTION
  The Install-LWCollector.ps1 script installs the Lacework Data Collector and adds a local firewall rule to allow the
  Collector to communicate outbound.  It can also configure a Defender exclusion for the Data Collector (see the
  defender parameter below).

  All parameters except defender are required.

  .PARAMETER Token
  A Lacework agent token that you have created in your Lacework account.

  .PARAMETER Endpoint
  The Lacework endpoint to send data to.  Choice is either api.lacework.net or api.fra.lacework.net.  The script
  defaults to api.lacework.net.

  .PARAMETER MsiInstaller
  URL or local path to use for the installer MSI file.

  .PARAMETER Defender
  Exclude the Data Collector from scanning with Defender.  Defaults to false.  This depends on and checks for the
  Defender Powershell module (we will not install the module if it is not present).
#>

Param (
    [ValidateLength(56, 56)][string]$Token = $( throw 'Lacework token is required.' ),
    [string]$Endpoint = "api.lacework.net",
    [string]$MsiInstaller = $( throw 'Lacework MSI installer URL or file path is required.' ),
    [switch]$Defender
)

[string[]]$validEndpoints = "api.lacework.net", "api.fra.lacework.net"

If ( -Not ($Endpoint -In $validEndpoints) ) {
    Write-Error ("Invalid Lacework endpoint.  Must be one of the following:`n" + ($validEndpoints -join "`n"))
    Exit 1
}

# This is safe to reinstall if it is already installed.  And it updates if we change the token or endpoint.
Start-Process msiexec.exe -Wait -ArgumentList "/I  $MsiInstaller ACCESSTOKEN=$Token SERVERURL=$Endpoint /qn"

# New-NetFirewallRule will create multiple of the same rule if this is run multiple times on the same host.
# To make this idempotent, we need to remove existing rules. This removes all rules involving LWDataCollector.
$filters = Get-NetFirewallApplicationFilter -Program "C:\Program Files\Lacework\LWDataCollector.exe" -ErrorAction Ignore
ForEach ( $filter In $filters ) {
    Remove-NetFirewallRule -AssociatedNetFirewallApplicationFilter $filter
}
New-NetFirewallRule -DisplayName "Lacework" -Direction Outbound -Program "C:\Program Files\Lacework\LWDataCollector.exe" -Action Allow | Out-Null

# Defender AV and its PS module are not installed by default on Windows Server versions prior to 2019.
If ( $Defender -and (Get-Module -ListAvailable -Name Defender) ) {
    # If the exclusion already exists, then this does nothing.  It's safe.
    Add-MpPreference -ExclusionPath "C:\Program Files\Lacework\LWDataCollector.exe"
}
