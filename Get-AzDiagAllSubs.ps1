ForEach ($sub In Get-AzSubscription) {
    $output = "" | Select-Object Subscription, LogStorage
    ForEach ($diag In Get-AzDiagnosticSetting -SubscriptionId $sub.SubscriptionId -WarningAction SilentlyContinue ) {
        If ($diag.StorageAccountId) {
            $output = "" | Select-Object Subscription, LogStorage
            $output.Subscription = $sub.Name
            $output.LogStorage = $diag.StorageAccountId
            Write-Output $output
        }
    }
    If (-Not $output.Subscription) {
        $output.Subscription = $sub.Name
        $output.LogStorage = "None"
        Write-Output $output
    }
}
