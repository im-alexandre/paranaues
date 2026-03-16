# install_paranaues.ps1
# Xandão Labs 🧪 — bootstrap declarativo da workstation
# Pré-req: rodar como Admin (o script relança elevado).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ROOT          = Split-Path -Parent $MyInvocation.MyCommand.Path

$WINGET_FILE      = Join-Path $ROOT "windows\winget-packages.json"
$CHOCO_FILE       = Join-Path $ROOT "windows\packages.config"
$TERMINAL_REPO    = Join-Path $ROOT "windows\terminal_settings.json"
$DEFENDER_FILE    = Join-Path $ROOT "windows\defender_exclusions.json"
$USER_PATH_FILE   = Join-Path $ROOT "windows\user_path.txt"

$LAZYVIM_REPO  = "https://github.com/im-alexandre/lazyvim_config"
$LAZYVIM_DIR   = Join-Path $env:USERPROFILE "nvim"

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
  if (Get-Command $Name -ErrorAction SilentlyContinue) { return }
  throw "Comando '$Name' não encontrado. $Hint"
}

function Try-WingetInstall([string]$Id) {
  & winget install --id $Id -e --accept-package-agreements --accept-source-agreements --silent `
    --disable-interactivity | Out-Host
}

function Get-TerminalTargets {
  $targets = @()

  $stable  = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
  $preview = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"

  if (Test-Path (Split-Path $stable -Parent))  { $targets += $stable }
  if (Test-Path (Split-Path $preview -Parent)) { $targets += $preview }

  return $targets
}

function Force-Symlink([string]$LinkPath, [string]$TargetPath) {
  $dir = Split-Path $LinkPath -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

  if (Test-Path $LinkPath) {
    try { Copy-Item $LinkPath "$LinkPath.bak" -Force } catch {}
    Remove-Item $LinkPath -Force
  }

  New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
}

function Patch-TerminalRepoJsonInPlace([string]$PwshPath, [string]$WinPsPath) {
  if (-not (Test-Path $TERMINAL_REPO)) {
    throw "terminal_settings.json não encontrado no repo: $TERMINAL_REPO"
  }

  $json = Get-Content -Raw -Encoding UTF8 $TERMINAL_REPO | ConvertFrom-Json

  if (-not $json.profiles -or -not $json.profiles.list) {
    throw "terminal_settings.json não tem 'profiles.list'."
  }

  foreach ($p in $json.profiles.list) {
    if ($p.name -eq "PowerShell" -or $p.name -eq "PowerShell (Admin)") {
      $p.commandline = $PwshPath
    }
    if ($p.name -eq "Windows PowerShell") {
      $p.commandline = $WinPsPath
    }
  }

  $out = $json | ConvertTo-Json -Depth 64
  Set-Content -Path $TERMINAL_REPO -Value $out -Encoding UTF8
}

Write-Host "=== Xandão Labs :: Install Paranauês 🧪 ===" -ForegroundColor Cyan
Write-Host "Repo: $ROOT" -ForegroundColor DarkGray

# --------------------------------------------------
# 1) winget import (faz o grosso)
# --------------------------------------------------
Write-Host "`n[1/4] winget import..." -ForegroundColor Yellow
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

# --------------------------------------------------
# 2) choco install packages.config
# --------------------------------------------------
Write-Host "`n[2/4] choco install..." -ForegroundColor Yellow
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  Write-Host "Chocolatey não encontrado. Tentando winget install Chocolatey.Chocolatey..." -ForegroundColor DarkYellow
  Try-WingetInstall "Chocolatey.Chocolatey"
}

Ensure-Command choco "Inclui Chocolatey no winget-packages.json ou instala manualmente."

if (Test-Path $CHOCO_FILE) {
  & choco install $CHOCO_FILE -y --no-progress
  choco upgrade all -y --no-progress | Out-Host
} else {
  Write-Host "packages.config não encontrado. Pulando." -ForegroundColor DarkYellow
}

