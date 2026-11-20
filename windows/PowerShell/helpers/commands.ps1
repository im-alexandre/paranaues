$script:ParanauesLoadingLocalProfile = $false

function Invoke-LocalProfile {
  $localProfile = Join-Path (Get-Location) '.profile.ps1'
  if ($script:ParanauesLoadingLocalProfile -or -not (Test-Path -LiteralPath $localProfile -PathType Leaf)) {
    return
  }
  $script:ParanauesLoadingLocalProfile = $true
  try {
    . $localProfile
  } finally {
    $script:ParanauesLoadingLocalProfile = $false
  }
}

# O alias nativo cd tem precedencia sobre funcoes com o mesmo nome.
if (Test-Path Alias:\cd) {
  Remove-Item Alias:\cd -Force
}
function cd {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)][string]$Path,
    [string]$LiteralPath,
    [string]$StackName,
    [switch]$PassThru
  )
  $PSBoundParameters['ErrorAction'] = 'Stop'
  Set-Location @PSBoundParameters
  Invoke-LocalProfile
}

function np {
  $directory = Split-Path -Parent $PSScriptRoot
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    $directory = Join-Path (Split-Path -Parent $directory) 'WindowsPowerShell'
  }
  Push-Location -LiteralPath $directory
  try {
    nvim (Join-Path $directory 'profile.ps1')
  } finally {
    Pop-Location
  }
}

function npm {
  & "$env:ProgramFiles\nodejs\npm.cmd" @args
}

function npx {
  & "$env:ProgramFiles\nodejs\npx.cmd" @args
}

function git-cp {
  & git commit -m @args
  if ($LASTEXITCODE -eq 0) {
    & git push
  }
}

Set-Alias v nvim
Set-Alias lg lazygit

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
    $subs = Get-ChildItem -LiteralPath $base -Directory -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
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

function gpoe {
  $directory = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'
  poe -C $directory @args
}

function nc {
  Set-Location -LiteralPath (Join-Path $env:LOCALAPPDATA 'nvim') -ErrorAction Stop
  nvim .
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

function rmdirf {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-Not (Test-Path -LiteralPath $Path)) {
    Write-Host "❌ Caminho não encontrado: $Path" -ForegroundColor Red
    return
  }

  try {
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
    Write-Host "✅ Pasta removida: $Path" -ForegroundColor Green
  } catch {
    Write-Host "⚠️ Erro ao remover: $_" -ForegroundColor Yellow
  }
}

function tf {
  if (Test-Path "./terraform" -PathType Container) {
    terraform -chdir=terraform @args
  } else {
    terraform @args
  }
}
