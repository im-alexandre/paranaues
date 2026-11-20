[CmdletBinding()]
param(
  [switch]$ProfileOnly,
  [switch]$SkipPackages,
  [switch]$UpgradeAll,
  [switch]$RestoreDefenderExclusions,
  [string[]]$OnlyPackageIds = @(),
  [string[]]$SkipPackageIds = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$profileRepo = Join-Path $root 'windows\PowerShell\Microsoft.PowerShell_profile.ps1'
$helpersRepo = Join-Path $root 'windows\PowerShell\helpers'
$packagesFile = Join-Path $root 'windows\winget-packages.json'
$terminalRepo = Join-Path $root 'windows\terminal_settings.json'
$defenderFile = Join-Path $root 'windows\defender_exclusions.json'
$lazyVimDir = Join-Path $env:LOCALAPPDATA 'nvim'
$lazyVimRepo = 'https://github.com/im-alexandre/lazyvim_config'

$ErrorActionPreference = "Stop"

$ROOT          = Split-Path -Parent $MyInvocation.MyCommand.Path

$WINGET_FILE      = Join-Path $ROOT "windows\winget-packages.json"
$TERMINAL_REPO    = Join-Path $ROOT "windows\terminal_settings.json"
$DEFENDER_FILE    = Join-Path $ROOT "windows\defender_exclusions.json"

$POWERSHELL_REPO         = Join-Path $ROOT "windows\PowerShell"
$POWERSHELL_HELPERS_REPO = Join-Path $POWERSHELL_REPO "helpers"
$POWERSHELL_MODULES_REPO = Join-Path $POWERSHELL_REPO "Modules"
$POWERSHELL_LOADERS_REPO = Join-Path $ROOT "windows\profile-loaders"

$LAZYVIM_REPO  = "https://github.com/im-alexandre/lazyvim_config"
$LAZYVIM_DIR   = Join-Path $env:LOCALAPPDATA "nvim"

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
  Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  exit
}

function Ensure-Command([string]$Name, [string]$Hint) {
  if (Get-Command $Name -ErrorAction SilentlyContinue) {
    return
function Assert-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Comando necessario nao encontrado: $Name"
  }
}

function Assert-ExitCode([string]$Action) {
  if ($LASTEXITCODE -ne 0) {
    throw "$Action falhou (codigo $LASTEXITCODE)."
  }
}

function Get-BackupPath([string]$Path) {
  $timestamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
  return "$Path.bak.$timestamp"
function Invoke-Winget([string[]]$Arguments, [string]$Action) {
  $proxyValue = if ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } else { $env:HTTP_PROXY }
  $settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json'
  $settingsExisted = Test-Path -LiteralPath $settingsPath
  $originalSettings = if ($settingsExisted) { Get-Content -LiteralPath $settingsPath -Raw } else { $null }
  $bridge = $null
  $bridgeOut = $null
  $bridgeErr = $null

  try {
    if ($proxyValue) {
      $settings = if ($settingsExisted) { ConvertFrom-Json -InputObject $originalSettings -AsHashtable } else { @{} }
      if (-not $settings.ContainsKey('source') -or -not $settings['source']) {
        $settings['source'] = @{}
      }
      $settings['source']['autoUpdateIntervalInMinutes'] = 0
      New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
      $settings | ConvertTo-Json -Depth 64 | Set-Content -LiteralPath $settingsPath -Encoding utf8NoBOM

      $proxyUri = [uri]$proxyValue
      if ($proxyUri.UserInfo) {
        Assert-Command node
        $bridgeScript = Join-Path $root 'windows\winget-proxy-bridge.js'
        if (-not (Test-Path -LiteralPath $bridgeScript -PathType Leaf)) {
          throw "Ponte do proxy nao encontrada: $bridgeScript"
        }
        $bridgeOut = Join-Path $env:TEMP "paranaues-winget-$([guid]::NewGuid().ToString('N')).out"
        $bridgeErr = "$bridgeOut.err"
        $bridge = Start-Process -FilePath (Get-Command node).Source -ArgumentList $bridgeScript -PassThru -WindowStyle Hidden -RedirectStandardOutput $bridgeOut -RedirectStandardError $bridgeErr
        $port = $null
        for ($i = 0; $i -lt 100; $i++) {
          Start-Sleep -Milliseconds 100
          if (Test-Path -LiteralPath $bridgeOut) {
            $port = (Get-Content -LiteralPath $bridgeOut -Raw).Trim()
            if ($port -match '^\d+$') { break }
          }
        }
        if ($port -notmatch '^\d+$') {
          throw 'A ponte local do proxy nao iniciou.'
        }
        $proxyValue = "http://127.0.0.1:$port"
      }

      & winget settings --enable ProxyCommandLineOptions | Out-Null
      Assert-ExitCode 'winget ProxyCommandLineOptions'
      $Arguments += @('--proxy', $proxyValue)
    }

    & winget @Arguments | Out-Host
    Assert-ExitCode $Action
  } finally {
    if ($bridge) {
      Stop-Process -Id $bridge.Id -Force -ErrorAction SilentlyContinue
    }
    foreach ($path in @($bridgeOut, $bridgeErr)) {
      if ($path) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
    }
    if ($proxyValue) {
      if ($settingsExisted) {
        Set-Content -LiteralPath $settingsPath -Value $originalSettings -NoNewline -Encoding utf8NoBOM
      } else {
        Remove-Item -LiteralPath $settingsPath -Force -ErrorAction SilentlyContinue
      }
    }
  }
}

