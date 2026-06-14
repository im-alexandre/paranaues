function ollama-docker {
  param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
  )

  Write-Host "OLLAMA CPU"
  docker exec -it ollama-cpu /usr/bin/ollama @Args

  Write-Host ""
  Write-Host "******************************"
  Write-Host ""

  Write-Host "OLLAMA GPU"
  docker exec -it ollama-gpu /usr/bin/ollama @Args
}

function cdf {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Path = $HOME
  )

  if ($Path -eq '-') {
    Set-Location -
    return
  }

  try {
    $base = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
  } catch {
    Write-Error "cdf: diretório inválido: $Path"
    return
  }

  $items = @($base)

  if (Get-Command fd -ErrorAction SilentlyContinue) {
    $subs = & fd . $base --type directory --max-depth 4 --hidden --follow --exclude .git 2>$null
    if ($subs) {
      $items += $subs
    }
  } else {
    $subs = Get-ChildItem -LiteralPath $base -Directory -Recurse -Force -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty FullName
    if ($subs) {
      $items += $subs
    }
  }

  $preview = 'powershell -NoLogo -NoProfile -Command "Get-ChildItem -LiteralPath ''{}'' -Force | Select-Object Mode,LastWriteTime,Name | Format-Table -AutoSize | Out-String -Width 200"'

  $target = $items |
    Where-Object { $_ -and $_.Trim() } |
    Select-Object -Unique |
    fzf --prompt "Diretórios [$base]> " --height 80% --reverse --preview $preview

  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($target)) {
    return
  }

  Set-Location -LiteralPath $target
}

Set-Alias "v" "nvim"
Set-Alias "lg" "lazygit"

function agenthub {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
  )

  $agenthubGui = "$env:LOCALAPPDATA\Programs\AgentHub\agenthub.exe"
  $agenthubConsole = "$env:LOCALAPPDATA\Programs\AgentHub\agenthub-console.exe"

  if ($Args.Count -eq 0) {
    & $agenthubGui
    return
  }

  if (Test-Path -LiteralPath $agenthubConsole) {
    & $agenthubConsole @Args
    return
  }

  & $agenthubGui @Args
}

$env:EDITOR = "code --wait --reuse-window"
$env:VISUAL = "code --wait --reuse-window"

function nc {
  Set-Location $env:LOCALAPPDATA\nvim
  nvim .
  Set-Location -
}

function np {
  Set-Location (Split-Path -Parent $PROFILE)
  nvim $PROFILE
  Set-Location -
}

Remove-Item Function:\conda -ErrorAction SilentlyContinue
if (Get-Command Remove-Alias -ErrorAction SilentlyContinue) {
  Remove-Alias conda -ErrorAction SilentlyContinue
} else {
  Remove-Item Alias:\conda -ErrorAction SilentlyContinue
}

$condaExe = "C:\tools\miniforge3\Scripts\conda.exe"

function conda {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$RemainingArgs
  )

  $argv = @(
    foreach ($arg in $RemainingArgs) {
      if ($null -ne $arg) {
        $s = "$arg"
        if (-not [string]::IsNullOrWhiteSpace($s)) {
          $s
        }
      }
    }
  )

  if ($argv.Count -eq 0) {
    & $condaExe
    return
  }

  switch -Regex ($argv[0]) {
    '^(activate|deactivate)$' {
      $cmd = (& $condaExe "shell.powershell" @argv) -join "`n"
      if (-not [string]::IsNullOrWhiteSpace($cmd)) {
        Invoke-Expression $cmd
      }
      return
    }
    default {
      & $condaExe @argv
      return
    }
  }
}

$env:CONDA_EXE = $condaExe
$env:_CE_M = ""
$env:_CE_CONDA = ""
$env:CONDA_PYTHON_EXE = "C:\tools\miniforge3\python.exe"

