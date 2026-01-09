param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    [Parameter(Mandatory=$true)]
    [string]$ClientSecret
)

$logPath = "./check_purview_debug.log"

#Write-Output "SubscriptionId: $SubscriptionId" | Out-File -Append $logPath
#Write-Output "TenantId: $TenantId" | Out-File -Append $logPath
#Write-Output "ClientId: $ClientId" | Out-File -Append $logPath

# Login with service principal
az login --service-principal -u $ClientId -p $ClientSecret --tenant $TenantId | Out-File -Append $logPath
az account set --subscription $SubscriptionId | Out-File -Append $logPath

# Get Purview accounts as JSON, filter out warnings
$purviewRaw = az purview account list --subscription $SubscriptionId --output json 2>&1
$startIndex = ($purviewRaw | Select-String '^(\[|\{)').LineNumber
if ($startIndex) {
    $purviewJson = ($purviewRaw | Select-Object -Skip ($startIndex - 1)) -join "`n"
} else {
    $purviewJson = ""
}

#Write-Output "Raw Purview JSON (filtered):" | Out-File -Append $logPath
#Write-Output $purviewJson | Out-File -Append $logPath

try {
    $purviewAccounts = $purviewJson | ConvertFrom-Json
} catch {
    $purviewAccounts = @()
}

if ($purviewAccounts) {
    Write-Output "PurviewAccounts object type: $($purviewAccounts.GetType().FullName)" | Out-File -Append $logPath
    Write-Output "PurviewAccounts count: $($purviewAccounts.Count)" | Out-File -Append $logPath
} else {
    Write-Output "PurviewAccounts is null" | Out-File -Append $logPath
}

if ($purviewAccounts -is [System.Collections.IEnumerable] -and $purviewAccounts.Count -gt 0) {
    # array case
    $firstAccount = $purviewAccounts[0]
} elseif ($purviewAccounts -and $purviewAccounts.PSObject.Properties['name']) {
    # single object case
    $firstAccount = $purviewAccounts
} else {
    $firstAccount = $null
}

if ($firstAccount) {
    Write-Output "Purview account already exists: $($firstAccount.name) in resource group $($firstAccount.resourceGroup)" | Out-File -Append $logPath
    # No longer write .auto.tfvars file, only output JSON for Terraform external data source
} else {
    Write-Output "No Purview account found. Terraform will create one." | Out-File -Append $logPath
    # No longer write .auto.tfvars file, only output JSON for Terraform external data source
}

if (-not $purviewJson) {
    Write-Output "ERROR: az purview account list returned no data. Check your login, subscription, and permissions." | Out-File -Append $logPath
}

if ($firstAccount) {
    $result = @{
        purview_exists = "true"
        purview_existing_name = "$($firstAccount.name)"
        purview_existing_rg = "$($firstAccount.resourceGroup)"
    }
} else {
    $result = @{
        purview_exists = "false"
        purview_existing_name = ""
        purview_existing_rg = ""
    }
}
$result | ConvertTo-Json -Compress