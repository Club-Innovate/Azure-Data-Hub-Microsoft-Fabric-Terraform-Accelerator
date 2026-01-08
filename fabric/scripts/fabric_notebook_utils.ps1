Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FabricAccessToken {
  $token = (az account get-access-token --resource "https://api.fabric.microsoft.com" --query "accessToken" -o tsv --only-show-errors)
  if (-not $token) { throw "Failed to acquire Fabric API token via Azure CLI." }
  return $token
}

function Get-FabricHeaders {
  $token = Get-FabricAccessToken
  return @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
  }
}

function Wait-FabricOperation {
  param(
    [Parameter(Mandatory=$true)][string]$OperationUrl,
    [int]$TimeoutSeconds = 900
  )
  $headers = Get-FabricHeaders
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
    $op = Invoke-RestMethod -Method Get -Uri $OperationUrl -Headers $headers
    if ($op.status -match "Succeeded|Success") { return $op }
    if ($op.status -match "Failed") { throw ("Operation failed: " + ($op | ConvertTo-Json -Depth 50)) }
  }
  throw "Timed out waiting for operation: $OperationUrl"
}

function Get-WorkspaceItems {
  param([Parameter(Mandatory=$true)][string]$WorkspaceId)
  $headers = Get-FabricHeaders
  $uri = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items"
  return (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).value
}

function New-IpynbJsonBase64 {
  param(
    [Parameter(Mandatory=$true)][string]$LakehouseId,
    [Parameter(Mandatory=$true)][string]$LakehouseName,
    [Parameter(Mandatory=$true)][string]$WorkspaceId
  )

  function NL([string]$s) {
    return $s + "`n"
  }

  $cells = @(
    [PSCustomObject]@{
      cell_type = "markdown"
      metadata  = @{}
      source    = @(
        (NL "# Medallion pipeline (Bronze → Silver → Gold)"),
        (NL "This notebook writes data into medallion layers in a Fabric Lakehouse. It uses portable prefixed table names (no Spark CREATE SCHEMA/CREATE DATABASE) to avoid runtime restrictions.")
      )
    },
    [PSCustomObject]@{
      cell_type = "code"
      metadata  = @{}
      execution_count = $null
      outputs   = @()
      source    = @(
        (NL "# Parameters (you can override at run time via job parameters)"),
        (NL "# Place the file in this Lakehouse under Files/..."),
        (NL "file_rel_path = 'Files/patient_encounter.csv'"),
        (NL ""),
        (NL "# Use the Fabric 'Copy ABFS path' format: abfss://<workspaceId>@onelake.dfs.fabric.microsoft.com/<lakehouseId>/<path>"),
        (NL "workspace_id = '$WorkspaceId'"),
        (NL "lakehouse_id = '$LakehouseId'"),
        (NL ""),
        (NL 'source_path = f"abfss://{workspace_id}@onelake.dfs.fabric.microsoft.com/{lakehouse_id}/{file_rel_path}"'),
        (NL ""),
        (NL "# Fallback if needed"),
        (NL "fallback_path = '/lakehouse/default/' + file_rel_path"),
        (NL "print('source_path=' + source_path)"),
        (NL "print('fallback_path=' + fallback_path)"),
        (NL ""),
        (NL "# Portable medallion table names (no schemas)"),
        (NL "bronze_table = 'bronze_raw_events'"),
        (NL "silver_table = 'silver_events_clean'"),
        (NL "gold_table   = 'gold_events_daily'")
      )
    },
    [PSCustomObject]@{
      cell_type = "code"
      metadata  = @{}
      execution_count = $null
      outputs   = @()
      source    = @(
        (NL "# Helpers"),
        (NL "import re"),
        (NL ""),
        (NL "# Cleanse function to make Delta-friendly column names"),
        (NL "def cleanse_colname(colname: str) -> str:"),
        (NL "    # Only replace spaces with underscores"),
        (NL "    return re.sub(r'\\s+', '_', colname)"),
        (NL ""),
        (NL "def cleanse_df_columns(df, keep=None):"),
        (NL "    keep = set(keep or [])"),
        (NL "    for c in df.columns:"),
        (NL "        if c in keep:"),
        (NL "            continue"),
        (NL "        df = df.withColumnRenamed(c, cleanse_colname(c))"),
        (NL "    return df")
      )
    },
    [PSCustomObject]@{
      cell_type = "code"
      metadata  = @{}
      execution_count = $null
      outputs   = @()
      source    = @(
        (NL "# 1) BRONZE: ingest as-is (minimal changes) — store raw in a Delta table"),
        (NL "df_raw = (spark.read"),
        (NL "  .option('header', 'true')"),
        (NL "  .option('inferSchema', 'true')"),
        (NL "  .csv(source_path)"),
        (NL ")"),
        (NL ""),
        (NL "df_bronze_out = cleanse_df_columns(df_raw)"),
        (NL "df_bronze_out.write.mode('overwrite').format('delta').saveAsTable(bronze_table)"),
        (NL "print(f'Wrote bronze: {bronze_table}')")
      )
    },
    [PSCustomObject]@{
      cell_type = "code"
      metadata  = @{}
      execution_count = $null
      outputs   = @()
      source    = @(
        (NL "# 2) SILVER: clean/standardize/dedupe (example)"),
        (NL "from pyspark.sql import functions as F"),
        (NL ""),
        (NL "df_bronze = spark.table(bronze_table)"),
        (NL ""),
        (NL "# Example cleansing rules (adjust to your domain):"),
        (NL "df_silver = (df_bronze"),
        (NL "  .dropDuplicates()"),
        (NL ")"),
        (NL ""),
        (NL "# Clean problematic source columns but keep ingest_date stable by adding it after cleansing"),
        (NL "df_silver_clean = cleanse_df_columns(df_silver)"),
        (NL "df_silver_out = df_silver_clean.withColumn('ingest_date', F.current_date())"),
        (NL ""),
        (NL "df_silver_out.write.mode('overwrite').format('delta').saveAsTable(silver_table)"),
        (NL "print(f'Wrote silver: {silver_table}')")
      )
    },
    [PSCustomObject]@{
      cell_type = "code"
      metadata  = @{}
      execution_count = $null
      outputs   = @()
      source    = @(
        (NL "# 3) GOLD: curated/aggregated for analytics (example)"),
        (NL "df_silver = spark.table(silver_table)"),
        (NL ""),
        (NL "# Example: daily counts"),
        (NL "group_col = 'event_date' if 'event_date' in df_silver.columns else 'ingest_date'"),
        (NL "df_gold = df_silver.groupBy(group_col).count()"),
        (NL ""),
        (NL "df_gold_out = cleanse_df_columns(df_gold, keep=[group_col])"),
        (NL "df_gold_out.write.mode('overwrite').format('delta').saveAsTable(gold_table)"),
        (NL "print(f'Wrote gold: {gold_table}')")
      )
    }
  )

  $nb = [PSCustomObject]@{
    nbformat = 4
    nbformat_minor = 5
    cells = $cells
    metadata = @{
      language_info = @{ name = "python" }
      # Fabric-specific wiring for Lakehouse
      dependencies = @{
        lakehouse = @{
          default_lakehouse = $LakehouseId
          default_lakehouse_name = $LakehouseName
          default_lakehouse_workspace_id = $WorkspaceId
        }
      }
    }
  }

  $json = $nb | ConvertTo-Json -Depth 50
  $localNotebookPath = Join-Path -Path (Get-Location) -ChildPath "MedallionSetup.ipynb"
  Set-Content -Path $localNotebookPath -Value $json -Encoding UTF8
  Write-Host "Notebook JSON saved to $localNotebookPath for review." -ForegroundColor Cyan
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  return [Convert]::ToBase64String($bytes)
}

