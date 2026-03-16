# --- PARANAUES EXTRAS (append-only) ---

# local bin primeiro
export PATH="$HOME/.local/bin:$PATH"

# Windows user profile path (pra scripts/interop)
export USERPROFILE="/mnt/c/Users/imale"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Miniforge/Conda (sem auto-activate base)
if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
  . "$HOME/miniforge3/etc/profile.d/conda.sh"
  conda config --set auto_activate_base false >/dev/null 2>&1 || true
fi

# Clipboard WSL <-> Windows (win32yank)
if grep -qi microsoft /proc/version 2>/dev/null; then
  if command -v win32yank.exe >/dev/null 2>&1; then
    alias clip="win32yank.exe -i"
    alias paste="win32yank.exe -o"
  fi
fi
