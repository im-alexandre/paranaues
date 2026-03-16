# Adicionar-Neovim-MenuCompleto.ps1
# Adiciona "Abrir com Neovim" (arquivos) e "Abrir pasta no Neovim" (diretórios)
# 100% seguro, reversível e sem alterar associações de sistema

$ErrorActionPreference = 'Stop'

# 🧭 Caminho do Neovim
$nvimPath = "C:\tools\neovim\nvim-win64\bin\nvim.exe"
if (-not (Test-Path $nvimPath)) {
    Write-Error "Neovim não encontrado em '$nvimPath'. Ajuste o caminho e tente novamente."
    exit 1
}

# 🪄 Comandos de execução
$cmdFile = "pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command `"Start-Process -FilePath '$nvimPath' -ArgumentList '--', '%1' -WorkingDirectory (Split-Path '%1')`""
$cmdDir  = "pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command `"Start-Process -FilePath '$nvimPath' -ArgumentList '--', '%V' -WorkingDirectory '%V'`""

# 📂 Caminhos do registro
$baseHKCU = "HKCU:\Software\Classes"
$fileMenuKey = "$baseHKCU\*\shell\Abrir_com_Neovim"
$fileCmdKey  = "$fileMenuKey\command"
$dirMenuKey  = "$baseHKCU\Directory\shell\Abrir_pasta_no_Neovim"
$dirCmdKey   = "$dirMenuKey\command"

Write-Host 🧩 Adiciona para arquivos 
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$cu = [Microsoft.Win32.Registry]::CurrentUser
$keyPath = 'Software\Classes\*\shell\Abrir_com_Neovim'
$cmdSub  = 'command'
$k = $cu.CreateSubKey($keyPath)  # cria/abre sem múltiplas chamadas
$k.SetValue('MUIVerb', 'Abrir com Neovim', [Microsoft.Win32.RegistryValueKind]::String)
$k.SetValue('Icon', $nvimPath, [Microsoft.Win32.RegistryValueKind]::String)
$kc = $k.CreateSubKey($cmdSub)
# Valor padrão (Default) deve ser string vazia como nome -> mais rápido que New-ItemProperty
$kc.SetValue('', $cmdFile, [Microsoft.Win32.RegistryValueKind]::String)
$kc.Close(); $k.Close()
$sw.Stop()
Write-Host ("⏱️  Arquivos prontos em {0:N0} ms" -f $sw.ElapsedMilliseconds)

# ⛽️ Adiciona para diretórios (versão rápida via .NET)
Write-Host "🧱 Adiciona para diretórios e background de diretórios"
$sw2 = [System.Diagnostics.Stopwatch]::StartNew()
$cu = [Microsoft.Win32.Registry]::CurrentUser

# Para quando clica no ícone da pasta
$keyPathDir = 'Software\Classes\Directory\shell\Abrir_pasta_no_Neovim'
$k  = $cu.CreateSubKey($keyPathDir)          
$k.SetValue('Icon',  $nvimPath, [Microsoft.Win32.RegistryValueKind]::String)
$k.SetValue('MUIVerb','Abrir com Neovim', [Microsoft.Win32.RegistryValueKind]::String)
$kc = $k.CreateSubKey('command')              
$kc.SetValue('', $cmdDir, [Microsoft.Win32.RegistryValueKind]::String)  
$kc.Close(); $k.Close()

# Para quando clica no fundo (background) da pasta aberta
$keyPathDirBg = 'Software\Classes\Directory\Background\shell\Abrir_pasta_no_Neovim'
$kBg  = $cu.CreateSubKey($keyPathDirBg)          
$kBg.SetValue('Icon',  $nvimPath, [Microsoft.Win32.RegistryValueKind]::String)
$kBg.SetValue('MUIVerb','Abrir com Neovim', [Microsoft.Win32.RegistryValueKind]::String)
$kcBg = $kBg.CreateSubKey('command')              
$kcBg.SetValue('', $cmdDir, [Microsoft.Win32.RegistryValueKind]::String)  
$kcBg.Close(); $kBg.Close()

$sw2.Stop()
Write-Host ("⏱️  Diretórios e Background prontos em {0:N0} ms" -f $sw2.ElapsedMilliseconds)

Write-Host "✅ Menu de contexto atualizado com sucesso!"
Write-Host "   • 'Abrir com Neovim' → arquivos"
Write-Host "   • 'Abrir pasta no Neovim' → diretórios"
Write-Host "   Caminho usado: $nvimPath"


Write-Host "Adicionar no menu reduzido dos arquivos (abrir com)"
$exts = @(".txt",".md",".ps1",".lua",".json",
    ".toml",".yaml",".yml",".vim",".vimrc",
    ".cfg",".ini",".log",".java", ".py",
    ".ini", ".xml")
$cu = [Microsoft.Win32.Registry]::CurrentUser
# 1) Deixa o Applications\nvim.exe como acima (mantém)
# 2) Em SupportedTypes, coloque apenas as extensões (sem o '*'):
$appK = $cu.CreateSubKey("Software\Classes\Applications\nvim.exe\SupportedTypes")
foreach ($e in $exts) { $appK.SetValue($e, "", [Microsoft.Win32.RegistryValueKind]::String) }
$appK.Close()
# 3) Coloca nvim.exe no OpenWithList de cada extensão
foreach ($e in $exts) {
  $k = $cu.CreateSubKey("Software\Classes\$e\OpenWithList")
  $null = $k.CreateSubKey("nvim.exe")
  $k.Close()
}
Start-Process "cmd.exe" "/c ie4uinit.exe -show" -WindowStyle Hidden
Write-Host "✅ Neovim adicionado ao 'Abrir com' para as extensões selecionadas."


# Write-Host 🔄 Reinicia Explorer para aplicar
# taskkill /f /im explorer.exe
# start explorer.exe
