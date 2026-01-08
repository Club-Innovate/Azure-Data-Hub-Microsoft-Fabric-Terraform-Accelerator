<#
.SYNOPSIS
  Creates a Microsoft Fabric Lakehouse in the specified workspace using the Fabric REST API.
.DESCRIPTION
  This script is invoked from Terraform (null_resource local-exec) as part of the fabric_lakehouse module.
  It requires:
    - Azure CLI (`az`) installed and on PATH
    - Service Principal (Fabric-SPA) added as Contributor to the workspace
    - The Fabric API endpoint to be available in your tenant
  NOTE: The Fabric REST APIs evolve; treat this as a template and validate against current Microsoft documentation before production use.
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$TenantId,
  [Parameter(Mandatory=$true)]
  [string]$ClientId,
  [Parameter(Mandatory=$true)]
  [string]$ClientSecret,
  [Parameter(Mandatory=$true)]
  [string]$WorkspaceId,
  [Parameter(Mandatory=$true)]
  [string]$LakehouseName,
  [Parameter(Mandatory=$false)]
  [string]$ApiVersion = "2023-11-01",
  [Parameter(Mandatory=$false)]
  [bool]$CreateAndRunNotebook = $true # You would need to add some code to upload a .csv file to the Files folder within the Lakehouse, before you can set to true.
)

# ================================
# 1. Get Access Token from Microsoft Entra ID
# ================================
Write-Host "Requesting access token..." -ForegroundColor Cyan

$tokenResponse = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id     = $ClientId
        scope         = "https://api.fabric.microsoft.com/.default"
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
    }

if (-not $tokenResponse.access_token) {
    Write-Host "Failed to obtain access token." -ForegroundColor Red
    exit 1
}

$accessToken = $tokenResponse.access_token
Write-Host "Access token acquired." -ForegroundColor Green

# ================================
# Check if Lakehouse already exists
# ================================
function Get-ExistingLakehouse {
    param(
        [string]$WorkspaceId,
        [string]$LakehouseName,
        [string]$AccessToken,
        [string]$ApiVersion = "2023-11-01"
    )
    $uri = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/lakehouses?api-version=$ApiVersion"
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{ Authorization = "Bearer $AccessToken" }
        foreach ($lakehouse in $response.value) {
            if ($lakehouse.displayName -eq $LakehouseName) {
                return $true
            }
        }
        return $false
    } catch {
        Write-Host "Error checking for existing Lakehouse: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

if (Get-ExistingLakehouse -WorkspaceId $WorkspaceId -LakehouseName $LakehouseName -AccessToken $accessToken -ApiVersion $ApiVersion) {
    Write-Host "Lakehouse '$LakehouseName' already exists in workspace '$WorkspaceId'. Skipping creation." -ForegroundColor Yellow
    return
}

# ================================
# 2. Create Lakehouse via REST API
# ================================
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/lakehouses?api-version=$ApiVersion"

# Generate a valid Lakehouse ID (lowercase, only letters, numbers, underscores, starts with letter)
$LakehouseId = $LakehouseName.ToLower() -replace '[^a-z0-9_]', '_' -replace '_+', '_' -replace '^_|_$',''
if ($LakehouseId -eq '') {
  $LakehouseId = 'lakehouse'
}
if ($LakehouseId -notmatch '^[a-z]') {
  $LakehouseId = 'lh_' + $LakehouseId
}

# Use underscores in display name for consistency
$LakehouseDisplayName = $LakehouseId
$LakehouseDescription = "Lakehouse created via PowerShell script"

$body = @{
    displayName = $LakehouseDisplayName
    description = $LakehouseDescription
    lakehouseSchema = @{
      enabled = $true
    }
} | ConvertTo-Json -Depth 10

Write-Host "Creating Lakehouse '$LakehouseDisplayName' (ID: $LakehouseId) in workspace '$WorkspaceId'..."
Write-Host "[DEBUG] WorkspaceId: $WorkspaceId"
Write-Host "[DEBUG] LakehouseName: $LakehouseName"
Write-Host "[DEBUG] LakehouseId: $LakehouseId"
Write-Host "[DEBUG] Request URI: $uri"
Write-Host "[DEBUG] Request Body: $body"

try {
    $response = Invoke-RestMethod -Method Post `
        -Uri $uri `
        -Headers @{ Authorization = "Bearer $accessToken" } `
        -ContentType "application/json" `
        -Body $body

    Write-Host "Lakehouse creation request sent. StatusCode: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Error creating Lakehouse:" -ForegroundColor Red
    if ($_.Exception.Response -and ($_.Exception.Response -is [System.Net.HttpWebResponse])) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Yellow
    } elseif ($_.ErrorDetails) {
        Write-Host "Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    } else {
        Write-Host "Exception: $($_ | Out-String)" -ForegroundColor Yellow
    }
    exit 1
}

