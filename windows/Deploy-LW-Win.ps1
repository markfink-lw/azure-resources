<#
  .SYNOPSIS
  Performs a batch deployment of the Lacework Data Collector to Windows VMs in Azure.

  .DESCRIPTION
  The Deploy-LW-Win.ps1 script installs the Lacework Data Collector to all Windows VMs it finds in a list
  of Azure resource groups provided as a parameter.  It depends on the Install-LWCollector.ps1 script.

  The results are output as an object to the pipe.  Because errors tend to be long, you should capture the
  results to a variable or at least add " | format-list" after the command for readability.

  .PARAMETER ResourceGroups
  A list of Azure resource groups in which to look for Windows VMs to install the Collector.

  .PARAMETER EnableExtensions
  If extension operations are disabled on a target Azure VM, then we will enable extension operations on the VM
  and install the Collector.  Default is false, in which case the Collector is not installed and the script
  proceeds to the next VM.

  .PARAMETER InstallScript
  A URL for Install-LWCollector.ps1 that is accessible from the target Azure VMs.

  .PARAMETER Vault
  The name of an Azure Key Vault that contains a secret for the Lacework token.

  .PARAMETER TokenSecret
  The name of a secret in the Azure Key Vault for the Lacework token.

  .PARAMETER Endpoint
  The Lacework endpoint to send data to.  Choice is either api.lacework.net or api.fra.lacework.net.  The script
  defaults to api.lacework.net.

  .PARAMETER MsiInstaller
  A URL or local file path (relative to the target Azure VMs) for the Lacework MSI installer.  This will most
  likely be a URL.

  .PARAMETER Defender
  Exclude the Data Collector from scanning with Defender.  Defaults to false.  This depends on and checks for
  the Defender Powershell module on the target Azure VMs (we will not install the module if it is not present).
#>

Param (
    [Parameter(Mandatory=$true)][string[]]$ResourceGroups,
    [switch]$EnableExtensions,
    [string]$InstallScript = "https://raw.githubusercontent.com/markfink-lw/azure-resources/master/windows/Install-LWCollector.ps1",
    [Parameter(Mandatory=$true)][string]$Vault,
    [Parameter(Mandatory=$true)][string]$TokenSecret,
    [string]$Endpoint = "api.lacework.net",
    [Parameter(Mandatory=$true)][string]$MsiInstaller,
    [switch]$Defender
)

[string[]]$validEndpoints = "api.lacework.net", "api.fra.lacework.net"

If ( -Not ($Endpoint -In $validEndpoints) ) {
    Write-Error ("Invalid Lacework endpoint.  Must be one of the following:`n" + ($validEndpoints -join "`n"))
    Exit 1
}

$token = Get-AzKeyVaultSecret -VaultName $Vault -Name $TokenSecret -AsPlainText -ErrorAction Stop 

# If TokenSecret does not exist, the above does not throw an error; it simply returns nothing.
If ( -Not $token ) {
    Write-Error "Failed to retrieve the Lacework token.  Check the value of TokenSecret."
    Exit 1
}

$command = "Install-LWCollector.ps1 -Token $token -Endpoint $Endpoint -MsiInstaller $MsiInstaller"
If ( $Defender ) { $command += " -Defender" }

$result = ""

ForEach ( $rg In $ResourceGroups ) {
    $windowsVMs = Get-AzVM -ResourceGroupName $rg -Status | Where {`
        $_.PowerState -eq "VM running" -and `
        $_.OSProfile.WindowsConfiguration
    }

    ForEach ( $vm In $windowsVMs ) {
        Write-Output $result

        $result = "" | Select-Object ResourceGroupName, Name, Success, Reason
        $result.ResourceGroupName = $vm.ResourceGroupName
        $result.Name = $vm.Name

        If ( -Not $vm.OSProfile.AllowExtensionOperations ) {
            If ( $EnableExtensions ) {
                $vm.OSProfile.AllowExtensionOperations = $true
                Try { $vm | Update-AzVM -ErrorAction Stop | Out-Null }
                Catch {
                    $result.Success = $false
                    $result.Reason = $error[0].Exception.Message
                    Continue
                }
            }
            Else {
                $result.Success = $false
                $result.Reason = "Extension operations are disabled."
                Continue
            }
        }
        Else {
            $ext = Get-AzVMCustomScriptExtension `
                -ResourceGroupName $rg `
                -VMName $vm.Name `
                -Name LaceworkDC
            If ( $ext.ProvisioningState -eq "Succeeded" ) {
                $result.Success = $true
                $result.Reason = "Extension is already installed."
                Continue
            }
        }

        Try {
            Set-AzVMCustomScriptExtension `
                -VMObject $vm `
                -Location $vm.Location `
                -FileUri $InstallScript `
                -Run $command `
                -Name LaceworkDC `
                -SecureExecution `
                -ErrorAction Stop | Out-Null

            $result.Success = $true
            $result.Reason = "Installed extension successfully."
        }
        Catch {
            $result.Success = $false
            $result.Reason = $error[0].Exception.Message
        }
    }
    Write-Output $result
}
