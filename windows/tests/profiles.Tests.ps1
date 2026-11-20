$script:ProfileRoot = Split-Path -Parent $PSScriptRoot
$script:CommandsHelper = Join-Path $script:ProfileRoot 'PowerShell/helpers/commands.ps1'
$script:EnvironmentHelper = Join-Path $script:ProfileRoot 'PowerShell/helpers/environment.ps1'

function Assert-Equal {
  param($Actual, $Expected, [string]$Message = 'Valores diferentes')
  if ($Actual -cne $Expected) {
    throw "$Message (esperado: '$Expected'; recebido: '$Actual')"
  }
}

function New-TestDirectory {
  $path = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $path -Force | Out-Null
  return $path
}

function Protect-ApiKeysDirectory {
  Mock Test-Path { return $false } -ParameterFilter {
    $LiteralPath -and $LiteralPath -eq (Join-Path $HOME '.api_keys')
  }
  Mock Get-ChildItem { throw 'Import-ApiKeys tentou enumerar chaves reais' } -ParameterFilter {
    $LiteralPath -and $LiteralPath.StartsWith((Join-Path $HOME '.api_keys'), [StringComparison]::OrdinalIgnoreCase)
  }
  Mock Get-Content { throw 'Import-ApiKeys tentou ler chaves reais' } -ParameterFilter {
    $LiteralPath -and $LiteralPath.StartsWith((Join-Path $HOME '.api_keys'), [StringComparison]::OrdinalIgnoreCase)
  }
}

function Assert-NoApiKeyReads {
  Assert-MockCalled Get-ChildItem -Times 0 -ParameterFilter {
    $LiteralPath -and $LiteralPath.StartsWith((Join-Path $HOME '.api_keys'), [StringComparison]::OrdinalIgnoreCase)
  }
  Assert-MockCalled Get-Content -Times 0 -ParameterFilter {
    $LiteralPath -and $LiteralPath.StartsWith((Join-Path $HOME '.api_keys'), [StringComparison]::OrdinalIgnoreCase)
  }
}

function Get-InstallerProfileFunctions {
  $installerPath = Join-Path $script:ProfileRoot '..\install_windows.ps1'
  $tokens = $null
  $parseErrors = $null
  $ast = [Management.Automation.Language.Parser]::ParseFile($installerPath, [ref]$tokens, [ref]$parseErrors)
  if ($parseErrors.Count) { throw "Erro ao analisar installer: $($parseErrors[0].Message)" }
  $definitions = @{}
  foreach ($functionName in @('Get-BackupPath', 'Install-PowerShellRepoProfile')) {
    $definition = $ast.Find({
      param($node)
      $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName
    }, $true)
    if (-not $definition) { throw "Funcao ausente no installer: $functionName" }
    $definitions[$functionName] = [ScriptBlock]::Create($definition.Extent.Text)
  }
  return $definitions
}

