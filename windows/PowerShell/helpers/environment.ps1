# Preferencias comuns, com os nomes de encoding aceitos por cada versao.
$utf8 = [Text.UTF8Encoding]::new($false)
$OutputEncoding = $utf8
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$encodingName = if ($PSVersionTable.PSVersion.Major -ge 7) { 'utf8NoBOM' } else { 'utf8' }
foreach ($command in @('Out-File', 'Set-Content', 'Add-Content', 'Export-Csv')) {
  $PSDefaultParameterValues["${command}:Encoding"] = $encodingName
}
if ($PSVersionTable.PSVersion.Major -ge 7) {
  $PSDefaultParameterValues['Tee-Object:Encoding'] = $encodingName
}

$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:LESSCHARSET = 'utf-8'
$env:OPENCODE_DISABLE_CLAUDE_CODE_PROMPT = '1'
$env:OPENCODE_DISABLE_CLAUDE_CODE_SKILLS = '1'
$env:COOLIFY_BASE_URL = 'https://coolify.drg.ink'

function source {
  param([Parameter(Mandatory = $true)][string]$Path)
  foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop)) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    $parts = $line.Split('=', 2)
    if ($parts.Length -eq 2 -and $parts[0].Trim() -match '^[A-Za-z_][A-Za-z0-9_]*$') {
      $name = $parts[0].Trim()
      Set-Item -LiteralPath "Env:$name" -Value $parts[1].Trim()
      Write-Host "Set environment variable: $name"
    }
  }
}

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

      $value = (Get-Content -LiteralPath $keyFile.FullName -Encoding UTF8 -Raw).Trim()
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
      $variables = Get-Content -LiteralPath $environmentFile.FullName -Encoding UTF8 -Raw | ConvertFrom-StringData -ErrorAction Stop
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
