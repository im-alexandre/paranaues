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
