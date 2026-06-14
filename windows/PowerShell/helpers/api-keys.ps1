function Import-ApiKeys {
  [CmdletBinding()]
  param(
    [string]$KeysDir = (Join-Path $HOME ".api_keys")
  )

  if (-not (Test-Path -LiteralPath $KeysDir)) {
    return
  }

  Get-ChildItem -LiteralPath $KeysDir -File | ForEach-Object {
    $provider = $_.Name.ToUpperInvariant()
    $varName = if ($provider -like "*_API_KEY") {
      $provider
    } else {
      "${provider}_API_KEY"
    }

    $value = (Get-Content -LiteralPath $_.FullName -Raw).Trim()
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      Set-Item -Path "Env:$varName" -Value $value
    }
  }
}

Import-ApiKeys
