# O carregamento so prepara a funcao; nenhum processo Conda roda ao abrir o shell.
foreach ($path in @('Alias:\conda', 'Function:\conda')) {
  if (Test-Path $path) { Remove-Item $path -Force }
}
function conda {
  if (-not [IO.File]::Exists($env:CONDA_EXE)) {
    $command = Get-Command conda.exe -CommandType Application -ErrorAction SilentlyContinue
    $executable = if ($command) { $command.Source }
    if (-not $executable) {
      $executable = foreach ($root in @($HOME, $env:LOCALAPPDATA, $env:ProgramData)) {
        foreach ($distribution in 'miniconda3', 'miniforge3', 'anaconda3') {
          $candidate = Join-Path $root "$distribution\Scripts\conda.exe"
          if ([IO.File]::Exists($candidate)) { $candidate; break }
        }
      }
      $executable = $executable | Select-Object -First 1
    }
    if (-not $executable) { throw 'Conda nao encontrado. Configure CONDA_EXE ou disponibilize conda.exe no PATH.' }
    $env:CONDA_EXE = $executable
  }
  if ($args.Count -gt 0 -and $args[0] -in @('activate', 'deactivate')) {
    $activation = & $env:CONDA_EXE 'shell.powershell' @args
    if ($LASTEXITCODE -eq 0 -and $activation) {
      Invoke-Expression ($activation -join "`n")
    }
  } else {
    & $env:CONDA_EXE @args
  }
}