# Check if the Lakehouse now exists
function Test-LakehouseExists {
    param($uri, $headers)
    try {
        $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

if (Test-LakehouseExists -uri $uri -headers @{ Authorization = "Bearer $accessToken" }) {
    Write-Host "Lakehouse '$LakehouseDisplayName' successfully created in workspace '$WorkspaceId'." -ForegroundColor Green
} else {
    Write-Host "Lakehouse '$LakehouseDisplayName' was NOT found after creation attempt." -ForegroundColor Red
    exit 1
}

# Wait for SP Contributor rights to propagate before Lakehouse creation
function Wait-ForSPPermission {
    param($WorkspaceId, $SPObjectId, $MaxWaitSeconds, $AccessToken)
    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/users"
    $elapsed = 0
    while ($elapsed -lt $MaxWaitSeconds) {
        $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken"}
        $found = $false
        foreach ($user in $resp.value) {
            if ($user.identifier -eq $SPObjectId -and $user.groupUserAccessRight -eq "Contributor") {
                $found = $true
                break
            }
        }
        if ($found) { Write-Host "SP has Contributor rights."; return }
        Write-Host "Waiting for SP Contributor rights to propagate... ($elapsed seconds)"
        Start-Sleep -Seconds 10
        $elapsed += 10
    }
    Write-Error "SP Contributor rights not found after $MaxWaitSeconds seconds."
    exit 1
}

# Example: get SP object id from environment variable or parameter (customize as needed)
$SPObjectId = $env:FABRIC_SP_OBJECT_ID
if ($SPObjectId) {
    Wait-ForSPPermission -WorkspaceId $WorkspaceId -SPObjectId $SPObjectId -MaxWaitSeconds 180 -AccessToken $accessToken
}

# After Lakehouse creation, create and run medallion notebook if enabled
if ($CreateAndRunNotebook) {
    $notebookUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath 'fabric_notebook_utils.ps1'
    . $notebookUtilsPath

    $notebookName = "Medallion-BronzeSilverGold"
    $lakehouse = (Get-WorkspaceItems -WorkspaceId $WorkspaceId | Where-Object { $_.type -eq "Lakehouse" -and $_.displayName -eq $LakehouseName } | Select-Object -First 1)
    if (-not $lakehouse) { throw "Lakehouse '$LakehouseName' not found in workspace." }
    $nb = Ensure-FabricNotebook -WorkspaceId $WorkspaceId -NotebookDisplayName $notebookName -LakehouseId $lakehouse.id -LakehouseName $lakehouse.displayName
    Write-Host "Notebook creation response:" -ForegroundColor Yellow
    Write-Host ($nb | ConvertTo-Json -Depth 10)

    # Always get notebook id from workspace items by name
    Start-Sleep -Seconds 5
    $nbItem = Get-WorkspaceItems -WorkspaceId $WorkspaceId | Where-Object { $_.type -eq 'Notebook' -and $_.displayName -eq $notebookName } | Select-Object -First 1

    if (-not $nbItem -or -not $nbItem.id) {
        throw "Notebook creation failed or notebook not found in workspace. Response: $($nb | ConvertTo-Json -Depth 10)"
    }

    Write-Host "Notebook ready. id=$($nbItem.id)"

    $params = @{}
    $result = Invoke-FabricNotebookRunAndWait -WorkspaceId $WorkspaceId -NotebookItemId $nbItem.id -Parameters $params
    Write-Host "Notebook completed. start=$($result.startTimeUtc) end=$($result.endTimeUtc) status=$($result.status)"
}