Describe 'Perfis PowerShell' {
  It 'descobre helpers .ps1 uma vez e em ordem alfabetica e invoca o perfil local' {
    $root = New-TestDirectory
    $helpers = Join-Path $root 'helpers'
    New-Item -ItemType Directory -Path $helpers | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:ProfileRoot 'PowerShell/profile.ps1') -Destination (Join-Path $root 'profile.ps1')
    try {
      ' $global:ProfileHelperOrder += ''z'' ' | Set-Content -LiteralPath (Join-Path $helpers 'z-last.ps1')
      ' $global:ProfileHelperOrder += ''a'' ' | Set-Content -LiteralPath (Join-Path $helpers 'a-first.ps1')
      ' $global:ProfileHelperOrder += ''a'' ' | Set-Content -LiteralPath (Join-Path $helpers 'a-second.ps1')
      '.txt' | Set-Content -LiteralPath (Join-Path $helpers 'ignored.txt')
      $global:ProfileHelperOrder = @()
      $global:ProfileInvocationCount = 0
      $oldInvokeProfile = Get-Item Function:\Invoke-LocalProfile -ErrorAction SilentlyContinue
      function global:Invoke-LocalProfile { $global:ProfileInvocationCount++ }
      . (Join-Path $root 'profile.ps1')
      Assert-Equal ($global:ProfileHelperOrder -join ',') 'a,a,z' 'Ordem/quantidade de helpers'
      Assert-Equal $global:ProfileInvocationCount 1 'Invocacao local'
    } finally {
      Remove-Item Function:\Invoke-LocalProfile -ErrorAction SilentlyContinue
      if ($oldInvokeProfile) { Set-Item Function:\Invoke-LocalProfile $oldInvokeProfile.ScriptBlock }
      Remove-Variable ProfileHelperOrder, ProfileInvocationCount -Scope Global -ErrorAction SilentlyContinue
    }
  }

  It 'cd -LiteralPath aceita colchetes e impede recursao do .profile.ps1' {
    $root = New-TestDirectory
    $target = Join-Path $root 'pasta[1]'
    New-Item -ItemType Directory -Path $target | Out-Null
    $oldLocation = Get-Location
    $commandsModule = New-Module -ArgumentList $script:CommandsHelper -ScriptBlock {
      param($helperPath)
      . $helperPath
    }
    try {
      @'
$global:LocalProfileRuns++
cd -LiteralPath (Get-Location).Path
'@ | Set-Content -LiteralPath (Join-Path $target '.profile.ps1')
      $global:LocalProfileRuns = 0
      if (-not (Test-Path -LiteralPath (Join-Path $target '.profile.ps1') -PathType Leaf)) { throw 'O perfil local de teste nao foi criado' }
      $cdFunction = & $commandsModule { Get-Item Function:\cd }
      & $cdFunction -LiteralPath $target
      Assert-Equal (Get-Location).Path $target 'Diretorio literal'
      Assert-Equal $global:LocalProfileRuns 1 'O perfil local deve executar uma vez'
    } finally {
      Set-Location -LiteralPath $oldLocation.Path
      Remove-Module $commandsModule.Name -ErrorAction SilentlyContinue
      Remove-Variable LocalProfileRuns -Scope Global -ErrorAction SilentlyContinue
    }
  }

  It 'nao executa o perfil local quando cd falha' {
    $root = New-TestDirectory
    $oldLocation = Get-Location
    $commandsModule = New-Module -ArgumentList $script:CommandsHelper -ScriptBlock {
      param($helperPath)
      . $helperPath
    }
    try {
      $global:LocalProfileRuns = 0
      $failed = $false
      $cdFunction = & $commandsModule { Get-Item Function:\cd }
      try { & $cdFunction -LiteralPath (Join-Path $root 'nao-existe') } catch { $failed = $true }
      if (-not $failed) { throw 'cd deveria falhar para caminho inexistente' }
      Assert-Equal $global:LocalProfileRuns 0 'Perfil local executado apos cd falho'
    } finally {
      Set-Location -LiteralPath $oldLocation.Path
      Remove-Module $commandsModule.Name -ErrorAction SilentlyContinue
      Remove-Variable LocalProfileRuns -Scope Global -ErrorAction SilentlyContinue
    }
  }

  It 'np restaura o diretorio atual quando o editor falha' {
    $oldLocation = (Get-Location).Path
    # O comando local garante que o editor real nunca seja resolvido.
    function nvim { throw 'chamada nao interceptada do editor' }
    . $script:CommandsHelper
    Mock nvim { throw 'falha simulada do editor' }
    $failed = $false
    try { np } catch { $failed = $true }
    if (-not $failed) { throw 'A falha simulada do editor nao foi propagada' }
    Assert-Equal (Get-Location).Path $oldLocation 'np nao restaurou o diretorio'
    Assert-MockCalled nvim -Times 1
  }

  It 'git-cp nao chama push se commit falha' {
    . $script:CommandsHelper
    $global:GitCalls = @()
    function git { throw 'chamada nao interceptada de git' }
    Mock git {
      $global:GitCalls += ,@($args)
      if ($args[0] -eq 'commit') { $global:LASTEXITCODE = 1 }
    }
    try {
      git-cp 'mensagem de teste'
      Assert-MockCalled git -Times 1 -ParameterFilter { $args[0] -eq 'commit' }
      Assert-MockCalled git -Times 0 -ParameterFilter { $args[0] -eq 'push' }
    } finally {
      Remove-Variable GitCalls -Scope Global -ErrorAction SilentlyContinue
    }
  }

  It 'source importa valores com sinal de igual sem exibi-los' {
    $root = New-TestDirectory
    $name = 'PROFILE_SOURCE_TEST_' + [Guid]::NewGuid().ToString('N')
    $helperEnvironmentNames = @('EDITOR','VISUAL','PYTHONUTF8','PYTHONIOENCODING','PYTHONDONTWRITEBYTECODE','LESSCHARSET','OPENCODE_DISABLE_CLAUDE_CODE_PROMPT','OPENCODE_DISABLE_CLAUDE_CODE_SKILLS','COOLIFY_BASE_URL')
    $oldHelperEnvironment = @{}
    foreach ($environmentName in $helperEnvironmentNames) { $oldHelperEnvironment[$environmentName] = [Environment]::GetEnvironmentVariable($environmentName, 'Process') }
    $oldValue = [Environment]::GetEnvironmentVariable($name, 'Process')
    $value = 'parte=ação=valor-nao-exibir'
    try {
      [IO.File]::WriteAllText((Join-Path $root 'values.env'), "${name}=$value`n", [Text.UTF8Encoding]::new($false))
      Protect-ApiKeysDirectory
      . $script:EnvironmentHelper
      Assert-NoApiKeyReads
      $captured = @(source -Path (Join-Path $root 'values.env') 6>&1 | Out-String)
      Assert-Equal ([Environment]::GetEnvironmentVariable($name, 'Process')) $value 'Valor de ambiente'
      if (($captured -join "`n").Contains($value)) { throw 'source exibiu o valor importado' }
    } finally {
      if ($null -eq $oldValue) { Remove-Item "Env:$name" -ErrorAction SilentlyContinue }
      else { Set-Item "Env:$name" $oldValue }
      foreach ($environmentName in $helperEnvironmentNames) {
        [Environment]::SetEnvironmentVariable($environmentName, $oldHelperEnvironment[$environmentName], 'Process')
      }
    }
  }

  It 'configura encoding UTF-8 e faz roundtrip com defaults da versao atual' {
    $root = New-TestDirectory
    $helperEnvironmentNames = @('EDITOR','VISUAL','PYTHONUTF8','PYTHONIOENCODING','PYTHONDONTWRITEBYTECODE','LESSCHARSET','OPENCODE_DISABLE_CLAUDE_CODE_PROMPT','OPENCODE_DISABLE_CLAUDE_CODE_SKILLS','COOLIFY_BASE_URL')
    $oldHelperEnvironment = @{}
    foreach ($environmentName in $helperEnvironmentNames) { $oldHelperEnvironment[$environmentName] = [Environment]::GetEnvironmentVariable($environmentName, 'Process') }
    $oldDefaults = @{}
    foreach ($key in @('Out-File:Encoding','Set-Content:Encoding','Add-Content:Encoding','Export-Csv:Encoding','Tee-Object:Encoding')) {
      $oldDefaults[$key] = $PSDefaultParameterValues[$key]
    }
    $oldOutputEncoding = $OutputEncoding
    $oldConsoleInput = [Console]::InputEncoding
    $oldConsoleOutput = [Console]::OutputEncoding
    try {
      Protect-ApiKeysDirectory
      . $script:EnvironmentHelper
      Assert-NoApiKeyReads
      $text = 'ação; café; 漢字'
      $file = Join-Path $root 'roundtrip.txt'
      $text | Out-File -LiteralPath $file
      Assert-Equal (Get-Content -LiteralPath $file -Raw).TrimEnd("`r", "`n") $text 'Roundtrip UTF-8'
      $expectedEncoding = if ($PSVersionTable.PSVersion.Major -ge 7) { 'utf8NoBOM' } else { 'utf8' }
      Assert-Equal $PSDefaultParameterValues['Out-File:Encoding'] $expectedEncoding 'Default Out-File encoding'
      if ($PSVersionTable.PSVersion.Major -ge 7) {
        Assert-Equal $PSDefaultParameterValues['Tee-Object:Encoding'] 'utf8NoBOM' 'Default Tee-Object encoding'
      }
    } finally {
      foreach ($environmentName in $helperEnvironmentNames) {
        [Environment]::SetEnvironmentVariable($environmentName, $oldHelperEnvironment[$environmentName], 'Process')
      }
      foreach ($key in $oldDefaults.Keys) {
        if ($null -eq $oldDefaults[$key]) { $PSDefaultParameterValues.Remove($key) }
        else { $PSDefaultParameterValues[$key] = $oldDefaults[$key] }
      }
      $OutputEncoding = $oldOutputEncoding
      [Console]::InputEncoding = $oldConsoleInput
      [Console]::OutputEncoding = $oldConsoleOutput
    }
  }

  It 'instala os dois loaders e uma segunda execucao nao altera arquivos nem cria backups' {
    $definitions = Get-InstallerProfileFunctions
    . $definitions['Get-BackupPath']
    . $definitions['Install-PowerShellRepoProfile']
    $oldRoot = Get-Variable ROOT -Scope Global -ErrorAction SilentlyContinue
    $oldHelpers = Get-Variable POWERSHELL_HELPERS_REPO -Scope Global -ErrorAction SilentlyContinue
    $oldLoaders = Get-Variable POWERSHELL_LOADERS_REPO -Scope Global -ErrorAction SilentlyContinue
    $documents = Join-Path $TestDrive 'InstallDocuments'
    $global:ROOT = Split-Path -Parent $script:ProfileRoot
    $global:POWERSHELL_HELPERS_REPO = Join-Path $global:ROOT 'windows/PowerShell/helpers'
    $global:POWERSHELL_LOADERS_REPO = Join-Path $global:ROOT 'windows/profile-loaders'
    try {
      Install-PowerShellRepoProfile -DocumentsDirectory $documents
      $profiles = @(
        (Join-Path $documents 'PowerShell/profile.ps1'),
        (Join-Path $documents 'WindowsPowerShell/profile.ps1')
      )
      foreach ($profile in $profiles) {
        if (-not (Test-Path -LiteralPath $profile -PathType Leaf)) { throw "Loader ausente: $profile" }
      }
      $beforeTimes = @{}
      foreach ($profile in $profiles) { $beforeTimes[$profile] = (Get-Item -LiteralPath $profile).LastWriteTimeUtc.Ticks }
      $backupCount = @(Get-ChildItem -LiteralPath $documents -Recurse -File -Filter '*.bak.*').Count
      Install-PowerShellRepoProfile -DocumentsDirectory $documents
      foreach ($profile in $profiles) {
        Assert-Equal (Get-Item -LiteralPath $profile).LastWriteTimeUtc.Ticks $beforeTimes[$profile] "Loader regravado: $profile"
      }
      Assert-Equal @(Get-ChildItem -LiteralPath $documents -Recurse -File -Filter '*.bak.*').Count $backupCount 'Backups criados na segunda execucao'
    } finally {
      foreach ($entry in @(@('ROOT', $oldRoot), @('POWERSHELL_HELPERS_REPO', $oldHelpers), @('POWERSHELL_LOADERS_REPO', $oldLoaders))) {
        if ($entry[1]) { Set-Variable -Name $entry[0] -Scope Global -Value $entry[1].Value }
        else { Remove-Variable -Name $entry[0] -Scope Global -ErrorAction SilentlyContinue }
      }
    }
  }

  It 'arquiva apenas o legacy loader literal e preserva o perfil customizado' {
    $definitions = Get-InstallerProfileFunctions
    . $definitions['Get-BackupPath']
    . $definitions['Install-PowerShellRepoProfile']
    $oldRoot = Get-Variable ROOT -Scope Global -ErrorAction SilentlyContinue
    $oldHelpers = Get-Variable POWERSHELL_HELPERS_REPO -Scope Global -ErrorAction SilentlyContinue
    $oldLoaders = Get-Variable POWERSHELL_LOADERS_REPO -Scope Global -ErrorAction SilentlyContinue
    $documents = Join-Path $TestDrive 'LegacyDocuments'
    $global:ROOT = Split-Path -Parent $script:ProfileRoot
    $global:POWERSHELL_HELPERS_REPO = Join-Path $global:ROOT 'windows/PowerShell/helpers'
    $global:POWERSHELL_LOADERS_REPO = Join-Path $global:ROOT 'windows/profile-loaders'
    $legacyDirectory = Join-Path $documents 'WindowsPowerShell'
    $customDirectory = Join-Path $documents 'PowerShell'
    New-Item -ItemType Directory -Path $legacyDirectory,$customDirectory -Force | Out-Null
    $legacyPath = Join-Path $legacyDirectory 'Microsoft.PowerShell_profile.ps1'
    $customPath = Join-Path $customDirectory 'Microsoft.PowerShell_profile.ps1'
    $legacySource = Join-Path $global:ROOT 'windows/WindowsPowerShell/Microsoft.PowerShell_profile.ps1'
    $legacyContents = ". '$legacySource'"
    $customContents = '# user custom profile sentinel'
    [IO.File]::WriteAllText($legacyPath, $legacyContents)
    [IO.File]::WriteAllText($customPath, $customContents)
    try {
      Install-PowerShellRepoProfile -DocumentsDirectory $documents
      if (Test-Path -LiteralPath $legacyPath) { throw 'O carregador legado literal nao foi removido' }
      if (-not (Test-Path -LiteralPath $customPath -PathType Leaf)) { throw 'O perfil customizado foi removido' }
      Assert-Equal ([IO.File]::ReadAllText($customPath)) $customContents 'Conteudo customizado alterado'
      $backups = @(Get-ChildItem -LiteralPath $legacyDirectory -File -Filter 'Microsoft.PowerShell_profile.ps1.bak.*')
      Assert-Equal $backups.Count 1 'Quantidade de backups do carregador legado'
      Assert-Equal ([IO.File]::ReadAllText($backups[0].FullName)) $legacyContents 'Backup do legacy loader alterado'
    } finally {
      foreach ($entry in @(@('ROOT', $oldRoot), @('POWERSHELL_HELPERS_REPO', $oldHelpers), @('POWERSHELL_LOADERS_REPO', $oldLoaders))) {
        if ($entry[1]) { Set-Variable -Name $entry[0] -Scope Global -Value $entry[1].Value }
        else { Remove-Variable -Name $entry[0] -Scope Global -ErrorAction SilentlyContinue }
      }
    }
  }
}