function Test-Administrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-RepoLink([string]$LinkPath, [string]$TargetPath) {
  $parent = Split-Path -Parent $LinkPath
  New-Item -ItemType Directory -Path $parent -Force | Out-Null

  $existing = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
  if ($existing -and $existing.LinkType -eq 'SymbolicLink' -and
      @($existing.Target) -contains $TargetPath) {
    return
  }

  $backup = $null
  if ($existing) {
    $backup = "$LinkPath.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss').$([guid]::NewGuid().ToString('N').Substring(0, 8))"
    Move-Item -LiteralPath $LinkPath -Destination $backup -ErrorAction Stop
  }

  try {
    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -ErrorAction Stop | Out-Null
  } catch {
    if ($backup) {
      Move-Item -LiteralPath $backup -Destination $LinkPath -ErrorAction Stop
    }
    throw
  }

  if ($backup) {
    Write-Host "Backup: $backup" -ForegroundColor DarkGray
  }
  Write-Host "Link: $LinkPath -> $TargetPath" -ForegroundColor Green
}

function Ensure-PSReadLine {
  $module = Get-Module -ListAvailable PSReadLine |
    Where-Object { $_.Version -ge [version]'2.2.0' } |
    Sort-Object Version -Descending |
    Select-Object -First 1

  if (-not $module) {
    Write-Host 'Instalando PSReadLine para o usuario atual...' -ForegroundColor Yellow
    Assert-Command Install-PSResource
    Install-PSResource -Name PSReadLine -Scope CurrentUser -Repository PSGallery -TrustRepository -AcceptLicense -ErrorAction Stop
  }

  Import-Module PSReadLine -MinimumVersion 2.2.0 -Force -ErrorAction Stop
  $loaded = Get-Module PSReadLine
  Write-Host "PSReadLine carregado: $($loaded.Version)" -ForegroundColor Green
}

function Install-Profile {
  if (-not (Test-Path -LiteralPath $profileRepo -PathType Leaf)) {
    throw "Profile nao encontrado: $profileRepo"
  }
  if (-not (Test-Path -LiteralPath $helpersRepo -PathType Container)) {
    throw "Helpers nao encontrados: $helpersRepo"
  }
  foreach ($name in @('openclaw.ps1', 'api-keys.ps1', 'profile-core.ps1')) {
    if (-not (Test-Path -LiteralPath (Join-Path $helpersRepo $name) -PathType Leaf)) {
      throw "Helper nao encontrado: $name"
    }
  }

  New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -Force | Out-Null
}

