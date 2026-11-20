# Os dois perfis usam os mesmos helpers, sem duplicar suas definicoes.
$helpersDirectory = Join-Path $PSScriptRoot '..\PowerShell\helpers'
foreach ($helper in (Get-ChildItem -LiteralPath $helpersDirectory -Filter '*.ps1' -File | Sort-Object Name)) {
  . $helper.FullName
}
Invoke-LocalProfile
