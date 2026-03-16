# dump_windows.ps1
# Xandão Labs 🧪 — Exporta o estado atual da máquina para o repositório

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

$WINGET_FILE    = Join-Path $ROOT "windows\winget-packages.json"
$CHOCO_FILE     = Join-Path $ROOT "windows\packages.config"
$DEFENDER_FILE  = Join-Path $ROOT "windows\defender_exclusions.json"
$USER_PATH_FILE = Join-Path $ROOT "windows\user_path.txt"

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
  Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  exit
}

Write-Host "=== Xandão Labs :: Dump Paranauês 🧪 ===" -ForegroundColor Cyan
Write-Host "Repo: $ROOT" -ForegroundColor DarkGray

# --------------------------------------------------
# 1) winget export (sem dependências exóticas e sem --include-versions)
# --------------------------------------------------
Write-Host "`n[1/4] winget export..." -ForegroundColor Yellow
if (Get-Command winget -ErrorAction SilentlyContinue) {
  # O export original suja muito o output se não lidar com erro, vamos usar Try/Catch básico
  try {
     & winget export -o $WINGET_FILE --accept-source-agreements --disable-interactivity | Out-Null
     Write-Host "Winget exportado com sucesso para $WINGET_FILE (Ignorando versões específicas para garantir latest no install)." -ForegroundColor Green
  } catch {
     Write-Host "Erro ao exportar Winget. Verifique se há pacotes corrompidos." -ForegroundColor Red
  }
} else {
  Write-Host "Comando 'winget' não encontrado." -ForegroundColor DarkYellow
}

# --------------------------------------------------
# 2) choco export
# --------------------------------------------------
Write-Host "`n[2/4] choco export..." -ForegroundColor Yellow
if (Get-Command choco -ErrorAction SilentlyContinue) {
  try {
    # Choco export nativamente gera o packages.config com as versoes
    & choco export -o "$(Join-Path $ROOT "windows")" --force --no-progress | Out-Null
    Write-Host "Chocolatey exportado para $CHOCO_FILE" -ForegroundColor Green
  } catch {
    Write-Host "Erro ao exportar Chocolatey." -ForegroundColor Red
  }
} else {
  Write-Host "Comando 'choco' não encontrado." -ForegroundColor DarkYellow
}

# --------------------------------------------------
# 3) Windows Defender Exclusions
# --------------------------------------------------
Write-Host "`n[3/4] Exportando exclusões do Windows Defender..." -ForegroundColor Yellow
try {
  $mp = Get-MpPreference
  $exclusions = @{
    ExclusionPath    = if ($mp.ExclusionPath) { $mp.ExclusionPath } else { @() }
    ExclusionProcess = if ($mp.ExclusionProcess) { $mp.ExclusionProcess } else { @() }
    ExclusionExtension = if ($mp.ExclusionExtension) { $mp.ExclusionExtension } else { @() }
  }

  $exclusions | ConvertTo-Json -Depth 3 | Set-Content $DEFENDER_FILE -Encoding UTF8
  Write-Host "Exclusões do Defender salvas em $DEFENDER_FILE" -ForegroundColor Green
} catch {
  Write-Host "Falha ao ler o Get-MpPreference. O serviço do Defender está ativo?" -ForegroundColor Red
}

# --------------------------------------------------
# 4) User PATH Extractor
# --------------------------------------------------
Write-Host "`n[4/4] Exportando variáveis de PATH customizadas..." -ForegroundColor Yellow

# Lendo o PATH local do usuário do Registro
$userPathRaw = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
$machinePathRaw = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)

$userPaths = ($userPathRaw -split ';') | Where-Object { $_.Trim() -ne "" }
$machinePaths = ($machinePathRaw -split ';') | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.ToLowerInvariant().TrimEnd('\') }

$customUserPaths = @()

foreach ($up in $userPaths) {
  # Filtra vazios e caminhos que coincidentemente também estão no Machine (System)
  $normalizedUp = $up.ToLowerInvariant().TrimEnd('\')
  if (-not ($machinePaths -contains $normalizedUp)) {
      $customUserPaths += $up
  }
}

if ($customUserPaths.Count -gt 0) {
    # Salva filtrado (só os paths exclusivos do usuário e não-vazios)
    $customUserPaths | Out-File -FilePath $USER_PATH_FILE -Encoding UTF8
    Write-Host "$($customUserPaths.Count) caminhos de usuário exclusivos exportados para $USER_PATH_FILE" -ForegroundColor Green
} else {
    Out-File -FilePath $USER_PATH_FILE -Encoding UTF8 -InputObject ""
    Write-Host "Nenhum caminho de usuário exclusivo encontrado. Arquivo resetado." -ForegroundColor DarkGray
}

Write-Host "`n=== DUMP CONCLUÍDO 🧪 ===" -ForegroundColor Cyan
