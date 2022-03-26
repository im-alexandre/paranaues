local tabsize = 4

local settings = {
    cmdheight = 2,
    shell = "/bin/bash",
    cursorline = true,
    modifiable = true,
    splitbelow = true,
    splitright = true,
    secure = true,
    exrc = true,
    hidden = true,
    scrolloff = 8,
    nu = true,
    relativenumber = true,
    foldmethod = "indent",
    foldlevel = 99,
    encoding = 'utf-8',
    hlsearch = false,
    backup = false,
    swapfile = false,
    incsearch = true,
    undofile = true,
    undodir = vim.g['vim_home'] .. '/tmp',
    signcolumn = "yes",
    wrap = false,
    errorbells = false,
    clipboard = "unnamedplus",
    tabstop = tabsize,
    softtabstop = tabsize,
    shiftwidth = tabsize,
    expandtab = true,
    autoindent = true,
    fileformat = "unix",
    colorcolumn = "80",
    completeopt = {'menu','menuone','noselect' },
    updatetime = 50
}

for key, value in pairs(settings) do
    vim.opt[key] = value
end

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

