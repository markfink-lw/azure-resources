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
    $output = "" | Select-Object Subscription, LogStorage
    $output.Subscription = $sub.Name

    ForEach ($diag In Get-AzDiagnosticSetting -SubscriptionId $sub.SubscriptionId -WarningAction SilentlyContinue) {
        If ($diag.StorageAccountId) {
            $output.LogStorage = $diag.StorageAccountId
            Write-Output $output
        }
    }

    If (-Not $output.LogStorage) {
        $output.LogStorage = "None"
        Write-Output $output
    }
}
