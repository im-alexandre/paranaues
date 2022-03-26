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
    incsearch = true,
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
}

for key, value in pairs(settings) do
    vim.opt[key] = value
end

vim.highlight.create('ColorColumn', {ctermbg=0, guibg=lightgrey}, false)
