# >>> Paranaues >>>
$paranauesProfile = Join-Path $env:LOCALAPPDATA 'Paranaues\PowerShell\profile.ps1'
if (Test-Path -LiteralPath $paranauesProfile -PathType Leaf) { . $paranauesProfile }
# <<< Paranaues <<<