function Ensure-FabricNotebook {
  param(
    [Parameter(Mandatory=$true)][string]$WorkspaceId,
    [Parameter(Mandatory=$true)][string]$NotebookDisplayName,
    [Parameter(Mandatory=$true)][string]$LakehouseId,
    [Parameter(Mandatory=$true)][string]$LakehouseName
  )
  $existing = Get-WorkspaceItems -WorkspaceId $WorkspaceId |
    Where-Object { $_.type -eq "Notebook" -and $_.displayName -eq $NotebookDisplayName } |
    Select-Object -First 1
  if ($existing) { return $existing }
  $headers = Get-FabricHeaders
  $uri = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items"
  $payloadB64 = New-IpynbJsonBase64 -LakehouseId $LakehouseId -LakehouseName $LakehouseName -WorkspaceId $WorkspaceId
  $body = @{
    displayName = $NotebookDisplayName
    type = "Notebook"
    definition = @{
      format = "ipynb"
      parts = @(
        @{
          path = "notebook-content.ipynb"
          payload = $payloadB64
          payloadType = "InlineBase64"
        }
      )
    }
  } | ConvertTo-Json -Depth 50
  $resp = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -Body $body -SkipHttpErrorCheck
  if ($resp.StatusCode -eq 201) {
    return ($resp.Content | ConvertFrom-Json)
  }
  if ($resp.StatusCode -eq 202) {
    $location = $resp.Headers["Location"]
    Write-Host "Notebook creation returned 202. Location header type: $($location.GetType().FullName)"
    Write-Host "Location header value: $location"
    if ($location -is [array]) { $location = $location[0] }
    if (-not $location -or -not ($location -is [string]) -or $location -eq "") {
        throw "Create notebook returned 202 but Location header is missing or not a string."
    }
    $op = Wait-FabricOperation -OperationUrl ([string]$location)
    $created = Get-WorkspaceItems -WorkspaceId $WorkspaceId |
      Where-Object { $_.type -eq "Notebook" -and $_.displayName -eq $NotebookDisplayName } |
      Select-Object -First 1
    if (-not $created) { throw "Notebook LRO succeeded but notebook not found in workspace items." }
    return $created
  }
  throw "Create notebook failed: HTTP $($resp.StatusCode) $($resp.Content)"
}

