$env:PSModulePath = (($env:PSModulePath -split ';') |
    Where-Object { $_ -and ($_ -notlike "$HOME\OneDrive\Documentos\PowerShell\Modules*") } |
    Select-Object -Unique) -join ';'

$helpersDir = Join-Path (Split-Path -Parent $PROFILE) "helpers"
$helperScripts = @(
  "openclaw.ps1"
  "api-keys.ps1"
  "profile-core.ps1"
)

foreach ($helperScript in $helperScripts) {
  $helperPath = Join-Path $helpersDir $helperScript
  if (Test-Path -LiteralPath $helperPath) {
    . $helperPath
  }
}

# Forca npm/npx a usar os launchers .cmd para evitar associacao quebrada de .ps1.
function npm {
  & "$env:ProgramFiles\nodejs\npm.cmd" @args
}

function npx {
  & "$env:ProgramFiles\nodejs\npx.cmd" @args
}

function git-cp{
  & git commit -m @args; git push
}

$env:COOLIFY_BASE_URL="https://coolify.drg.ink"


$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8NoBOM'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8NoBOM'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8NoBOM'
$PSDefaultParameterValues['Export-Csv:Encoding'] = 'utf8NoBOM'

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$env:LESSCHARSET = 'utf-8'

chcp 65001 > $null