function Prepend-PathEntry([string]$Value, [string]$Entry) {
  $parts = @()
  if (-not [string]::IsNullOrWhiteSpace($Value)) {
    $parts = @($Value -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  }

  $normalizedEntry = $Entry.TrimEnd("\").ToLowerInvariant()
  $deduped = @(
    foreach ($part in $parts) {
      if ($part.TrimEnd("\").ToLowerInvariant() -ne $normalizedEntry) {
        $part
      }
    }
  )

  return (@($Entry) + $deduped) -join ";"
}

function Install-PowerShellRepoProfile {
  param(
    [string]$DocumentsDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
  )

  if (-not (Test-Path -LiteralPath $POWERSHELL_HELPERS_REPO)) {
    throw "Diretório de helpers do PowerShell não encontrado no repo: $POWERSHELL_HELPERS_REPO"
  }

  $profiles = @(
    foreach ($edition in @("PowerShell", "WindowsPowerShell")) {
      $relativePath = Join-Path $edition "profile.ps1"
      $sourcePath = Join-Path (Join-Path $ROOT "windows") $relativePath
      $loaderPath = Join-Path $POWERSHELL_LOADERS_REPO $relativePath
      if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Profile não encontrado no repo: $sourcePath"
      }
      if (-not (Test-Path -LiteralPath $loaderPath -PathType Leaf)) {
        throw "Carregador de profile não encontrado no repo: $loaderPath"
      }
      [pscustomobject]@{
        Path = Join-Path $DocumentsDirectory $relativePath
        Content = ([IO.File]::ReadAllText($loaderPath)).Replace("__PARANAUES_ROOT__", $ROOT.Replace("'", "''"))
        Source = $sourcePath
      }
    }
  )

  foreach ($profile in $profiles) {
    # Retira somente o carregador antigo criado por este repo; perfis proprios ficam intactos.
    $legacyPath = Join-Path (Split-Path -Parent $profile.Path) "Microsoft.PowerShell_profile.ps1"
    $legacySource = Join-Path (Split-Path -Parent $profile.Source) "Microsoft.PowerShell_profile.ps1"
    if (Test-Path -LiteralPath $legacyPath -PathType Leaf) {
      $legacyLoader = ". '" + $legacySource.Replace("'", "''") + "'"
      if ([IO.File]::ReadAllText($legacyPath).Trim() -eq $legacyLoader) {
        $backupPath = Get-BackupPath $legacyPath
        Copy-Item -LiteralPath $legacyPath -Destination $backupPath
        Remove-Item -LiteralPath $legacyPath -Force
        Write-Host "Carregador antigo arquivado: $backupPath" -ForegroundColor DarkGray
      }
    }
    $existing = Get-Item -LiteralPath $profile.Path -Force -ErrorAction SilentlyContinue
    if ($existing) {
      if ($existing.PSIsContainer) {
        throw "O caminho do profile é um diretório: $($profile.Path)"
      }
      if ([IO.File]::ReadAllText($profile.Path) -eq $profile.Content) {
        continue
      }
      $backupPath = Get-BackupPath $profile.Path
      Copy-Item -LiteralPath $profile.Path -Destination $backupPath -Force
      Write-Host "Backup: $backupPath" -ForegroundColor DarkGray
      if ($existing.LinkType -eq "SymbolicLink") {
        Remove-Item -LiteralPath $profile.Path -Force
      }
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $profile.Path) -Force | Out-Null
    [IO.File]::WriteAllText($profile.Path, $profile.Content, [Text.UTF8Encoding]::new($false))
    Write-Host "PowerShell profile: $($profile.Path) -> $($profile.Source)" -ForegroundColor Green
  Ensure-PSReadLine

  $documents = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
  foreach ($shellDir in @('PowerShell', 'WindowsPowerShell')) {
    $profileDir = Join-Path $documents $shellDir
    Set-RepoLink -LinkPath (Join-Path $profileDir 'Microsoft.PowerShell_profile.ps1') -TargetPath $profileRepo
    Set-RepoLink -LinkPath (Join-Path $profileDir 'helpers') -TargetPath $helpersRepo
  }
}

function Install-Packages {
  Assert-Command winget
  if (-not (Test-Path -LiteralPath $packagesFile -PathType Leaf)) {
    throw "Lista de pacotes nao encontrada: $packagesFile"
  }

  $importFile = $packagesFile
  if ($SkipPackageIds.Count -gt 0 -or $OnlyPackageIds.Count -gt 0) {
    $skipIds = @($SkipPackageIds | ForEach-Object { $_ -split ',' } | Where-Object { $_ } | ForEach-Object { $_.Trim() })
    $onlyIds = @($OnlyPackageIds | ForEach-Object { $_ -split ',' } | Where-Object { $_ } | ForEach-Object { $_.Trim() })
    $importData = Get-Content -LiteralPath $packagesFile -Raw | ConvertFrom-Json -AsHashtable
    foreach ($source in $importData['Sources']) {
      $source['Packages'] = @($source['Packages'] | Where-Object {
        ($onlyIds.Count -eq 0 -or $onlyIds -contains $_['PackageIdentifier']) -and
        $skipIds -notcontains $_['PackageIdentifier']
      })
    }
    $importData['Sources'] = @($importData['Sources'] | Where-Object { $_['Packages'].Count -gt 0 })
    $importFile = Join-Path $env:TEMP "paranaues-winget-import-$([guid]::NewGuid().ToString('N')).json"
    $importData | ConvertTo-Json -Depth 64 | Set-Content -LiteralPath $importFile -Encoding utf8NoBOM
    if ($onlyIds.Count -gt 0) { Write-Host "Pacotes selecionados: $($onlyIds -join ', ')" -ForegroundColor DarkGray }
    if ($skipIds.Count -gt 0) { Write-Host "Pacotes adiados: $($skipIds -join ', ')" -ForegroundColor DarkYellow }
  }

  $out = $json | ConvertTo-Json -Depth 64
  Set-Content -Path $TERMINAL_REPO -Value $out -Encoding UTF8
}

Write-Host "=== Xandão Labs :: Install Paranauês 🧪 ===" -ForegroundColor Cyan
Write-Host "Repo: $ROOT" -ForegroundColor DarkGray
<#
 # {
# --------------------------------------------------
# 1) winget import (faz o grosso)
# --------------------------------------------------
Write-Host "`n[1/7] winget import..." -ForegroundColor Yellow
Ensure-Command winget "Instala o App Installer (winget) primeiro."

& winget source update | Out-Null

if (Test-Path $WINGET_FILE) {
  & winget import -i $WINGET_FILE --ignore-versions `
    --accept-package-agreements `
    --accept-source-agreements `
    --disable-interactivity `
    --no-upgrade | Out-Host
} else {
  Write-Host "winget-packages.json não encontrado. Pulando." -ForegroundColor DarkYellow
}
:Enter a comment or description}
#>
# --------------------------------------------------
# 3) lazyvim_config (clone/pull) -> $HOME\nvim
# --------------------------------------------------
Write-Host "`n[3/7] lazyvim_config..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "git não encontrado. Tentando winget install Git.Git..." -ForegroundColor DarkYellow
  Try-WingetInstall "Git.Git"
}
Ensure-Command git "Inclui Git no winget-packages.json ou instala manualmente."

if (Test-Path (Join-Path $LAZYVIM_DIR ".git")) {
  & git -C $LAZYVIM_DIR pull --ff-only | Out-Host
} else {
  if (Test-Path $LAZYVIM_DIR) {
    throw "Diretório $LAZYVIM_DIR já existe mas não parece um repo git. Remove/renomeia e roda de novo."
  }
  & git clone $LAZYVIM_REPO $LAZYVIM_DIR | Out-Host
}

# --------------------------------------------------
# 4) Windows Terminal settings via mklink pro arquivo do repo
#     - Terminal edita e já reflete no repo ✅
#     - Patch só nos paths de pwsh/winps (que quebram)
# --------------------------------------------------
Write-Host "`n[4/7] Windows Terminal settings (mklink + patch paths)..." -ForegroundColor Yellow

$targets = Get-TerminalTargets
if ($targets -ne $null -gt 0) {
  Write-Host "Windows Terminal (stable/preview) não encontrado. Pulando mklink." -ForegroundColor DarkYellow
  Write-Host "Dica: inclui Microsoft.WindowsTerminal no winget-packages.json" -ForegroundColor DarkGray
} else {
  if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    throw "pwsh não encontrado após winget import. Inclui Microsoft.PowerShell no winget-packages.json."
  }

  $PWSH_PATH  = (Get-Command pwsh).Source
  $WINPS_PATH = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

  Patch-TerminalRepoJsonInPlace -PwshPath $PWSH_PATH -WinPsPath $WINPS_PATH

  foreach ($dst in $targets) {
    Force-Symlink -LinkPath $dst -TargetPath $TERMINAL_REPO
    Write-Host "Linked: $dst -> $TERMINAL_REPO" -ForegroundColor Green
  }
}

