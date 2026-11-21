#Requires -Version 7.0
[CmdletBinding()]
param(
  [switch]$ProfileOnly,
  [switch]$TerminalOnly,
  [switch]$SkipPackages,
  [switch]$UpgradeAll,
  [switch]$RestoreDefenderExclusions,
  [string[]]$OnlyPackageIds = @(),
  [string[]]$SkipPackageIds = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$helpersRepo = Join-Path $root 'windows\PowerShell\helpers'
$packagesFile = Join-Path $root 'windows\winget-packages.json'
$terminalRepo = Join-Path $root 'windows\terminal_settings.json'
$defenderFile = Join-Path $root 'windows\defender_exclusions.json'
$lazyVimDir = Join-Path $env:LOCALAPPDATA 'nvim'
$lazyVimRepo = 'https://github.com/im-alexandre/lazyvim_config'
. (Join-Path $root 'windows\PowerShell\module-path.ps1')

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
  $originalSettings = if ($proxyValue -and $settingsExisted) { [IO.File]::ReadAllBytes($settingsPath) } else { $null }
  $settingsChanged = $false
  $bridge = $null
  $bridgeOut = $null
  $bridgeErr = $null

  try {
    if ($proxyValue) {
      $settings = if ($settingsExisted) { [IO.File]::ReadAllText($settingsPath) | ConvertFrom-Json -AsHashtable } else { @{} }
      if (-not $settings.ContainsKey('source') -or -not $settings['source']) {
        $settings['source'] = @{}
      }
      $settings['source']['autoUpdateIntervalInMinutes'] = 0
      New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
      $settingsChanged = $true
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
        $bridge = Start-Process -FilePath (Get-Command node).Source -ArgumentList "`"$bridgeScript`"" -PassThru -WindowStyle Hidden -RedirectStandardOutput $bridgeOut -RedirectStandardError $bridgeErr
        $port = $null
        for ($i = 0; $i -lt 100; $i++) {
          Start-Sleep -Milliseconds 100
          if (Test-Path -LiteralPath $bridgeOut) {
            $port = ([IO.File]::ReadAllText($bridgeOut)).Trim()
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
    if ($settingsChanged) {
      if ($settingsExisted) {
        [IO.File]::WriteAllBytes($settingsPath, $originalSettings)
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

function Read-ConfigFile($Item) {
  if (-not $Item) { return '' }
  if ($Item.PSIsContainer) { throw "O caminho e um diretorio: $($Item.FullName)" }
  $path = if ($Item.LinkType -eq 'SymbolicLink') { $Item.ResolveLinkTarget($true).FullName } else { $Item.FullName }
  if (-not [IO.File]::Exists($path)) { return '' }
  try {
    [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false, $true))
  } catch [Text.DecoderFallbackException] {
    $encoding = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)
    [IO.File]::ReadAllText($path, $encoding)
  }
}

function Install-ConfigFile([string]$Path, [string]$Content, [switch]$Utf8Bom) {
  $existing = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if ($existing) {
    if ($existing.PSIsContainer) { throw "O caminho e um diretorio: $Path" }
    if (-not $existing.LinkType -and [IO.File]::ReadAllText($Path) -ceq $Content) { return }
  }
  New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
  $temporaryPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
  try {
    [IO.File]::WriteAllText($temporaryPath, $Content, [Text.UTF8Encoding]::new($Utf8Bom.IsPresent))
    [IO.File]::Move($temporaryPath, $Path, $true)
  } finally {
    [IO.File]::Delete($temporaryPath)
  }
  Write-Host "Configurado: $Path" -ForegroundColor Green
}

function Install-PowerShellProfiles {
  param(
    [string]$DocumentsDirectory = [Environment]::GetFolderPath('MyDocuments'),
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'Paranaues')
  )
  $loader = [IO.File]::ReadAllText((Join-Path $root 'windows\profile-loader.ps1')).TrimEnd()
  $helperFiles = @(Get-ChildItem -LiteralPath $helpersRepo -Filter '*.ps1' -File)
  $profileFiles = @('PowerShell\profile.ps1', 'PowerShell\module-path.ps1')
  $profileFiles += $helperFiles | ForEach-Object { "PowerShell\helpers\$($_.Name)" }
  foreach ($file in $profileFiles) {
    $source = Join-Path $root "windows\$file"
    Install-ConfigFile -Path (Join-Path $InstallDirectory $file) -Content ([IO.File]::ReadAllText($source)) -Utf8Bom
  }
  $installedHelpers = Join-Path $InstallDirectory 'PowerShell\helpers'
  foreach ($helper in Get-ChildItem -LiteralPath $installedHelpers -Filter '*.ps1' -File) {
    if ($helper.Name -notin $helperFiles.Name) { [IO.File]::Delete($helper.FullName) }
  }
  Install-ConfigFile -Path (Join-Path $InstallDirectory 'checkout.txt') -Content $root

  $managedBlock = '(?ms)^# >>> Paranaues >>>\r?\n.*?^# <<< Paranaues <<<(?:\r?\n|\z)'
  $oldProfilePath = '[\\/]windows[\\/](?:Windows)?PowerShell[\\/]profile\.ps1'
  $oldHostPath = '[\\/]windows[\\/](?:Windows)?PowerShell[\\/]Microsoft\.PowerShell_profile\.ps1'
  foreach ($edition in 'PowerShell', 'WindowsPowerShell') {
    $directory = Join-Path $DocumentsDirectory $edition
    $path = Join-Path $directory 'profile.ps1'
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    $existing = if ($item -and $item.Target -match "$oldProfilePath`$") { '' } else { Read-ConfigFile $item }
    if ($existing.Trim() -match "^\. '[^\r\n]+$oldProfilePath'`$") {
      $existing = ''
    }
    $match = [regex]::Match($existing, $managedBlock)
    $content = if ($match.Success) {
      $existing.Remove($match.Index, $match.Length).Insert($match.Index, "$loader`r`n")
    } elseif ($existing.Trim()) {
      "$($existing.TrimEnd())`r`n`r`n$loader`r`n"
    } else {
      "$loader`r`n"
    }
    Install-ConfigFile -Path $path -Content $content -Utf8Bom

    $hostProfile = Get-Item -LiteralPath (Join-Path $directory 'Microsoft.PowerShell_profile.ps1') -Force -ErrorAction SilentlyContinue
    if ($hostProfile -and -not $hostProfile.PSIsContainer) {
      if ($hostProfile.Target -match "$oldHostPath`$") {
        [IO.File]::Delete($hostProfile.FullName)
      } elseif (-not $hostProfile.LinkType) {
        $hostContent = (Read-ConfigFile $hostProfile).Trim()
        if ($hostContent -match "^\. '[^\r\n]+$oldHostPath'`$" -or
            $hostContent -match '(?s)\A# >>> Paranaues Console >>>\r?\n.*\r?\n# <<< Paranaues Console <<<\z') {
          [IO.File]::Delete($hostProfile.FullName)
        }
      }
    }
    $helperLink = Get-Item -LiteralPath (Join-Path $directory 'helpers') -Force -ErrorAction SilentlyContinue
    if ($helperLink -and $helperLink.LinkType -eq 'SymbolicLink' -and
        $helperLink.Target -match '[\\/]windows[\\/]PowerShell[\\/]helpers[\\/]?$') {
      [IO.Directory]::Delete($helperLink.FullName)
    }
  }

  $oldLocalProfile = Join-Path $InstallDirectory 'WindowsPowerShell\profile.ps1'
  if ([IO.File]::Exists($oldLocalProfile) -and
      [IO.File]::ReadAllText($oldLocalProfile).Trim() -ceq '. (Join-Path $PSScriptRoot ''..\PowerShell\profile.ps1'')') {
    [IO.File]::Delete($oldLocalProfile)
  }
}

function Set-LocalPowerShellModules {
  $modules = Join-Path $env:LOCALAPPDATA 'PowerShell\Modules'
  New-Item -ItemType Directory -Path $modules -Force | Out-Null

  # O config do PS7 evita que ele volte a acrescentar Documentos mesmo com -NoProfile.
  $configPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\powershell.config.json'
  $config = @{}
  if ([IO.File]::Exists($configPath)) {
    $config = [IO.File]::ReadAllText($configPath) | ConvertFrom-Json -AsHashtable
  }
  $modulePath = Get-ParanauesModulePath -Value $config['PSModulePath'] -ModulesDirectory '%LOCALAPPDATA%\PowerShell\Modules'
  if ($config['PSModulePath'] -ne $modulePath) {
    $config['PSModulePath'] = $modulePath
    Install-ConfigFile -Path $configPath -Content ($config | ConvertTo-Json -Depth 32)
  }

  $userModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
  $newModulePath = Get-ParanauesModulePath -Value $userModulePath
  if ($userModulePath -ne $newModulePath) {
    [Environment]::SetEnvironmentVariable('PSModulePath', $newModulePath, 'User')
  }
  $env:PSModulePath = Get-ParanauesModulePath -Value $env:PSModulePath

  $bundled = Join-Path $root 'windows\PowerShell\Modules\PSReadLine'
  $installed = Join-Path $modules 'PSReadLine'
  foreach ($file in Get-ChildItem -LiteralPath $bundled -Recurse -File -Force) {
    $target = Join-Path $installed ([IO.Path]::GetRelativePath($bundled, $file.FullName))
    if (Test-Path -LiteralPath $target -PathType Leaf) { continue }
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target
  }
  Write-Host "Modulos locais: $modules" -ForegroundColor Green
}

function Install-Packages {
  Assert-Command winget
  if (-not (Test-Path -LiteralPath $packagesFile -PathType Leaf)) {
    throw "Lista de pacotes nao encontrada: $packagesFile"
  }

  $importFile = $packagesFile
  if ($SkipPackageIds.Count -gt 0 -or $OnlyPackageIds.Count -gt 0) {
    $skipIds = @($SkipPackageIds | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $onlyIds = @($OnlyPackageIds | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $importData = Get-Content -LiteralPath $packagesFile -Raw | ConvertFrom-Json -AsHashtable
    foreach ($source in $importData['Sources']) {
      $source['Packages'] = @($source['Packages'] | Where-Object {
        ($onlyIds.Count -eq 0 -or $onlyIds -contains $_['PackageIdentifier']) -and
        $skipIds -notcontains $_['PackageIdentifier']
      })
    }
    $importData['Sources'] = @($importData['Sources'] | Where-Object { $_['Packages'].Count -gt 0 })
    if ($importData['Sources'].Count -eq 0) { return }
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

  $paths = @(
    $env:Path,
    [Environment]::GetEnvironmentVariable('Path', 'Machine'),
    [Environment]::GetEnvironmentVariable('Path', 'User')
  ) -split ';' | Where-Object { $_ } | Select-Object -Unique
  $env:Path = $paths -join ';'
}

function Install-LazyVim {
  if (Test-Path -LiteralPath $lazyVimDir) { return }
  Assert-Command git
  & git clone $lazyVimRepo $lazyVimDir | Out-Host
  Assert-ExitCode 'git clone lazyvim_config'
}

function Install-TerminalSettings {
  if (-not (Test-Path -LiteralPath $terminalRepo -PathType Leaf)) {
    throw "Configuracao do Terminal nao encontrada: $terminalRepo"
  }
  $content = [IO.File]::ReadAllText($terminalRepo)
  $null = ConvertFrom-Json -InputObject $content
  $localStateDirs = @(
    Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal'
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState'
  )
  foreach ($localState in $localStateDirs) {
    if (-not (Test-Path -LiteralPath $localState -PathType Container)) { continue }
    $path = Join-Path $localState 'settings.json'
    $existing = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    $current = Read-ConfigFile $existing
    if ($current) {
      try {
        if ((ConvertFrom-Json -InputObject $current -AsHashtable) -is [System.Collections.IDictionary]) {
          if ($existing.LinkType) { Install-ConfigFile -Path $path -Content $current }
          continue
        }
      } catch [System.ArgumentException] {
        # Um arquivo com JSON invalido precisa ser substituido.
      }
    }
    Install-ConfigFile -Path $path -Content $content
  }
}

function Restore-Defender {
  if (-not (Test-Path -LiteralPath $defenderFile -PathType Leaf)) {
    throw "Exclusoes do Defender nao encontradas: $defenderFile"
  }
  Assert-Command Get-MpPreference
  $data = Get-Content -LiteralPath $defenderFile -Raw | ConvertFrom-Json
  $current = Get-MpPreference
  $changes = @{}
  foreach ($kind in 'ExclusionPath', 'ExclusionProcess', 'ExclusionExtension') {
    $missing = @($data.$kind | Where-Object { $_ -and $_ -notin $current.$kind })
    if ($missing.Count) { $changes[$kind] = $missing }
  }
  if ($changes.Count) { Add-MpPreference @changes }
}

$fullInstall = -not ($ProfileOnly -or $TerminalOnly)
if ($RestoreDefenderExclusions -and -not (Test-Administrator)) {
  throw 'Abra o PowerShell como administrador para restaurar as exclusoes do Defender.'
}

if ($fullInstall) {
  if ($SkipPackages) {
    Write-Host '[1/4] Pacotes do winget: etapa ja executada' -ForegroundColor DarkGray
  } else {
    Write-Host '[1/4] Pacotes do winget' -ForegroundColor Yellow
    Install-Packages
  }

  Write-Host '[2/4] LazyVim' -ForegroundColor Yellow
  Install-LazyVim
}

if ($fullInstall -or $TerminalOnly) {
  Write-Host '[3/4] Windows Terminal' -ForegroundColor Yellow
  Install-TerminalSettings
}

if ($fullInstall -or $ProfileOnly) {
  Write-Host '[4/4] Perfis e modulos do PowerShell' -ForegroundColor Yellow
  Install-PowerShellProfiles
  Set-LocalPowerShellModules
  Write-Host 'Abra um novo PowerShell para carregar o perfil.' -ForegroundColor Green
}

if ($RestoreDefenderExclusions) {
  Restore-Defender
}

if ($UpgradeAll) {
  Assert-Command winget
  $wingetArgs = @('upgrade', '--all', '--accept-package-agreements', '--accept-source-agreements', '--silent', '--disable-interactivity')
  Invoke-Winget -Arguments $wingetArgs -Action 'winget upgrade --all'
}

Write-Host 'Instalacao concluida.' -ForegroundColor Green
