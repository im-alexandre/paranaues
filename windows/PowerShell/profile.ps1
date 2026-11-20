# Entrada compartilhada: helpers independentes, carregados uma vez em ordem alfabetica.
foreach ($helper in (Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'helpers') -Filter '*.ps1' -File | Sort-Object Name)) {
  . $helper.FullName
}
Invoke-LocalProfile
