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

function openclaw {
  $Port = 18789
  $HostAlias = "jarvis"
  $Url = "http://localhost:$Port"

  $Listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue

  if (-not $Listening) {
    Start-Process ssh -WindowStyle Hidden -ArgumentList @(
      "-N",
      "-o", "ConnectTimeout=10",
      "-o", "ServerAliveInterval=30",
      "-o", "ServerAliveCountMax=3",
      "-o", "ExitOnForwardFailure=yes",
      "-L", "$Port`:127.0.0.1:$Port",
      $HostAlias
    )

    Start-Sleep -Seconds 2
  }

  Start-Process $Url
}

function Retrieval {
  param (
    [Parameter(Mandatory=$true)]
    [array] $queries
  )

  $headers = @{
    Authorization = "Bearer $env:OWNER_API_KEY"
  }

  $body = @{
    collection_slug = "snptee"
    queries = $queries
  } | ConvertTo-Json -Depth 5

  try {
    Invoke-RestMethod `
      -Uri "https://api.baseia.ai/v1/retrieval" `
      -Method Post `
      -Headers $headers `
      -ContentType "application/json; charset=utf-8" `
      -Body $body |
      ConvertTo-Json -Depth 20
  } catch {
    $_.ErrorDetails.Message
  }

}
