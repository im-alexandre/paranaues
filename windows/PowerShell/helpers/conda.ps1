# O carregamento so prepara a funcao; nenhum processo Conda roda ao abrir o shell.
foreach ($path in @('Alias:\conda', 'Function:\conda')) {
  if (Test-Path $path) { Remove-Item $path -Force }
}
$env:CONDA_EXE = Join-Path $HOME 'miniconda3\Scripts\conda.exe'
$env:CONDA_PYTHON_EXE = Join-Path $HOME 'miniconda3\python.exe'
$env:_CE_M = ''
$env:_CE_CONDA = ''

function conda {
  if ($args.Count -gt 0 -and $args[0] -in @('activate', 'deactivate')) {
    $command = & $env:CONDA_EXE 'shell.powershell' @args
    if ($LASTEXITCODE -eq 0 -and $command) {
      Invoke-Expression ($command -join "`n")
    }
  } else {
    & $env:CONDA_EXE @args
  }
}