# --------------------------------------------------
# 3) lazyvim_config (clone/pull) -> $HOME\nvim
# --------------------------------------------------
Write-Host "`n[3/4] lazyvim_config..." -ForegroundColor Yellow
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
Write-Host "`n[4/4] Windows Terminal settings (mklink + patch paths)..." -ForegroundColor Yellow

$targets = Get-TerminalTargets
if ($targets.Count -eq 0) {
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
# 5) Windows Defender Restore Exclusions
# --------------------------------------------------
Write-Host "`n[5/6] Windows Defender (Restore Exclusions)..." -ForegroundColor Yellow
if (Test-Path $DEFENDER_FILE) {
  try {
    $defData = Get-Content -Raw -Encoding UTF8 $DEFENDER_FILE | ConvertFrom-Json
    
    if ($defData.ExclusionPath -and $defData.ExclusionPath.Count -gt 0) {
      Write-Host "Restaurando ExclusionPaths: $($defData.ExclusionPath -join ', ')" -ForegroundColor DarkGray
      foreach ($ep in $defData.ExclusionPath) { Add-MpPreference -ExclusionPath $ep -ErrorAction SilentlyContinue }
    }
    
    if ($defData.ExclusionProcess -and $defData.ExclusionProcess.Count -gt 0) {
      Write-Host "Restaurando ExclusionProcess: $($defData.ExclusionProcess -join ', ')" -ForegroundColor DarkGray
      foreach ($eproc in $defData.ExclusionProcess) { Add-MpPreference -ExclusionProcess $eproc -ErrorAction SilentlyContinue }
    }
    
    if ($defData.ExclusionExtension -and $defData.ExclusionExtension.Count -gt 0) {
      Write-Host "Restaurando ExclusionExtension: $($defData.ExclusionExtension -join ', ')" -ForegroundColor DarkGray
      foreach ($eext in $defData.ExclusionExtension) { Add-MpPreference -ExclusionExtension $eext -ErrorAction SilentlyContinue }
    }
    Write-Host "Exclusões do Defender aplicadas com sucesso." -ForegroundColor Green
  } catch {
    Write-Host "Erro ao aplicar regras do Defender. Pulei." -ForegroundColor DarkYellow
  }
} else {
  Write-Host "Arquivo defender_exclusions.json não encontrado. Pulando." -ForegroundColor DarkYellow
}

# --------------------------------------------------
# 6) User Environment PATH Restore
# --------------------------------------------------
Write-Host "`n[6/6] User PATH variables (Restore)..." -ForegroundColor Yellow
if (Test-Path $USER_PATH_FILE) {
  $customPaths = Get-Content -Encoding UTF8 $USER_PATH_FILE | Where-Object { $_.Trim() -ne "" }
  if ($customPaths -and $customPaths.Count -gt 0) {
    $currentUserPathRaw = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $currentUserPaths = ($currentUserPathRaw -split ';') | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.ToLowerInvariant().TrimEnd('\') }
    
    $pathsToAdd = @()
    foreach ($cp in $customPaths) {
      $normalizedCp = $cp.ToLowerInvariant().TrimEnd('\')
      if (-not ($currentUserPaths -contains $normalizedCp)) {
        $pathsToAdd += $cp
      }
    }
    
    if ($pathsToAdd.Count -gt 0) {
      # Apenda apenas os caminhos que realmente faltam no usuário
      $newTotalPath = $currentUserPathRaw.TrimEnd(';') + ";" + ($pathsToAdd -join ";")
      [Environment]::SetEnvironmentVariable("Path", $newTotalPath, [EnvironmentVariableTarget]::User)
      Write-Host "Adicionados ao PATH do Usuário: $($pathsToAdd -join ', ')" -ForegroundColor Green
    } else {
      Write-Host "Todos os caminhos personalizados de usuário já existem no PATH atual." -ForegroundColor DarkGray
    }
  } else {
      Write-Host "O arquivo de PATHs existe mas está vazio. Pulando." -ForegroundColor DarkGray
  }
} else {
  Write-Host "Arquivo user_path.txt não encontrado. Pulando." -ForegroundColor DarkYellow
}

# --------------------------------------------------
# UPGRADE FINAL (latest garantido)
# --------------------------------------------------
Write-Host "`n[UPGRADE] winget upgrade --all..." -ForegroundColor Yellow
try {
  winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --disable-interactivity | Out-Host
} catch {
  Write-Host "winget upgrade --all falhou (seguindo o baile)." -ForegroundColor DarkYellow
}

Write-Host "`n[UPGRADE] choco upgrade all..." -ForegroundColor Yellow
try {
  choco upgrade all -y --no-progress | Out-Host
} catch {
  Write-Host "choco upgrade all falhou (seguindo o baile)." -ForegroundColor DarkYellow
}

# --------------------------------------------------
# ABRIR MENU DO NEOVIM (pós-install)
# --------------------------------------------------
$menuScript = Join-Path $ROOT "windows\menu_open_neovim.ps1"
if (Test-Path $menuScript) {
  Write-Host "`n[MENU] Chamando menu_open_neovim.ps1..." -ForegroundColor Yellow
  try { & $menuScript } catch { Write-Host "menu_open_neovim.ps1 falhou (seguindo o baile)." -ForegroundColor DarkYellow }
} else {
  Write-Host "`n[MENU] menu_open_neovim.ps1 não encontrado no repo. Pulando." -ForegroundColor DarkYellow
}

# =========================================================
# FIX PERMISSIONS + REMOVE MARK-OF-THE-WEB (Zone.Identifier)
# Target: C:\tools
# =========================================================

Write-Host "Fixing ownership and permissions for C:\tools..."

# Take ownership
takeown /F C:\tools /R /D Y | Out-Null

# Ensure inheritance is enabled
icacls C:\tools /inheritance:e /T /C | Out-Null

# Set current user as owner
icacls C:\tools /setowner "$env:USERNAME" /T /C | Out-Null

# Grant full control to current user
icacls C:\tools /grant "$env:USERNAME:(OI)(CI)F" /T /C | Out-Null

Write-Host "Removing Zone.Identifier (Mark-of-the-Web) streams..."

# Remove Zone.Identifier alternate data streams
Get-ChildItem C:\tools -Recurse -Force -ErrorAction SilentlyContinue -Stream Zone.Identifier |
Remove-Item -Force -ErrorAction SilentlyContinue

# Unblock files just in case
Get-ChildItem C:\tools -Recurse -Force -ErrorAction SilentlyContinue |
Unblock-File -ErrorAction SilentlyContinue

Write-Host "Permissions and Zone.Identifier cleanup completed."

Write-Host "Linkando o settings para o terminal"
$repo = Join-Path $ROOT "windows\terminal_settings.json"
$dst  = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

$ErrorActionPreference = "Stop"

Write-Host "Instalando o PowerShellEditorServices"
winget install -e --id Microsoft.DotNet.SDK.8

if (-not (Test-Path "$HOME\PowerShellEditorServices")) {
    git clone "https://github.com/PowerShell/PowerShellEditorServices.git" "$HOME\PowerShellEditorServices"
}

pwsh -NoLogo -NoProfile -Command "Set-Location $HOME\PowerShellEditorServices; .\PowerShellEditorServices.build.ps1"
pwsh -NoLogo -NoProfile -Command "Install-Module -Name platyPS -RequiredVersion 0.14.2 -Scope CurrentUser -Force"
pwsh -NoLogo -NoProfile -Command "Get-Module -ListAvailable platyPS | Select-Object Name, Version, Path"
pwsh -NoLogo -NoProfile -Command "dotnet --list-sdks"
pwsh -NoLogo -NoProfile -Command "dotnet --version"


Remove-Item $dst -Force -ErrorAction SilentlyContinue; New-Item -ItemType SymbolicLink -Path $dst -Target $repo -Force | Out-Null

Write-Host "`n=== FIM :: RECEBA 🧪😈 ===" -ForegroundColor Cyan
