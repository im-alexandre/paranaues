# Entrada compartilhada: helpers independentes, carregados uma vez em ordem alfabetica.
. (Join-Path $PSScriptRoot 'module-path.ps1')
$env:PSModulePath = Get-ParanauesModulePath -Value $env:PSModulePath
foreach ($helper in (Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'helpers') -Filter '*.ps1' -File | Sort-Object Name)) {
  . $helper.FullName
}
Invoke-LocalProfile
