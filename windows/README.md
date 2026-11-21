# Perfis do PowerShell

O PowerShell 7 e o 5.1 usam um único perfil compartilhado, `PowerShell/profile.ps1`.
O instalador copia o perfil e os helpers para `%LOCALAPPDATA%\Paranaues`.
Cada versão do PowerShell procura o seu `$PROFILE.CurrentUserAllHosts` em
uma pasta diferente. O instalador coloca o mesmo [carregador](profile-loader.ps1)
nas duas pastas. Ambos apontam para a cópia local do perfil, que continua
disponível quando o checkout é movido ou o disco é desconectado.

## Helpers

`PowerShell/profile.ps1` encontra todos os arquivos `*.ps1` diretamente em
`PowerShell/helpers/`, ordena pelo nome e carrega cada um uma vez. Para adicionar
um helper, basta criar o arquivo nessa pasta. Os helpers devem ser independentes;
scripts auxiliares que não devem iniciar com o shell ficam fora dela.

- `commands.ps1`: navegação, editor, arquivos e atalhos de npm/Git.
- `conda.ps1`: wrapper do Conda, ativado somente quando chamado.
- `environment.ps1`: UTF-8, variáveis, `source` e importação de credenciais.
- `proxy.ps1`: comandos de proxy, sem alterar conexões durante o carregamento.
- `services.ps1`: atalhos de Ollama, AgentHub, OpenClaw e retrieval.
- `shell.ps1`: prompt e atalhos do PSReadLine no console interativo.

`np` abre o perfil compartilhado **no repo**, atualiza a cópia local ao
fechar o Neovim com sucesso e volta ao diretório anterior. `.profile.ps1` de
diretórios continua sendo executado ao iniciar
e ao usar `cd`; uma guarda impede que um `cd` dentro dele cause recursão.
`cd` aceita `-LiteralPath`, `-PassThru` e `-StackName` e só carrega o perfil local
se a navegação funcionar. `git-cp` só faz push depois de um commit bem-sucedido.

## Instalação e uso

Execute no PowerShell 7. Os modos de reparo funcionam sem elevação e podem ser
combinados.

```powershell
pwsh -NoProfile -File .\install_windows.ps1 -ProfileOnly -TerminalOnly
```

`-ProfileOnly` instala os perfis locais, registra o checkout para o comando
`np` e configura os módulos. A instalação mantém o código personalizado já
presente nos perfis e remove carregadores e links legados deste repositório.

`-TerminalOnly` preserva um arquivo local válido e converte links válidos
em arquivos com o mesmo conteúdo. Se o arquivo estiver ausente ou inválido,
usa `windows/terminal_settings.json`. O Terminal detecta as distribuições WSL
disponíveis na máquina.

Para preparar outro Windows, execute `pwsh -NoProfile -File .\install_windows.ps1`.
O instalador provisiona pacotes e clona o LazyVim se necessário. Use
`-SkipPackages` para refazer só a configuração e `-UpgradeAll` quando quiser
atualizar os pacotes existentes. As exclusões do Defender são opcionais e
exigem elevação.

Repetir a instalação com o mesmo conteúdo preserva os arquivos já configurados.

## Módulos locais

As duas versões buscam módulos em `%LOCALAPPDATA%\PowerShell\Modules` e nos
diretórios do sistema. Os carregadores continuam no caminho de Documentos que o
Windows informa. Quando ele está redirecionado para o OneDrive, os dois
carregadores são os únicos scripts que a instalação cria ali. O instalador também
configura o `powershell.config.json` do PowerShell 7.

Para instalar um módulo da galeria na pasta local, indique o destino
explicitamente. Os comandos tradicionais com `-Scope CurrentUser` ainda podem
usar Documentos.

```powershell
# PowerShell 7
Save-PSResource -Name NomeDoModulo -Path "$env:LOCALAPPDATA\PowerShell\Modules"

# Windows PowerShell 5.1
Save-Module -Name NomeDoModulo -Path "$env:LOCALAPPDATA\PowerShell\Modules"
```

Ao editar pelo `np`, a cópia local é atualizada automaticamente. Execute
`-ProfileOnly` depois de editar por outro meio ou de mover o checkout para
registrar o novo caminho. Para recarregar na sessão atual:

```powershell
. $PROFILE.CurrentUserAllHosts
```

`$PROFILE` sozinho aponta para `Microsoft.PowerShell_profile.ps1`, o perfil
específico do console. O instalador remove o antigo atalho gerado pelo projeto e
preserva perfis de console personalizados.

O Conda é localizado quando você chama `conda activate <ambiente>`, pelo
`CONDA_EXE`, pelo `PATH` ou pelas instalações usuais de Miniconda, Miniforge e
Anaconda.
Os scripts com texto não ASCII usam UTF-8 com BOM para leitura correta no 5.1.

Credenciais são carregadas de `$HOME/.api_keys/` por `environment.ps1`.
Variáveis adicionais usam arquivos em `$HOME/.api_keys/environment/`, com uma
linha `NOME=valor` por variável. `source` não imprime os valores importados.
Mantenha os valores fora dos arquivos versionados; `windows/.api_keys/` já é
ignorado pelo Git.

## Testes

Os testes usam Pester (validado com a versão 3.4.0 disponível nesta máquina) e
pastas temporárias, sem abrir editores nem executar Git ou comandos de rede reais.
Execute em processos sem profile para isolar a sessão:

```powershell
pwsh -NoProfile -Command "Invoke-Pester .\windows\tests\profiles.Tests.ps1 -EnableExit"
powershell -NoProfile -Command "Invoke-Pester .\windows\tests\profiles.Tests.ps1 -EnableExit"
```
