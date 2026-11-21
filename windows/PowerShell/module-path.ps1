function Get-ParanauesModulePath {
  param(
    [string]$Value,
    [string]$ModulesDirectory = (Join-Path $env:LOCALAPPDATA 'PowerShell\Modules')
  )
  $localPath = [Environment]::ExpandEnvironmentVariables($ModulesDirectory)
  $oldRepoPath = Join-Path $PSScriptRoot 'Modules'
  $oneDriveRoots = @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial) |
    Where-Object { $_ } | ForEach-Object { $_.Replace('/', '\').TrimEnd('\') + '\' }
  $paths = foreach ($entry in ($Value -split ';')) {
    if (-not $entry.Trim()) { continue }
    $resolved = [Environment]::ExpandEnvironmentVariables($entry.Trim()).Replace('/', '\').TrimEnd('\')
    if ($resolved -in @($localPath, $oldRepoPath) -or $resolved -like '*\paranaues\windows\PowerShell\Modules') { continue }
    if ($oneDriveRoots | Where-Object { $resolved.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }) { continue }
    $entry
  }
  (@($ModulesDirectory) + $paths | Select-Object -Unique) -join ';'
}
