vim.keymap.set('n', '<F3>', vim.cmd.Ex)

local function map(mode, shortcut, command)
  vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = true, silent = true })
end

local function nmap(shortcut, command)
  map('n', shortcut, command)
end

local function vmap(shortcut, command)
  map('v', shortcut, command)
end


nmap("<A-=>", ":vertical resize +10<CR>")
nmap("<A-->", ":vertical resize -10<CR>")
nmap("<A-[>", ":resize +10<CR>")
nmap("<A-]>", ":resize -10<CR>")

nmap("<Leader>cr", ":call Captura()<CR>")

-- Git - Vim-fugitive
nmap("<leader>gj", ":diffget //3<CR>")
nmap("<leader>gf", ":diffget //2<CR>")

nmap("<leader>gs", ":G<CR>")
nmap("<leader>gc", ":Git commit<CR>")

nmap("<leader>md", ":MarkdownPreview<CR>")
nmap("<S-l>", ":tabnex<CR>")
nmap("<S-h>", ":tabprev<CR>")

-- Troca de aba no vim
nmap("<C-h>", ":tabprevious<CR>")
nmap("<C-l>", ":tabnext<CR>")

 -- colar não substitui o register
vmap("p", '"_dP')
