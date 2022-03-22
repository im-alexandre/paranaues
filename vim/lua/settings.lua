local set = vim.opt
local cmd = vim.cmd

local tabsize = 4

local settings = {
    { "cmdheight", 2 },
    { "shell", "/bin/bash" },
    { "cursorline", true },
    { "modifiable", true },
    { "splitbelow", true },
    { "splitright", true },
    { "secure", true },
    { "exrc", true },
    { "hidden", true },
    { "scrolloff", 8 },
    { "nu", true },
    { "relativenumber", true },
    { "incsearch", true },
    { "foldmethod", "indent" },
    { "foldlevel", 99 },
    { "encoding", 'utf-8' },
    { "hlsearch", false },
    { "backup", false },
    { "swapfile", false },
    { "incsearch", true },
    { "undofile", true },
    { "undodir", "~/.config/nvim/tmp/undodir" },
    { "signcolumn", "yes" },
    { "wrap", false },
    { "errorbells", false },
    { "clipboard", "unnamedplus" },
    { "tabstop", tabsize },
    { "softtabstop", tabsize },
    { "shiftwidth", tabsize },
    { "expandtab", true },
    { "autoindent", true },
    { "fileformat", "unix" },
    { "colorcolumn", "80" },
}

for _,value in ipairs(settings) do
    vim.opt[value[1]] = value[2]
end

vim.highlight.create('ColorColumn', {ctermbg=0, guibg=lightgrey}, false)