# --------------------------------------------------
# 5) PowerShell profiles/helpers/modules via repo
# --------------------------------------------------
Write-Host "`n[5/7] PowerShell profiles/helpers/modules (repo)..." -ForegroundColor Yellow
Install-PowerShellRepoProfile
New-Item -ItemType Directory -Path $POWERSHELL_MODULES_REPO -Force | Out-Null
$userModulePath = [Environment]::GetEnvironmentVariable("PSModulePath", [EnvironmentVariableTarget]::User)
$newUserModulePath = Prepend-PathEntry -Value $userModulePath -Entry $POWERSHELL_MODULES_REPO
[Environment]::SetEnvironmentVariable("PSModulePath", $newUserModulePath, [EnvironmentVariableTarget]::User)
$env:PSModulePath = Prepend-PathEntry -Value $env:PSModulePath -Entry $POWERSHELL_MODULES_REPO
Write-Host "PSModulePath(User) começa com: $POWERSHELL_MODULES_REPO" -ForegroundColor Green

# --------------------------------------------------
# 6) Windows Defender Restore Exclusions
# --------------------------------------------------
Write-Host "`n[6/7] Windows Defender (Restore Exclusions)..." -ForegroundColor Yellow
if (Test-Path $DEFENDER_FILE) {
  try {
    $wingetArgs = @('import', '-i', $importFile, '--ignore-versions', '--ignore-unavailable', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity', '--no-upgrade')
    Invoke-Winget -Arguments $wingetArgs -Action 'winget import'
  } finally {
    if ($importFile -ne $packagesFile) {
      Remove-Item -LiteralPath $importFile -Force -ErrorAction SilentlyContinue
    }
  }

  $env:Path = @(
    [Environment]::GetEnvironmentVariable('Path', 'Machine'),
    [Environment]::GetEnvironmentVariable('Path', 'User')
  ) -join ';'
}

function Sync-LazyVim {
  Assert-Command git
  if (Test-Path -LiteralPath (Join-Path $lazyVimDir '.git')) {
    & git -C $lazyVimDir pull --ff-only | Out-Host
    Assert-ExitCode 'git pull lazyvim_config'
  } elseif (Test-Path -LiteralPath $lazyVimDir) {
    Write-Warning "$lazyVimDir existe e nao e um repositorio Git; LazyVim nao foi alterado."
  } else {
    & git clone $lazyVimRepo $lazyVimDir | Out-Host
    Assert-ExitCode 'git clone lazyvim_config'
  }
}

function Install-TerminalSettings {
  if (-not (Test-Path -LiteralPath $terminalRepo -PathType Leaf)) {
    throw "Configuracao do Terminal nao encontrada: $terminalRepo"
  }
  $localStateDirs = @(
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState'
  )
  foreach ($localState in $localStateDirs) {
    if (Test-Path -LiteralPath $localState -PathType Container) {
      Set-RepoLink -LinkPath (Join-Path $localState 'settings.json') -TargetPath $terminalRepo
    }
  }
}

function Restore-Defender {
  if (-not (Test-Path -LiteralPath $defenderFile -PathType Leaf)) {
    throw "Exclusoes do Defender nao encontradas: $defenderFile"
  }
  Assert-Command Add-MpPreference
  $data = Get-Content -LiteralPath $defenderFile -Raw | ConvertFrom-Json
  foreach ($path in @($data.ExclusionPath)) {
    if ($path) { Add-MpPreference -ExclusionPath $path -ErrorAction Stop }
  }
  foreach ($process in @($data.ExclusionProcess)) {
    if ($process) { Add-MpPreference -ExclusionProcess $process -ErrorAction Stop }
  }
  foreach ($extension in @($data.ExclusionExtension)) {
    if ($extension) { Add-MpPreference -ExclusionExtension $extension -ErrorAction Stop }
  }
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw 'Execute este instalador com pwsh 7 ou superior.'
}

if (-not $ProfileOnly -and -not (Test-Administrator)) {
  throw 'Execute a instalacao completa em um pwsh aberto como Administrador. Use -ProfileOnly para configurar somente o perfil.'
}

if (-not $ProfileOnly) {
  if ($SkipPackages) {
    Write-Host '[1/4] Pacotes do winget: etapa ja executada' -ForegroundColor DarkGray
  } else {
    Write-Host '[1/4] Pacotes do winget' -ForegroundColor Yellow
    Install-Packages
  }

  Write-Host '[2/4] LazyVim' -ForegroundColor Yellow
  Sync-LazyVim

  Write-Host '[3/4] Windows Terminal' -ForegroundColor Yellow
  Install-TerminalSettings
}

Write-Host '[4/4] Profile e PSReadLine' -ForegroundColor Yellow
Install-Profile

if ($RestoreDefenderExclusions) {
  Restore-Defender
}

if ($UpgradeAll) {
  Assert-Command winget
  $wingetArgs = @('upgrade', '--all', '--accept-package-agreements', '--accept-source-agreements', '--silent', '--disable-interactivity')
  Invoke-Winget -Arguments $wingetArgs -Action 'winget upgrade --all'
}

Write-Host 'Instalacao concluida. Abra um novo pwsh para carregar o PROFILE.' -ForegroundColor Green
