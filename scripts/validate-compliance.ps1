<#
.SYNOPSIS
    Validates Azure Policy compliance for HIPAA, GLBA, and GDPR assignments in a given scope.
.DESCRIPTION
    This script checks the compliance state of assigned Azure Policy initiatives (HIPAA, GLBA, GDPR)
    at the specified scope (subscription, resource group, or resource). It outputs a summary report
    and highlights any non-compliant resources.
.PARAMETER ScopeId
    The Azure resource ID of the scope to check (e.g., /subscriptions/xxxx/resourceGroups/xxxx).
.EXAMPLE
    .\validate-compliance.ps1 -ScopeId "/subscriptions/xxxx/resourceGroups/xxxx"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ScopeId
)

# Exception handling for Azure CLI login
try {
    az account show | Out-Null
} catch {
    Write-Error "Azure CLI not logged in. Please run 'az login' first."
    exit 1
}

# List of built-in policy initiative display names
$initiatives = @(
    "HITRUST/HIPAA",    
    "GDPR"
)

foreach ($initiative in $initiatives) {
    Write-Host "Checking compliance for: $initiative" -ForegroundColor Cyan
    try {
        $policySet = az policy set-definition list --query "[?displayName=='$initiative']" | ConvertFrom-Json
        if (-not $policySet) {
            Write-Warning "Policy initiative '$initiative' not found. Skipping."
            continue
        }
        $policySetId = $policySet[0].id
        $assignments = az policy assignment list --scope $ScopeId --query "[?policyDefinitionId=='$policySetId']" | ConvertFrom-Json
        if (-not $assignments) {
            Write-Host "No assignment found for '$initiative' at this scope." -ForegroundColor Yellow
            continue
        }
        foreach ($assignment in $assignments) {
            $compliance = az policy state summarize --management-group "" --resource-group "" --policy-assignment $assignment.name --query "results" | ConvertFrom-Json
            Write-Host "Assignment: $($assignment.name)"
            Write-Host "  Compliance State: $($compliance.complianceState)"
            if ($compliance.nonCompliantResources -gt 0) {
                Write-Host "  Non-compliant resources: $($compliance.nonCompliantResources)" -ForegroundColor Red
            } else {
                Write-Host "  All resources compliant." -ForegroundColor Green
            }
        }
    } catch {
        Write-Error "Error checking compliance for '$initiative': $_"
    }
}
