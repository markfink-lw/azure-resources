<#
  .SYNOPSIS
  Performs a batch deployment of the Lacework Data Collector to Linux VMs in Azure.

  .DESCRIPTION
  The Deploy-LW-Linux.ps1 script installs the Lacework Data Collector to all Linux VMs it finds in a list
  of Azure resource groups provided as a parameter.  It depends on the install.sh script you can download
  in your Lacework account in Settings->Agents.

  The results are output as an object to the pipe.  Because errors tend to be long, you should capture the
  results to a variable or at least add " | format-list" after the command for readability.

  .PARAMETER ResourceGroups
  A list of Azure resource groups in which to look for Linux VMs to install the Collector.

  .PARAMETER EnableExtensions
  If extension operations are disabled on a target Azure VM, then we will enable extension operations on the VM
  and install the Collector.  Default is false, in which case the Collector is not installed and the script
  proceeds to the next VM.

  .PARAMETER InstallScript
  A URL for install.sh that is accessible from the target Azure VMs.  install.sh contains your Lacework token
  so you should post it in a secure place, like a private Azure Storage container.

  .PARAMETER Endpoint
  The Lacework endpoint to send data to.  Choice is either api.lacework.net or api.fra.lacework.net.  The script
  defaults to api.lacework.net.
#>

Param (
    [Parameter(Mandatory=$true)][string[]]$ResourceGroups,
    [switch]$EnableExtensions,
    [Parameter(Mandatory=$true)][string]$InstallScript,
    [string]$Endpoint = "api.lacework.net"
)

[string[]]$validEndpoints = "api.lacework.net", "api.fra.lacework.net"

If ( -Not ($Endpoint -In $validEndpoints) ) {
    Write-Error ("Invalid Lacework endpoint.  Must be one of the following:`n" + ($validEndpoints -join "`n"))
    Exit 1
}

$extSettings = @{
    "fileUris"         = @($InstallScript)
    "commandToExecute" = "./install.sh -U https://$Endpoint"
}

$result = ""

ForEach ( $rg In $ResourceGroups ) {
    $linuxVMs = Get-AzVM -ResourceGroupName $rg -Status | Where {`
        $_.PowerState -eq "VM running" -and `
        $_.OSProfile.LinuxConfiguration
    }

    ForEach ( $vm In $linuxVMs ) {
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
            # This will throw an error if it doesn't find the extension.
            # This differs from Get-AzVMCustomScriptExtension with Windows.
            $ext = Get-AzVMExtension `
                -ResourceGroupName $rg `
                -VMName $vm.Name `
                -Name LaceworkDC `
                -ErrorAction Ignore
            If ( $ext.ProvisioningState -eq "Succeeded" ) {
                $result.Success = $true
                $result.Reason = "Extension is already installed."
                Continue
            }
        }

        Try {
            Set-AzVMExtension `
                -ResourceGroupName $vm.ResourceGroupName `
                -VMName $vm.Name `
                -Type "customScript" `
                -Publisher "Microsoft.Azure.Extensions" `
                -TypeHandlerVersion "2.1" `
                -Name LaceworkDC `
                -ProtectedSettings $extSettings `
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
