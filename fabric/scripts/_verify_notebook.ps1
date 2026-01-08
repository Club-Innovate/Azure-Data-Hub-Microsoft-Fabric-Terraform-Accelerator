. "$PSScriptRoot/fabric_notebook_utils.ps1"

$b64 = New-IpynbJsonBase64 -LakehouseId 'lh1' -LakehouseName 'lhname' -WorkspaceId 'ws1'
$json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
$nb = $json | ConvertFrom-Json

$i = 0
foreach ($c in $nb.cells) {
  $src = $c.source
  $t = $src.GetType().FullName
  Write-Host ("cell[{0}] {1} sourceType={2}" -f $i, $c.cell_type, $t)
  if ($src -is [string]) {
    Write-Host "  ERROR: source is string"
  } else {
    Write-Host ("  lines={0}" -f $src.Count)
    Write-Host ("  first={0}" -f ($src[0] -replace "`n", "\\n"))
    Write-Host ("  last={0}" -f ($src[$src.Count-1] -replace "`n", "\\n"))
  }
  $i++
}
