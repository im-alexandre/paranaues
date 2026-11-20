# Perfis do PowerShell

Cada versão usa **um perfil no repo e um carregador pequeno em Documentos**:

| Versão | Perfil no repo | Carregador versionado |
| --- | --- | --- |
| PowerShell 7 | `PowerShell/profile.ps1` | `profile-loaders/PowerShell/profile.ps1` |
| Windows PowerShell 5.1 | `WindowsPowerShell/profile.ps1` | `profile-loaders/WindowsPowerShell/profile.ps1` |

O carregador é instalado em `$PROFILE.CurrentUserAllHosts`, que vale para todos os
hosts da respectiva versão. Não precisamos de outro perfil específico do console
(`Microsoft.PowerShell_profile.ps1`). Os dois perfis usam os mesmos helpers;
as diferenças de encoding e console são tratadas neles.

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

`np` abre o perfil da versão atual **no repo** e restaura o diretório anterior ao
fechar o editor. `.profile.ps1` de diretórios continua sendo executado ao iniciar
e ao usar `cd`; uma guarda impede que um `cd` dentro dele cause recursão.
`cd` aceita `-LiteralPath`, `-PassThru` e `-StackName` e só carrega o perfil local
se a navegação funcionar. `git-cp` só faz push depois de um commit bem-sucedido.

## Instalação e uso

A etapa de perfis de `install_windows.ps1` instala os dois carregadores e
substitui `__PARANAUES_ROOT__` pelo caminho do checkout. Antes de substituir um
perfil diferente, cria uma cópia `.bak.<data-hora>` ao lado dele. A etapa também
arquiva os antigos carregadores `Microsoft.PowerShell_profile.ps1` reconhecidos
como gerados por este repo, preservando perfis de host personalizados.
Repetir a instalação com os mesmos carregadores não reescreve os arquivos.
O instalador completo também executa as demais etapas de configuração do Windows.

Edite os perfis e helpers neste repositório. As alterações valem para novas
sessões sem reinstalar os carregadores. Para recarregar na sessão atual:

```powershell
. $PROFILE.CurrentUserAllHosts
```

O Conda não é executado ao iniciar o shell. Use `conda activate <ambiente>`.
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
