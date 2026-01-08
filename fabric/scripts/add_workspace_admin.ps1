param(
  [string]$WorkspaceId,
  [string]$UserToAdd,
  [string]$AccessRight = "Admin",
  [string]$PrincipalType = "User"
)

# Get token using Azure CLI (assumes az login as user)
$token = az account get-access-token --resource https://analysis.windows.net/powerbi/api --query accessToken -o tsv

# Check if user/SP is already assigned the specified access right
$uri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/users"
$existingUsers = Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $token"}

$userExists = $false
foreach ($user in $existingUsers.value) {
    if ($user.identifier -eq $UserToAdd -and $user.groupUserAccessRight -eq $AccessRight) {
        $userExists = $true
        break
    }
}

if ($userExists) {
    Write-Host "User/SP $UserToAdd already has $AccessRight rights. Skipping add."
    exit 0
}

# Add user or SP to workspace
$body = @{
    identifier = $UserToAdd
    groupUserAccessRight = $AccessRight
    principalType = $PrincipalType
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri $uri -Headers @{Authorization = "Bearer $token"} -Body $body -ContentType "application/json"
