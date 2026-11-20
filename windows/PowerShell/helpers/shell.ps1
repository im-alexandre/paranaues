function prompt {
  $location = Get-Location
  if ($env:WT_SESSION -and $location.Provider.Name -eq 'FileSystem') {
    Write-Host "$([char]27)]9;9;$($location.ProviderPath)$([char]7)" -NoNewline
  }

  $parts = $location.Path.Split([IO.Path]::DirectorySeparatorChar)
  $short = ($parts | Select-Object -Last 2) -join '\'
  $title = if ($short.Length -gt 25) { $parts[-1] } else { $short }
  if ($host.UI.RawUI.WindowTitle -match 'PANE\s+(\d+)') {
    $env:PANE = $Matches[1]
  }

  $branch = ''
  try {
    $name = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $name -and $name -ne 'HEAD') {
      $branch = "[git $name]"
    }
  } catch {
    # Diretorios fora de um repositorio nao exibem branch.
  }

  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
  if ($isAdmin) {
    Write-Host '(ADMIN-MODE)' -NoNewline -ForegroundColor Black -BackgroundColor White
    $title = 'ADMIN-MODE: ' + $title
  }
  if ($host.UI.RawUI.WindowTitle -ne $title) {
    $host.UI.RawUI.WindowTitle = $title
  }

  if ($env:CONDA_DEFAULT_ENV) {
    Write-Host "($(($env:CONDA_DEFAULT_ENV -split '\\')[-1]))" -NoNewline -ForegroundColor Yellow
  }
  $psTag = if ($PSVersionTable.PSVersion.Major -ge 7) { '[PS-7]' } else { '[PS-5]' }
  Write-Host $psTag -NoNewline -ForegroundColor Magenta
  Write-Host "{$env:COMPUTERNAME}" -NoNewline -ForegroundColor DarkGreen
  if ($env:PANE) {
    Write-Host "[$env:PANE]" -NoNewline -ForegroundColor White
  }
  Write-Host $short -NoNewline -ForegroundColor Cyan
  if ($branch) {
    Write-Host $branch -NoNewline -ForegroundColor White
  }
  return "`n$ "
}

# PSReadLine so e configurado quando ha um console interativo.
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) {
  Import-Module PSReadLine -ErrorAction Stop
  Set-PSReadLineOption -EditMode Vi -ViModeIndicator Cursor
  if ((Get-Command Set-PSReadLineOption).Parameters.ContainsKey('PredictionViewStyle')) {
    Set-PSReadLineOption -PredictionViewStyle ListView
  }
  Set-PSReadLineKeyHandler -ViMode Insert -Chord 'Ctrl+n' -Function HistorySearchForward
  Set-PSReadLineKeyHandler -ViMode Insert -Chord 'Ctrl+p' -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -ViMode Command -Chord 'v' -Function ViEditVisually
}
