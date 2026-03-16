# bootstrap-wsl

Bootstrap WSL (Ubuntu 24.04+) + LazyVim deps + Miniforge(mamba) + Rust + Node LTS + Go + Neovim.

## Run

```bash
chmod +x ./install_paranaues.sh
./install_paranaues.sh
```

Flags:

```bash
./install_paranaues.sh --no-dotfiles
./install_paranaues.sh --no-lazyvim
```

## Layout

- `dependencies/apt.txt`: pacotes apt
- `scripts/*.sh`: módulos
- `dotfiles/`: `.bashrc`, `.bash_aliases`, `.profile` (symlink no final, por padrão)
