<#
.SYNOPSIS
  Local smoke test for the Microsoft Fabric Terraform Accelerator (two-root pattern).
  - Validates repo structure
  - Runs terraform fmt/validate/plan for infra + fabric
  - Exports plan.json for policy testing
  - Runs conftest OPA policy checks against plan.json
  - Produces artifacts under:
      infra\tfplan, infra\plan.json, infra\conftest-results.json
      fabric\tfplan, fabric\plan.json, fabric\conftest-results.json

.REQUIREMENTS
  - terraform.exe on PATH (or set $Env:TERRAFORM_EXE)
  - conftest.exe on PATH (or set $Env:CONFTEST_EXE)
  - Azure CLI logged in (az login) OR SP env vars set for terraform providers
  - Shared tfvars at repo root: terraform.tfvars (recommended)

.NOTES
  This script performs NO apply/destroy; it is safe (plan-only).
  For a full sequential deployment (plan -> policy gate -> apply) of both roots,
  use `scripts\test_integration.ps1`.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Exists([string]$Path, [string]$Message) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "$Message`nMissing: $Path"
  }
}

function Get-ToolPath([string]$envVarName, [string]$fallbackExe) {
  $p = [Environment]::GetEnvironmentVariable($envVarName)
  if ($p -and (Test-Path -LiteralPath $p)) { return $p }
  $cmd = Get-Command $fallbackExe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  throw "Could not find $fallbackExe. Set `$Env:$envVarName or add it to PATH."
}

function Run([string]$Title, [string]$WorkingDir, [string]$Exe, [string[]]$Args) {
  Write-Host "`n=== $Title ===" -ForegroundColor Cyan
  Write-Host "Dir: $WorkingDir"
  Write-Host "Cmd: $Exe $($Args -join ' ')`n"
  $pinfo = New-Object System.Diagnostics.ProcessStartInfo
  $pinfo.FileName = $Exe
  $pinfo.WorkingDirectory = $WorkingDir
  $pinfo.RedirectStandardOutput = $true
  $pinfo.RedirectStandardError = $true
  $pinfo.UseShellExecute = $false
  $pinfo.Arguments = ($Args -join " ")

  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $pinfo
  $null = $proc.Start()
  $stdout = $proc.StandardOutput.ReadToEnd()
  $stderr = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()

  if ($stdout) { Write-Host $stdout }
  if ($stderr) { Write-Host $stderr -ForegroundColor Yellow }

  if ($proc.ExitCode -ne 0) {
    throw "Command failed with exit code $($proc.ExitCode): $Title"
  }
}

# --- Resolve repo root ---
$RepoRoot = Split-Path -Parent $PSScriptRoot
Write-Host "RepoRoot: $RepoRoot" -ForegroundColor Green

# --- Validate structure ---
Assert-Exists (Join-Path $RepoRoot "infra")  "Expected /infra root not found."
Assert-Exists (Join-Path $RepoRoot "fabric") "Expected /fabric root not found."
Assert-Exists (Join-Path $RepoRoot "policy") "Expected /policy folder not found."
Assert-Exists (Join-Path $RepoRoot "terraform.tfvars") "Expected shared terraform.tfvars at repo root."

# --- Tools ---
$Terraform = Get-ToolPath "TERRAFORM_EXE" "terraform"
$Conftest  = Get-ToolPath "CONFTEST_EXE"  "conftest"

# --- Common paths ---
$PolicyDir = Join-Path $RepoRoot "policy"
$SharedVarFile = Join-Path $RepoRoot "terraform.tfvars"

# --- FMT at repo root (optional but recommended) ---
Run "Terraform fmt (recursive)" $RepoRoot $Terraform @("fmt","-recursive")

# --- Smoke test INFRA ---
$InfraDir = Join-Path $RepoRoot "infra"
Run "INFRA: terraform init"      $InfraDir $Terraform @("init","-upgrade")
Run "INFRA: terraform validate"  $InfraDir $Terraform @("validate")
Run "INFRA: terraform plan"      $InfraDir $Terraform @("plan","-out=tfplan","-var-file=$SharedVarFile")
Run "INFRA: terraform show json" $InfraDir $Terraform @("show","-json","tfplan")

# Write plan.json from show output (capture stdout)
Write-Host "`n=== INFRA: write plan.json ===" -ForegroundColor Cyan
& $Terraform -chdir="$InfraDir" show -json tfplan | Out-File -Encoding utf8 (Join-Path $InfraDir "plan.json")

# Conftest on plan.json
Run "INFRA: conftest (table)" $RepoRoot $Conftest @("test","--policy",$PolicyDir,(Join-Path $InfraDir "plan.json"),"-o","table")
Write-Host "`n=== INFRA: conftest (json report) ===" -ForegroundColor Cyan
& $Conftest test --policy $PolicyDir (Join-Path $InfraDir "plan.json") -o json | Out-File -Encoding utf8 (Join-Path $InfraDir "conftest-results.json")

# --- Smoke test FABRIC ---
$FabricDir = Join-Path $RepoRoot "fabric"
Run "FABRIC: terraform init"      $FabricDir $Terraform @("init","-upgrade")
Run "FABRIC: terraform validate"  $FabricDir $Terraform @("validate")
Run "FABRIC: terraform plan"      $FabricDir $Terraform @("plan","-out=tfplan","-var-file=$SharedVarFile")
Run "FABRIC: terraform show json" $FabricDir $Terraform @("show","-json","tfplan")

Write-Host "`n=== FABRIC: write plan.json ===" -ForegroundColor Cyan
& $Terraform -chdir="$FabricDir" show -json tfplan | Out-File -Encoding utf8 (Join-Path $FabricDir "plan.json")

Run "FABRIC: conftest (table)" $RepoRoot $Conftest @("test","--policy",$PolicyDir,(Join-Path $FabricDir "plan.json"),"-o","table")
Write-Host "`n=== FABRIC: conftest (json report) ===" -ForegroundColor Cyan
& $Conftest test --policy $PolicyDir (Join-Path $FabricDir "plan.json") -o json | Out-File -Encoding utf8 (Join-Path $FabricDir "conftest-results.json")

Write-Host "`n✅ Smoke test complete." -ForegroundColor Green
Write-Host "Artifacts generated:"
Write-Host " - infra\tfplan, infra\plan.json, infra\conftest-results.json"
Write-Host " - fabric\tfplan, fabric\plan.json, fabric\conftest-results.json"