function Invoke-FabricNotebookRunAndWait {
  param(
    [Parameter(Mandatory=$true)][string]$WorkspaceId,
    [Parameter(Mandatory=$true)][string]$NotebookItemId,
    [hashtable]$Parameters = @{},
    [hashtable]$SparkConf = @{},
    [int]$TimeoutSeconds = 3600,
    [int]$PollSeconds = 10
  )

  $headers = Get-FabricHeaders
  $runUri = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$NotebookItemId/jobs/instances?jobType=RunNotebook"
  $body = @{
    executionData = @{
      parameters = $Parameters
      configuration = @{
        conf = $SparkConf
      }
    }
  } | ConvertTo-Json -Depth 50

  $resp = Invoke-WebRequest -Method Post -Uri $runUri -Headers $headers -Body $body -SkipHttpErrorCheck

  $jobInstanceId = $null
  $location = $resp.Headers["Location"]
  if ($location -is [array]) { $location = $location[0] }

  if ($resp.Content) {
    try {
      $runRespObj = $resp.Content | ConvertFrom-Json
      if ($null -ne $runRespObj) {
        if ($runRespObj.PSObject.Properties.Name -contains 'id' -and $runRespObj.id) { $jobInstanceId = $runRespObj.id }
        elseif ($runRespObj.PSObject.Properties.Name -contains 'jobInstanceId' -and $runRespObj.jobInstanceId) { $jobInstanceId = $runRespObj.jobInstanceId }
      }
    } catch {
      # ignore parse failures; will try Location header below
    }
  }

  if (-not $jobInstanceId -and $location) {
    # Location might be the status URL itself; use it directly
    if ($location -match "/jobs/instances/([0-9a-fA-F-]{36})") {
      $jobInstanceId = $Matches[1]
    }
  }

  if (-not $jobInstanceId) {
    $locMsg = if ($location) { $location } else { '<none>' }
    $contentMsg = if ($resp.Content) { $resp.Content } else { '<empty>' }
    throw "Run request succeeded but did not return a job instance id. HTTP $($resp.StatusCode). Location: $locMsg. Response: $contentMsg"
  }

  $statusUri = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$NotebookItemId/jobs/instances/$jobInstanceId"
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds $PollSeconds
    # If $statusUri is an array, use the first element
    if ($statusUri -is [System.Array]) {
        $statusUri = $statusUri[0]
    }
    Write-Host "DEBUG: statusUri = $statusUri"
    $s = Invoke-RestMethod -Method Get -Uri $statusUri -Headers $headers
    $status = if ($null -ne $s -and $s.PSObject.Properties.Name -contains 'status') { $s.status } else { $null }

    switch ($status) {
      "Completed" { return $s }
      "Failed"    { throw ("Notebook run failed: " + ($s | ConvertTo-Json -Depth 50)) }
      "Cancelled" { throw ("Notebook run cancelled: " + ($s | ConvertTo-Json -Depth 50)) }
      default     { Write-Host "Run status: $status (jobInstanceId=$jobInstanceId)" }
    }
  }
  throw "Timed out waiting for notebook run to complete. jobInstanceId=$jobInstanceId"
}

if ($MyInvocation.PSCommandPath -eq $MyInvocation.MyCommand.Path) {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WorkspaceId,
        [Parameter(Mandatory=$true)]
        [string]$LakehouseName,
        [Parameter(Mandatory=$false)]
        [string]$NotebookName = "Medallion-BronzeSilverGold"
    )

    $lakehouse = (Get-WorkspaceItems -WorkspaceId $WorkspaceId | Where-Object { $_.type -eq "Lakehouse" -and $_.displayName -eq $LakehouseName } | Select-Object -First 1)
    if (-not $lakehouse) { throw "Lakehouse '$LakehouseName' not found in workspace." }

    $nb = Ensure-FabricNotebook -WorkspaceId $WorkspaceId -NotebookDisplayName $NotebookName -LakehouseId $lakehouse.id -LakehouseName $lakehouse.displayName
    Write-Host "Notebook creation response:" -ForegroundColor Yellow
    Write-Host ($nb | ConvertTo-Json -Depth 10)

    # Always get notebook id from workspace items by name
    $nbItem = Get-WorkspaceItems -WorkspaceId $WorkspaceId | Where-Object { $_.type -eq 'Notebook' -and $_.displayName -eq $NotebookName } | Select-Object -First 1

    if (-not $nbItem -or -not $nbItem.id) {
        throw "Notebook creation failed or notebook not found in workspace. Response: $($nb | ConvertTo-Json -Depth 10)"
    }

    Write-Host "Notebook ready. id=$($nbItem.id)"

    $params = @{}
    $result = Invoke-FabricNotebookRunAndWait -WorkspaceId $WorkspaceId -NotebookItemId $nbItem.id -Parameters $params
    Write-Host "Notebook completed. start=$($result.startTimeUtc) end=$($result.endTimeUtc) status=$($result.status)"
}
