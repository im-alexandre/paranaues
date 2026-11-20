$env:PSModulePath = (($env:PSModulePath -split ';') |
    Where-Object { $_ -and ($_ -notlike "$HOME\OneDrive\Documentos\PowerShell\Modules*") } |
    Select-Object -Unique) -join ';'

$wingetLinks = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
if ((Test-Path -LiteralPath $wingetLinks) -and
  ($env:Path -split ';' | ForEach-Object { $_.TrimEnd('\') }) -notcontains $wingetLinks.TrimEnd('\')) {
  $env:Path = "$wingetLinks;$env:Path"
}

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

# O RefreshEnv.cmd nao altera o ambiente do processo PowerShell que o iniciou.
# Carregue o alias refreshenv fornecido pelo modulo do Chocolatey.
$chocolateyRoots = @(
  $env:ChocolateyInstall
  (Join-Path $env:ProgramData 'chocoportable')
  (Join-Path $env:ProgramData 'chocolatey')
) | Where-Object { $_ }
foreach ($chocolateyRoot in $chocolateyRoots) {
  $chocolateyProfile = Join-Path $chocolateyRoot 'helpers\chocolateyProfile.psm1'
  if (Test-Path -LiteralPath $chocolateyProfile -PathType Leaf) {
    try {
      Import-Module -Name $chocolateyProfile -ErrorAction Stop
    } catch {
      Write-Warning "Nao foi possivel carregar refreshenv: $($_.Exception.Message)"
    }
    break
  }
}

. C:\Users\alexandre\.credenciais\api_keys.ps1

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

function setProxy {
  $env:HTTP_PROXY="http://localhost:18080"
  $env:HTTPS_PROXY=$env:HTTP_PROXY
}

function unsetProxy {
  $env:HTTP_PROXY=$null
  $env:HTTPS_PROXY=$null
}

# Usa o Codex CLI sem o app-server compartilhado, evitando janelas extras na 0.157.
# function codex {
#   $codexLauncher = Join-Path $env:APPDATA 'npm\codex.ps1'
#   if ($args -contains '--no-daemon') {
#     & $codexLauncher @args
#   } else {
#     & $codexLauncher --no-daemon @args
#   }
# }

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$env:LESSCHARSET = 'utf-8'
$env:CLAUDE_CODE_USE_POWERSHELL_TOOL = "1"

chcp 65001 > $null
