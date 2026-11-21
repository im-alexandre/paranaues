# bootstrap-wsl

Bootstrap WSL (Ubuntu 24.04+) + LazyVim deps + Miniforge(mamba) + Rust + Node LTS + Go + Neovim.

## Run

```bash
bash ./install_ubuntu.sh
```

Flags:

```bash
bash ./install_ubuntu.sh --no-dotfiles
bash ./install_ubuntu.sh --no-lazyvim
```

## Layout

- `dependencies/apt.txt`: pacotes apt
- `scripts/*.sh`: módulos
- `dotfiles/`: trechos copiados para `~/.paranaues.*` e carregados pelos perfis locais

Você pode executar o instalador novamente para aplicar mudanças nos dotfiles.
Ele mantém o conteúdo personalizado nos perfis do usuário e substitui os
links do próprio projeto por arquivos locais.
