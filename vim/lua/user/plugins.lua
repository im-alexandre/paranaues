local Plug = vim.fn['plug#']
local plug_install = vim.g['vim_plugin_install']
vim.call('plug#begin', plug_install)
    --Plug 'tpope/vim-sensible'
    Plug 'lewis6991/gitsigns.nvim'
    Plug 'jiangmiao/auto-pairs'


    -- Telescope e Harpoon
    Plug ('nvim-treesitter/nvim-treesitter', {['do'] = vim.fn[':TSUpdate']})  -- We recommend updating the parsers on update
    Plug 'burntsushi/ripgrep'
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'sharkdp/fd'

    Plug 'nvim-telescope/telescope.nvim'
    Plug 'ThePrimeagen/harpoon'

    --LSP autocomplete
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'hrsh7th/cmp-buffer'
    Plug 'hrsh7th/cmp-path'
    Plug 'L3MON4D3/LuaSnip'
    Plug 'saadparwaiz1/cmp_luasnip'
    

    Plug 'tpope/vim-fugitive'

    Plug 'ryanoasis/vim-devicons'

    Plug ('iamcco/markdown-preview.nvim', {['do'] = vim.fn['cd app && ./install.sh && yarn install']})
    Plug 'vimwiki/vimwiki'

    -- Code commenter
    Plug 'scrooloose/nerdcommenter'

    -- Better file browser
    Plug 'scrooloose/nerdtree'
    Plug 'mbbill/undotree'
    Plug 'sheerun/vim-polyglot'

    -- Plug 'Vimjas/vim-python-pep8-indent'
    Plug 'dense-analysis/ale'
    Plug 'vim-utils/vim-man'

    --" Class/module browser
    Plug 'majutsushi/tagbar'

    --"dockerfile
    --Plug 'ekalinin/Dockerfile.vim'
    --
    --"Snippets
    Plug 'MarcWeber/vim-addon-mw-utils'
    Plug 'tomtom/tlib_vim'
    Plug 'honza/vim-snippets'
    Plug 'garbas/vim-snipmate'
    --" Airline
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'

    --"colorscheme
    Plug 'gruvbox-community/gruvbox'
    Plug 'lukas-reineke/indent-blankline.nvim'

    -- LSP
    Plug 'neovim/nvim-lspconfig'

vim.call('plug#end')


vim.g['vimtex_fold_enabled'] = 1
vim.g['tex_flavor'] = 'latex'
vim.g['snipMate'] = { ['snippet_version'] = 1 }
vim.g.mapleader = " "
vim.g['fancy_symbols_enabled'] = 1
vim.g['vimwiki_key_mappings'] = { ['all_maps'] = 1, 
       ['global']= 1,
       ['headers']= 1,
       ['text_objs']= 1,
       ['table_format']= 1,
       ['table_mappings']= 0,
       ['lists']= 0,
       ['links']= 0,
       ['html']= 1,
       ['mouse']= 0,
}

function map(mode, shortcut, command)
  vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = true, silent = true })
end

function nmap(shortcut, command)
  map('n', shortcut, command)
end

function imap(shortcut, command)
  map('i', shortcut, command)
end

function vmap(shortcut, command)
  map('v', shortcut, command)
end

nmap("<C-J>", "<C-W><C-J>")
nmap("<C-K>", "<C-W><C-K>")
nmap("<C-L>", "<C-W><C-L>")
nmap("<C-H>", "<C-W><C-H>")

nmap("<Leader>v+", ":vertical resize +15<CR>")
nmap("<Leader>v-", ":vertical resize -15<CR>")
nmap("v+", ":resize +15<CR>")
nmap("v+", ":resize +15<CR>")
nmap("<Leader>mx", ":MarkdownPreview<CR>")
nmap("<Leader>cr", ":call Captura()<CR>")

-- Git - Vim-fugitive
nmap("<leader>gj", ":diffget //3<CR>")
nmap("<leader>gf", ":diffget //2<CR>")

nmap("<leader>gs", ":G<CR>")
nmap("<leader>gc", ":Git commit<CR>")

nmap("<leader>cx", ":call CompilaLatex()<CR>")

nmap("<leader>md", ":MarkdownPreview<CR>")

require('telescope').setup{
defaults = {
    prompt_prefix = "$ "
    }
}

-- Harpoon
nmap('<leader>gt', ':lua require("harpoon.term").gotoTerminal(1)<CR>')
nmap("<leader>hp", ":lua require('harpoon.ui').toggle_quick_menu()<CR>")
nmap('<leader>ha', ':lua require("harpoon.mark").add_file()<CR>')
--vim.keymap.set("n", "<leader>gt", require("harpoon.term").gotoTerminal)
