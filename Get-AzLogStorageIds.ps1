<#
  .SYNOPSIS
  Output the Azure Storage account(s) where Activity Logs are sent for Azure subscriptions.

  .DESCRIPTION
  Iterates through Azure subscriptions that the user has access to and outputs the Azure Storage account(s) where
  Activity Logs are sent for each subscription (if they are sent to Azure Storage).

  This is useful for understanding the current configuration before applying the Lacework Azure integration.

  This depends on the Powershell Az modules and that your Powershell environment is authenticated to Azure with an
  appropriate user account.  It just reads the existing configuration; it changes nothing.
#>

ForEach ($sub In Get-AzSubscription -WarningAction SilentlyContinue) {
    $output = "" | Select-Object SubscriptionName, SubscriptionId, LogStorageId
    $output.SubscriptionName = $sub.Name
    $output.SubscriptionId = $sub.Id

    ForEach ($diag In Get-AzDiagnosticSetting `
                        -SubscriptionId $sub.SubscriptionId `
                        -WarningAction SilentlyContinue `
                        -ErrorAction SilentlyContinue) {
        If ($diag.StorageAccountId) {
            $output.LogStorageId = $diag.StorageAccountId
            Write-Output $output
        }
    }

    If (-Not $output.LogStorageId) {
        $output.LogStorageId = "None"
        Write-Output $output
    }
}
