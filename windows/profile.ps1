function prompt
{
  $limit = 25

  if (-not $env:PANE -and $host.UI.RawUI.WindowTitle -match 'PANE\s+(\d+)')
  {
    $env:PANE = $Matches[1]
  }

  $parts = (Get-Location).Path.Split([IO.Path]::DirectorySeparatorChar)
  $short = ($parts | Select-Object -Last 2) -join "\"

  $pane = ''
  if ($env:CONDA_DEFAULT_ENV)
  {
    $condaEnv = ($env:CONDA_DEFAULT_ENV -split '\\')[-1]
  }

  $t = $host.UI.RawUI.WindowTitle
  if ($t -match 'PANE\s+(\d+)')
  { $pane = $Matches[1] 
  }
  #
  # título da janela (igual ao seu)
  if ($short.Length -gt $limit)
  { $title = ($parts | Select-Object -Last 1) 
  } else
  { $title = $short 
  }

  if ($host.UI.RawUI.WindowTitle -ne $title)
  {
    $host.UI.RawUI.WindowTitle = $title
  }

  # ---- Pega a branch do git -----
  $branch = ''
  try
  {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($branch -and $branch -ne 'HEAD')
    {
      $branch = "[🌱 $branch]"
    } else
    {
      $branch = ''
    }
  } catch
  {
  }

  # ---- linha colorida ----
  if ($condaEnv)
  { Write-Host "($condaEnv)" -NoNewline -ForegroundColor Yellow 
  }
  Write-Host "{${env:COMPUTERNAME}}" -NoNewline -ForegroundColor DarkGreen
  # Write-Host "->" -NoNewline -ForegroundColor White
  if ($pane)
  { Write-Host "[$pane]"    -NoNewline -ForegroundColor White 
  }
  Write-Host "$short"    -NoNewline -ForegroundColor Cyan
  if ($branch)
  { Write-host $branch -NoNewline -ForegroundColor White 
  }

  return "`n$ "
}

function open_splits
{
  param([string]$ProfileName = "PowerShell")

  & wt -w 0 `
    new-tab     -p $ProfileName --title "PANE 1" ';' `
    split-pane  -V -p $ProfileName --title "PANE 2" ';' `
    split-pane  -H -p $ProfileName --title "PANE 3" ';' `
    focus-pane  -t 0 ';' `
    split-pane  -H -p $ProfileName --title "PANE 4"
}

function unzip
{
  param (
    [Parameter(Mandatory = $true)]
    [string]$InputZip,

    [Parameter(Mandatory = $true)]
    [string]$OutputDir
  )

  Expand-Archive -Path $InputZip -DestinationPath $OutputDir -Force
}

# function sudo
# {
#   param(
#     [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
#     [string[]]$Command
#   )
#
#   Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"$($Command -join ' ')`"" | Out-Null
# }
$env:DISPLAY="$(hostname).local:0.0"

function source
{
  param (
    [Parameter(Mandatory=$true)]
    [string]$Path
  )

  if (-not (Test-Path $Path))
  {
    Write-Error "File not found: $Path"
    return
  }

  Get-Content $Path | ForEach-Object {
    # Skip empty lines and lines starting with # (comments)
    if (-not ([string]::IsNullOrWhiteSpace($_)) -and -not ($_.StartsWith("#")))
    {
      $parts = $_.Split('=', 2)
      if ($parts.Length -eq 2)
      {
        $name = $parts[0].Trim()
        $value = $parts[1].Trim()
        Set-Item -Path "Env:$name" -Value $value
        Write-Host "Set environment variable: $name = $value"
      }
    }
  }
}

function rmdirf
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-Not (Test-Path $Path))
  {
    Write-Host "❌ Caminho não encontrado: $Path" -ForegroundColor Red
    return
  }

  try
  {
    Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
    Write-Host "✅ Pasta removida: $Path" -ForegroundColor Green
  } catch
  {
    Write-Host "⚠️ Erro ao remover: $_" -ForegroundColor Yellow
  }
}

Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -ViModeIndicator Cursor
Set-PSReadLineKeyHandler -ViMode Insert -Key "Ctrl+n" -Function NextSuggestion
Set-PSReadLineKeyHandler -ViMode Insert -key "CTRL+p" -Function PreviousSuggestion
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function NextSuggestion
Set-PSReadLineKeyHandler -Key "Ctrl+p" -Function PreviousSuggestion

$env:EDITOR = "nvim"

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile))
{
  Import-Module "$ChocolateyProfile"
}

function cdf
{
  [CmdletBinding()]
  param([Parameter(Position=0)][string]$Path)

  if ($PSBoundParameters.ContainsKey('Path') -and $Path -eq '-')
  { Set-Location -Path '-'; return 
  }
  if (-not $PSBoundParameters.ContainsKey('Path') -or [string]::IsNullOrWhiteSpace($Path))
  { Set-Location -Path $HOME; return 
  }

  try
  { $base = (Resolve-Path -LiteralPath $Path).ProviderPath 
  } catch
  { Write-Error "cd: diretório inválido: $Path"; return 
  }

  $env:FZF_BASE = $base

  # Constrói a lista: BASE + subdiretórios do BASE
  $subs  = & fd . $base --type directory --max-depth 4 --hidden --follow --exclude .git --relative-to $base 2>$null
  $items = @($base) + @($subs)

  # Mostra no fzf
  $target = $items | fzf --prompt "Diretórios [$env:FZF_BASE]> " --height 80% --reverse `
    --preview 'tree /A {}'

  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($target))
  { return 
  }
  Set-Location -LiteralPath $target
}

function ndiff
{
  param(
    [Parameter(Mandatory=$true)][string]$PathA,
    [Parameter(Mandatory=$true)][string]$PathB
  )
  git diff --no-index $PathA $PathB | nvim -c "set ft=diff foldmethod=diff foldenable"
}

function nc
{
  Set-Location C:\Users\imale\AppData\Local\nvim
  nvim init.lua
}

function avante
{
  nvim -c "lua vim.defer_fn(function()require('avante.api').zen_mode() end, 100)"
}

Remove-Item Alias:where -Force
Set-Alias where "C:\Windows\System32\where.exe"
Set-Alias lg "lazygit"
Set-Alias vim "nvim"
Set-Alias v "nvim"
$env:PGCLIENTENCODING = "UTF8"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$JAVA_HOME = "D:/tools/java/openjdk-21.0.2_windows-x64_bin"
$env:JAVA_HOME = "D:/tools/java/openjdk-21.0.2_windows-x64_bin"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
# Consoles em UTF-8
[Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
chcp 65001 | Out-Null

# Padrões de encoding ao gravar arquivos
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
