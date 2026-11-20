function Proxy-VpsOn {
    $proxy = "http://127.0.0.1:8888"
    $pidFile = "$env:LOCALAPPDATA\vps-proxy-ssh.pid"
    $internetSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    tailscale set --exit-node= | Out-Null

    $process = $null

    if (Test-Path $pidFile) {
        $process = Get-Process `
            -Id ([int](Get-Content $pidFile)) `
            -ErrorAction SilentlyContinue
    }

    if (-not $process) {
        if (
            Get-NetTCPConnection `
                -LocalAddress "127.0.0.1" `
                -LocalPort 8888 `
                -State Listen `
                -ErrorAction SilentlyContinue
        ) {
            throw "A porta 127.0.0.1:8888 já está em uso."
        }

        $process = Start-Process `
            -FilePath "ssh.exe" `
            -WindowStyle Hidden `
            -PassThru `
            -ArgumentList @(
                "-NT",
                "-o", "ExitOnForwardFailure=yes",
                "-o", "ServerAliveInterval=30",
                "-o", "ServerAliveCountMax=3",
                "-L", "127.0.0.1:8888:127.0.0.1:8888",
                "hostgator"
            )

        $process.Id | Set-Content $pidFile
    }

    for ($i = 0; $i -lt 30; $i++) {
        $listener = Get-NetTCPConnection `
            -LocalAddress "127.0.0.1" `
            -LocalPort 8888 `
            -State Listen `
            -ErrorAction SilentlyContinue

        if ($listener) {
            break
        }

        Start-Sleep -Milliseconds 200
    }

    if (-not $listener) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        throw "O túnel SSH não abriu a porta 8888."
    }

    $env:HTTP_PROXY = $proxy
    $env:HTTPS_PROXY = $proxy
    $env:NO_PROXY = "localhost,127.0.0.1,::1,100.64.0.0/10"
    Remove-Item Env:ALL_PROXY -ErrorAction SilentlyContinue

    [Environment]::SetEnvironmentVariable("HTTP_PROXY", $proxy, "User")
    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", $proxy, "User")
    [Environment]::SetEnvironmentVariable(
        "NO_PROXY",
        "localhost,127.0.0.1,::1,100.64.0.0/10",
        "User"
    )
    [Environment]::SetEnvironmentVariable("ALL_PROXY", $null, "User")

    Set-ItemProperty `
        -Path $internetSettings `
        -Name ProxyEnable `
        -Value 1

    Set-ItemProperty `
        -Path $internetSettings `
        -Name ProxyServer `
        -Value "127.0.0.1:8888"

    Set-ItemProperty `
        -Path $internetSettings `
        -Name ProxyOverride `
        -Value "<local>;localhost;127.*;100.*"

    Write-Host "Proxy VPS ligado: $proxy"
}


function Proxy-VpsOff {
    $pidFile = "$env:LOCALAPPDATA\vps-proxy-ssh.pid"
    $internetSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    if (Test-Path $pidFile) {
        Stop-Process `
            -Id ([int](Get-Content $pidFile)) `
            -Force `
            -ErrorAction SilentlyContinue

        Remove-Item $pidFile -Force
    }

    Set-ItemProperty `
        -Path $internetSettings `
        -Name ProxyEnable `
        -Value 0

    Set-ItemProperty `
        -Path $internetSettings `
        -Name ProxyServer `
        -Value ""

    foreach ($name in @("HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY", "ALL_PROXY")) {
        [Environment]::SetEnvironmentVariable($name, $null, "User")
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }

    Write-Host "Proxy VPS desligado."
}

function setProxy {
  $env:HTTPS_PROXY="http://192.168.137.1:18080"
  $env:HTTP_PROXY=$env:HTTPS_PROXY
}
