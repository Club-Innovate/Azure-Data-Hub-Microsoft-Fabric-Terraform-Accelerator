<#
.SYNOPSIS
  Full integration test for two-root Terraform accelerator.
  - Plans + enforces OPA/Conftest policies
  - Applies infra (Azure + Fabric capacity)
  - Applies fabric (Workspace + Lakehouse)
  - Runs basic sanity checks by reading terraform outputs
  - Optional destroy at end (default: true)

.SAFETY
  This will CREATE cloud resources. Use a dedicated test subscription/resource group.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
  [switch]$SkipDestroy
)

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

$RepoRoot = Split-Path -Parent $PSScriptRoot
Write-Host "RepoRoot: $RepoRoot" -ForegroundColor Green

Assert-Exists (Join-Path $RepoRoot "infra") "Expected /infra not found."
Assert-Exists (Join-Path $RepoRoot "fabric") "Expected /fabric not found."
Assert-Exists (Join-Path $RepoRoot "policy") "Expected /policy folder not found."
Assert-Exists (Join-Path $RepoRoot "terraform.tfvars") "Expected root terraform.tfvars not found."

$Terraform = Get-ToolPath "TERRAFORM_EXE" "terraform"
$Conftest  = Get-ToolPath "CONFTEST_EXE"  "conftest"

$PolicyDir = Join-Path $RepoRoot "policy"
$VarFile   = Join-Path $RepoRoot "terraform.tfvars"

$InfraDir  = Join-Path $RepoRoot "infra"
$FabricDir = Join-Path $RepoRoot "fabric"

# --- INFRA PLAN + POLICY GATE + APPLY ---
Run "INFRA: terraform init"     $InfraDir $Terraform @("init","-upgrade")
Run "INFRA: terraform validate" $InfraDir $Terraform @("validate")
Run "INFRA: terraform plan"     $InfraDir $Terraform @("plan","-out=tfplan","-var-file=$VarFile")

Write-Host "`n=== INFRA: write plan.json ===" -ForegroundColor Cyan
& $Terraform -chdir="$InfraDir" show -json tfplan | Out-File -Encoding utf8 (Join-Path $InfraDir "plan.json")

Run "INFRA: conftest (policy gate)" $RepoRoot $Conftest @("test","--policy",$PolicyDir,(Join-Path $InfraDir "plan.json"),"-o","table")

Run "INFRA: terraform apply" $InfraDir $Terraform @("apply","-auto-approve","tfplan")

Write-Host "`n=== INFRA: outputs ===" -ForegroundColor Cyan
& $Terraform -chdir="$InfraDir" output

# --- FABRIC PLAN + POLICY GATE + APPLY ---
Run "FABRIC: terraform init"     $FabricDir $Terraform @("init","-upgrade")
Run "FABRIC: terraform validate" $FabricDir $Terraform @("validate")
Run "FABRIC: terraform plan"     $FabricDir $Terraform @("plan","-out=tfplan","-var-file=$VarFile")

Write-Host "`n=== FABRIC: write plan.json ===" -ForegroundColor Cyan
& $Terraform -chdir="$FabricDir" show -json tfplan | Out-File -Encoding utf8 (Join-Path $FabricDir "plan.json")

Run "FABRIC: conftest (policy gate)" $RepoRoot $Conftest @("test","--policy",$PolicyDir,(Join-Path $FabricDir "plan.json"),"-o","table")

Run "FABRIC: terraform apply" $FabricDir $Terraform @("apply","-auto-approve","tfplan")

Write-Host "`n=== FABRIC: outputs ===" -ForegroundColor Cyan
& $Terraform -chdir="$FabricDir" output

Write-Host "`n✅ Integration apply complete." -ForegroundColor Green

if (-not $SkipDestroy) {
  Write-Host "`n=== DESTROY (fabric then infra) ===" -ForegroundColor Yellow

  Run "FABRIC: terraform destroy" $FabricDir $Terraform @("destroy","-auto-approve","-var-file=$VarFile")
  Run "INFRA: terraform destroy"  $InfraDir $Terraform @("destroy","-auto-approve","-var-file=$VarFile")

  Write-Host "`n✅ Destroy complete." -ForegroundColor Green
} else {
  Write-Host "`n⚠️ SkipDestroy enabled. Resources remain deployed." -ForegroundColor Yellow
}
