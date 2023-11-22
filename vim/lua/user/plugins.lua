local Plug = vim.fn['plug#']
local plug_install = vim.g['vim_plugin_install']
vim.call('plug#begin', plug_install)
    Plug 'tpope/vim-sensible'
    Plug 'lewis6991/gitsigns.nvim'
    Plug 'jiangmiao/auto-pairs'

    --Dart/Flutter
    Plug 'dart-lang/dart-vim-plugin'
    Plug 'thosakwe/vim-flutter'
    Plug 'natebosch/vim-lsc'
    Plug 'natebosch/vim-lsc-dart'

    -- Telescope e Harpoon
    Plug ('nvim-treesitter/nvim-treesitter', {['do'] = vim.fn[':TSUpdate']})  -- We recommend updating the parsers on update
    Plug 'burntsushi/ripgrep'
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'sharkdp/fd'

    Plug 'nvim-telescope/telescope.nvim'
    Plug 'ThePrimeagen/harpoon'

    -- Autocomplete
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-buffer'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'hrsh7th/cmp-path'
    Plug 'hrsh7th/cmp-cmdline'
    Plug 'saadparwaiz1/cmp_luasnip'
    Plug 'hrsh7th/cmp-nvim-lua'

    -- LSP
    --Plug 'williamboman/mason.nvim'
    Plug 'neovim/nvim-lspconfig'
    Plug 'williamboman/nvim-lsp-installer'

    -- Snippets
    Plug 'L3MON4D3/LuaSnip'
    Plug 'rafamadriz/friendly-snippets'

    -- Vim-git
    Plug 'tpope/vim-fugitive'

    Plug 'ryanoasis/vim-devicons'

    -- Markdown & docs
    Plug ('iamcco/markdown-preview.nvim', {['do'] = vim.fn['cd app && ./install.sh && npm install']})
    Plug 'vimwiki/vimwiki'

    -- Code commenter
    Plug 'scrooloose/nerdcommenter'

    -- Better file browser
    Plug 'scrooloose/nerdtree'
    Plug 'mbbill/undotree'
    Plug 'sheerun/vim-polyglot'

    --" Class/module browser
    Plug 'majutsushi/tagbar'

    --" Airline
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'

    --"colorscheme
    Plug 'gruvbox-community/gruvbox'
    Plug 'lukas-reineke/indent-blankline.nvim'

vim.call('plug#end')


