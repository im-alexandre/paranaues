function Import-ApiKeys {
  [CmdletBinding()]
  param(
    [string]$KeysDir = (Join-Path $HOME ".api_keys"),
    [string]$ApiKeysSubdir = "api_keys",
    [string]$EnvironmentSubdir = "environment"
  )

  if (-not (Test-Path -LiteralPath $KeysDir)) {
    return
  }

  $apiKeysPath = Join-Path $KeysDir $ApiKeysSubdir
  if (Test-Path -LiteralPath $apiKeysPath -PathType Container) {
    foreach ($keyFile in (Get-ChildItem -LiteralPath $apiKeysPath -File)) {
      $name = $keyFile.Name.ToUpperInvariant()
      if ($name -notlike "*_API_KEY") {
        $name = "${name}_API_KEY"
      }

      if ($name -notmatch "^[A-Z_][A-Z0-9_]*$") {
        Write-Warning "Nome de arquivo de API key invalido: $($keyFile.Name)"
        continue
      }

      $value = (Get-Content -LiteralPath $keyFile.FullName -Raw).Trim()
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        Set-Item -Path "Env:$name" -Value $value
      }
    }
  }

  $environmentPath = Join-Path $KeysDir $EnvironmentSubdir
  if (-not (Test-Path -LiteralPath $environmentPath -PathType Container)) {
    return
  }

  foreach ($environmentFile in (Get-ChildItem -LiteralPath $environmentPath -File)) {
    try {
      $variables = Get-Content -LiteralPath $environmentFile.FullName -Raw | ConvertFrom-StringData -ErrorAction Stop
    } catch {
      Write-Warning "Arquivo de ambiente invalido em $($environmentFile.FullName). Use o formato NOME=valor por linha."
      continue
    }

    foreach ($entry in $variables.GetEnumerator()) {
      $name = $entry.Key.Trim()
      if ($name -match "^[A-Za-z_][A-Za-z0-9_]*$") {
        Set-Item -Path "Env:$name" -Value $entry.Value
      }
    }
  }
}

Import-ApiKeys
