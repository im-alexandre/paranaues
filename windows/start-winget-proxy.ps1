$ErrorActionPreference = 'Stop'

$port = 18080
$bridge = Join-Path $PSScriptRoot 'winget-proxy-bridge.js'
$listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
  Where-Object { $_.LocalAddress -eq '127.0.0.1' }

if ($listener) { exit 0 }

$nodePath = (Get-Command node -ErrorAction SilentlyContinue).Source
if (-not $nodePath) {
  $nodePath = Join-Path $env:ProgramFiles 'nodejs\node.exe'
  if (-not (Test-Path -LiteralPath $nodePath -PathType Leaf)) {
    throw 'Node.js is required to start the WinGet proxy bridge.'
  }
}

$env:WINGET_PROXY_PORT = [string]$port
Start-Process -FilePath $nodePath -ArgumentList @('"' + $bridge + '"') -WindowStyle Hidden
