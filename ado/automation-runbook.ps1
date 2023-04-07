param
(
    [Parameter(Mandatory=$false)]
    [object] $WebhookData
)

function Get-LwApiToken([string]$lwAccount) {
    $lwApiKey = Get-AutomationVariable -Name 'LW_API_KEY'
    $lwApiSecret = Get-AutomationVariable -Name 'LW_API_SECRET'
    if (-not ($lwApiKey -and $lwApiSecret)) {
        Write-Error "Get-LwApiToken: LW_API variables are not set."
        return $null
    }
    $lwHeader = @{"X-LW-UAKS" = $lwApiSecret}
    $lwBody = @(
        @{
            "keyId" = $lwApiKey
            "expiryTime" = 30
        }
    ) | ConvertTo-Json
    $lwUri = 'https://{0}.lacework.net/api/v2/access/tokens' -f $lwAccount
    try {
        $response = Invoke-RestMethod -Uri $lwUri -Method POST -Headers $lwHeader `
            -ContentType 'application/json' -Body $lwBody
    } catch {
        Write-Error "Get-LwApiToken: $_"
        return $null
    }
    return $response.token
}

function Get-LwAlertResources([string]$lwAccount, [string]$token, [string]$eventId) {
    $lwUri = 'https://{0}.lacework.net/api/v2/Alerts/{1}?scope=Details' -f $lwAccount, $eventId
    $lwAuth = @{Authorization = 'Bearer ' + $token}
    try {
        $response = Invoke-RestMethod -Uri $lwUri -Method GET -Headers $lwAuth
    } catch {
        \
        return $null
    }
    $res = @()
    foreach ($r in $response.data.entityMap.Resource) { $res += $r.KEY.value }
    return $res
}

function Add-WorkItemDescRow([string]$label, [string]$data) {
    return @"
        <tr align="left">
          <th>$label</th>
          <td>$data</td>
        </tr>
"@
}


## MAIN ##
if (-not $WebHookData){
    Write-Error "No data received in webhook."
    exit
}

$adoPat = Get-AutomationVariable -Name 'ADO_PAT'
$adoOrg = Get-AutomationVariable -Name 'ADO_ORG'
$adoProject = Get-AutomationVariable -Name 'ADO_PROJECT'
$adoItemType = 'task'

if (-not ($adoPat -and $adoOrg -and $adoProject)) {
    Write-Error "ADO variables are not set."
    exit
}

$eventData = $webHookData.RequestBody | ConvertFrom-Json

$workItemTitle = "Alert: $($eventData.event_id) - $($eventData.event_title)"
$workItemDesc = @"
<html>
  <head>
    <style>
    table, td, th {
      border: 1px solid black;
    }
    table {
      border-collapse: collapse;
      width: 100%;
    }
    th, td {
      vertical-align: top;
    }
    </style>
  </head>
  <body> 
    <table width="1000" border="1">
"@

$workItemDesc += Add-WorkItemDescRow "Title" $($eventData.event_title)
$workItemDesc += Add-WorkItemDescRow "Link" "<a href=`"$($eventData.event_link)`">$($eventData.event_link)</a>"
$workItemDesc += Add-WorkItemDescRow "Lacework Account" $($eventData.lacework_account)
$workItemDesc += Add-WorkItemDescRow "Source" $($eventData.event_source)
$workItemDesc += Add-WorkItemDescRow "Description" $($eventData.event_description)
$workItemDesc += Add-WorkItemDescRow "Timestamp" $($eventData.event_timestamp)
$workItemDesc += Add-WorkItemDescRow "Type" $($eventData.event_type)
$workItemDesc += Add-WorkItemDescRow "ID" $($eventData.event_id)
$workItemDesc += Add-WorkItemDescRow "Severity" $($eventData.event_severity)

# This calls the LW API to retrieve resources for compliance violations.
# The LW_API_KEY and LW_API_SECRET variables must be set for a key configured in the LW account sending the webhooks.
# This implies that all webhooks processed by this runbook are coming from the same LW account.
if ($($eventData.event_type) -eq "Compliance") {
    $lwAccount = $($eventData.lacework_account).ToLower()
    $token = Get-LwApiToken $lwAccount
    if ($token) { $res = Get-LwAlertResources $lwAccount $token $($eventData.event_id) }
    if ($res) {
        $workItemDesc += Add-WorkItemDescRow "Resource" ($res -join "<br>")
    }
}

# If we find a policy in the event description, add a link to it.
$match = select-string "^.*: (lacework-global-\d+) .*$" -inputobject $($eventData.event_description)
if ($match) {
    $policy = $match.matches.groups[1].value
    $policyLink = "https://docs.lacework.com/catalog/policies/" + $policy
    $workItemDesc += Add-WorkItemDescRow "Policy" "<a href=`"$policyLink`">$policyLink</a>"
}

$workItemDesc += @"
    </table>
  </body>  
</html>
"@

# LW has 5 priorities; ADO has 4 priorities.
# So we merge LW priorities 1 and 2 (Critical and High) into one ADO priority.
$workItemPriority = $($eventData.event_severity) - 1
if ($workItemPriority -eq 0) { $workItemPriority = 1 }

$adoUri = 'https://dev.azure.com/{0}/{1}/_apis/wit/workitems/${2}?api-version=6.0' -f $adoOrg, $adoProject, $adoItemType

$adoAuthHeader = @{Authorization = 'Basic ' + `
    [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($adoPat)")) }

$adoBody = @(
    @{
        'op' = 'add'
        'value' = $workItemTitle
        'from' = 'null'
        'path' = '/fields/System.Title'
    },
    @{
        'op' = 'add'
        'value' = $workItemDesc
        'from' = 'null'
        'path' = '/fields/System.Description'
    },
    @{
        'op' = 'add'
        'value' = $workItemPriority
        'from' = 'null'
        'path' = '/fields/Microsoft.VSTS.Common.Priority'
    }
) | ConvertTo-Json

Invoke-RestMethod -Uri $adoUri -Method Patch -Headers $adoAuthHeader `
    -ContentType 'application/json-patch+json' -Body $adoBody
