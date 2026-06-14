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