function prompt {
  $pathInfo = $executionContext.SessionState.Path.CurrentLocation
  if ($env:WT_SESSION -and $pathInfo.Provider.Name -eq 'FileSystem') {
    Write-Host "$([char]27)]9;9;$($pathInfo.ProviderPath)$([char]7)" -NoNewline
  }

  $limit = 25
  $psTag = if ($PSVersionTable.PSVersion.Major -ge 7) {
    '[PS-7]'
  } else {
    '[PS-5]'
  }

  if (-not $env:PANE -and $host.UI.RawUI.WindowTitle -match 'PANE\s+(\d+)') {
    $env:PANE = $Matches[1]
  }

  $parts = (Get-Location).Path.Split([IO.Path]::DirectorySeparatorChar)
  $short = ($parts | Select-Object -Last 2) -join "\"

  $pane = ''
  $condaEnv = $null
  if ($env:CONDA_DEFAULT_ENV) {
    $condaEnv = ($env:CONDA_DEFAULT_ENV -split '\\')[-1]
  }

  $t = $host.UI.RawUI.WindowTitle
  if ($t -match 'PANE\s+(\d+)') {
    $pane = $Matches[1]
  }

  if ($short.Length -gt $limit) {
    $title = ($parts | Select-Object -Last 1)
  } else {
    $title = $short
  }

  if ($host.UI.RawUI.WindowTitle -ne $title) {
    $host.UI.RawUI.WindowTitle = $title
  }

  $branch = ''
  try {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($branch -and $branch -ne 'HEAD') {
      $branch = "[git $branch]"
    } else {
      $branch = ''
    }
  } catch {
  }

  $isAdmin = $false
  try {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
      [Security.Principal.WindowsBuiltInRole]::Administrator
    )
  } catch {
    $isAdmin = $false
  }

  if ($isAdmin) {
    Write-Host "(ADMIN-MODE)" -NoNewline -ForegroundColor Black -BackgroundColor White
    $host.UI.RawUI.WindowTitle = "ADMIN-MODE: " + $title
  }

  if ($condaEnv) {
    Write-Host "($condaEnv)" -NoNewline -ForegroundColor Yellow
  }

  Write-Host $psTag -NoNewline -ForegroundColor Magenta
  Write-Host "{${env:COMPUTERNAME}}" -NoNewline -ForegroundColor DarkGreen

  if ($pane) {
    Write-Host "[$pane]" -NoNewline -ForegroundColor White
  }

  Write-Host $short -NoNewline -ForegroundColor Cyan

  if ($branch) {
    Write-Host $branch -NoNewline -ForegroundColor White
  }

  return "`n$ "
}

function open_splits {
  param([string]$ProfileName = "PowerShell")

  & wt -w 0 `
    new-tab     -p $ProfileName --title "PANE 1" ';' `
    split-pane  -V -p $ProfileName --title "PANE 2" ';' `
    split-pane  -H -p $ProfileName --title "PANE 3" ';' `
    focus-pane  -t 0 ';' `
    split-pane  -H -p $ProfileName --title "PANE 4"
}

function unzip {
  param (
    [Parameter(Mandatory = $true)]
    [string]$InputZip,

    [Parameter(Mandatory = $true)]
    [string]$OutputDir
  )

  Expand-Archive -Path $InputZip -DestinationPath $OutputDir -Force
}

function source {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    return
  }

  Get-Content $Path | ForEach-Object {
    if (-not ([string]::IsNullOrWhiteSpace($_)) -and -not ($_.StartsWith("#"))) {
      $parts = $_.Split('=', 2)
      if ($parts.Length -eq 2) {
        $name = $parts[0].Trim()
        $value = $parts[1].Trim()
        Set-Item -Path "Env:$name" -Value $value
        Write-Host "Set environment variable: $name = $value"
      }
    }
  }
}

function rmdirf {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-Not (Test-Path $Path)) {
    Write-Host "❌ Caminho não encontrado: $Path" -ForegroundColor Red
    return
  }

  try {
    Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
    Write-Host "✅ Pasta removida: $Path" -ForegroundColor Green
  } catch {
    Write-Host "⚠️ Erro ao remover: $_" -ForegroundColor Yellow
  }
}

$psReadLinePath = Join-Path $PSHOME "Modules\PSReadLine\PSReadLine.psd1"
if (Test-Path -LiteralPath $psReadLinePath) {
  Import-Module $psReadLinePath -ErrorAction SilentlyContinue

  try {
    Set-PSReadLineOption -EditMode Vi -ErrorAction Stop
    Set-PSReadLineOption -ViModeIndicator Cursor -ErrorAction Stop

    try {
      Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
    } catch {
      Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction SilentlyContinue
    }
  } catch {
  }

  $historyForward = {
    param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchForward($key, $arg)
  }

  $historyBackward = {
    param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchBackward($key, $arg)
  }

  try {
    Set-PSReadLineKeyHandler -ViMode Insert -Chord 'Ctrl+n' -ScriptBlock $historyForward -BriefDescription 'History search forward'
    Set-PSReadLineKeyHandler -ViMode Insert -Chord 'Ctrl+p' -ScriptBlock $historyBackward -BriefDescription 'History search backward'
    Set-PSReadLineKeyHandler -ViMode Command -Chord 'v' -Function ViEditVisually -BriefDescription 'Edit command line visually'
    Set-PSReadLineKeyHandler -Chord 'Ctrl+n' -ScriptBlock $historyForward -BriefDescription 'History search forward'
    Set-PSReadLineKeyHandler -Chord 'Ctrl+p' -ScriptBlock $historyBackward -BriefDescription 'History search backward'
  } catch {
  }
}
  
$shimDir = "$HOME\bin"
$shim = "$shimDir\code-wait.cmd"

New-Item -ItemType Directory -Force $shimDir | Out-Null

@'
@echo off
code --wait --reuse-window %*
'@ | Set-Content -Encoding ASCII $shim

$env:EDITOR = $shim
$env:VISUAL = $shim
