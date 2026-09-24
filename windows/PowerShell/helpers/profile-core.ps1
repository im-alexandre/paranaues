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

  if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Warning 'cdf precisa do fzf (incluido em windows/winget-packages.json).'
    return
  }

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

if (Get-Command nvim -ErrorAction SilentlyContinue) {
  Set-Alias 'v' 'nvim'
}
if (Get-Command lazygit -ErrorAction SilentlyContinue) {
  Set-Alias 'lg' 'lazygit'
}

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

$condaCommand = Get-Command conda.exe -CommandType Application -ErrorAction SilentlyContinue
if ($condaCommand) {
  $script:ParanauesCondaExe = $condaCommand.Source
  Remove-Item Alias:\conda -ErrorAction SilentlyContinue

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
      & $script:ParanauesCondaExe
      return
    }

    switch -Regex ($argv[0]) {
      '^(activate|deactivate)$' {
        $cmd = (& $script:ParanauesCondaExe 'shell.powershell' @argv) -join "`n"
        if (-not [string]::IsNullOrWhiteSpace($cmd)) {
          Invoke-Expression $cmd
        }
        return
      }
      default {
        & $script:ParanauesCondaExe @argv
        return
      }
    }
  }
}

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

try {
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    $helpersRoot = $PSScriptRoot
    $helpersItem = Get-Item -LiteralPath $helpersRoot
    if ($helpersItem.LinkType -eq 'SymbolicLink') {
      $helpersRoot = @($helpersItem.Target)[0]
    }
    $moduleManifest = Join-Path (Split-Path -Parent $helpersRoot) 'Modules\PSReadLine\2.4.5\PSReadLine.psd1'
    Import-Module $moduleManifest -Force -ErrorAction Stop
  } else {
    Import-Module PSReadLine -MinimumVersion 2.2.0 -Force -ErrorAction Stop
  }
  Set-PSReadLineOption -EditMode Vi -ErrorAction Stop
  Set-PSReadLineOption -ViModeIndicator Cursor -ErrorAction Stop

  try {
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
  } catch {
    Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction SilentlyContinue
  }

  $historyForward = {
    param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchForward($key, $arg)
  }

  $historyBackward = {
    param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchBackward($key, $arg)
  }

  Set-PSReadLineKeyHandler -ViMode Insert -Chord 'Ctrl+n' -ScriptBlock $historyForward -BriefDescription 'History search forward'
  Set-PSReadLineKeyHandler -ViMode Insert -Chord 'Ctrl+p' -ScriptBlock $historyBackward -BriefDescription 'History search backward'
  Set-PSReadLineKeyHandler -ViMode Command -Chord 'v' -Function ViEditVisually
  Set-PSReadLineKeyHandler -ViMode Command -Chord 'Ctrl+n' -ScriptBlock $historyForward -BriefDescription 'History search forward'
  Set-PSReadLineKeyHandler -ViMode Command -Chord 'Ctrl+p' -ScriptBlock $historyBackward -BriefDescription 'History search backward'
} catch {
  Write-Warning "PSReadLine/Vi nao configurado: $($_.Exception.Message)"
}

if (Get-Command code -ErrorAction SilentlyContinue) {
  $shimDir = Join-Path $HOME 'bin'
  $shim = Join-Path $shimDir 'code-wait.cmd'
  New-Item -ItemType Directory -Path $shimDir -Force | Out-Null
  if (-not (Test-Path -LiteralPath $shim)) {
    "@echo off`r`ncode --wait --reuse-window %*`r`n" | Set-Content -LiteralPath $shim -Encoding ASCII
  }
  $env:EDITOR = $shim
  $env:VISUAL = $shim
} elseif (Get-Command nvim -ErrorAction SilentlyContinue) {
  $env:EDITOR = (Get-Command nvim).Source
  $env:VISUAL = $env:EDITOR
}
