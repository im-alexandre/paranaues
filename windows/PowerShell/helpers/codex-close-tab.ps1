param(
  [switch]$Resume,
  [string]$SessionId,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$CodexArgs
)

$ErrorActionPreference = "Stop"

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

try {
  if ($Resume -and $SessionId) {
    & codex resume $SessionId
  } else {
    & codex @CodexArgs
  }

  $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
} catch {
  Write-Error $_
  $exitCode = 1
}

exit $exitCode
