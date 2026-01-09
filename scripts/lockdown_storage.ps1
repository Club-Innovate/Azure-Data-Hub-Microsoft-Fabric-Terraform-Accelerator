<#
.SYNOPSIS
    Locks down a storage account by disabling public network access for HIPAA compliance.
.PARAMETER StorageAccountName
    The name of the storage account to lock down.
.PARAMETER ResourceGroupName
    The resource group containing the storage account.
.EXAMPLE
    .\lockdown_storage.ps1 -StorageAccountName "avatardevsa" -ResourceGroupName "avatar-dev-rg"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

try {
    Write-Host "Locking down storage account: $StorageAccountName in resource group: $ResourceGroupName" -ForegroundColor Cyan
    az storage account update --name $StorageAccountName --resource-group $ResourceGroupName --public-network-access Disabled
    Write-Host "Storage account locked down for HIPAA compliance." -ForegroundColor Green
} catch {
    Write-Error "Failed to lock down storage account: $_"
    exit 1
}
