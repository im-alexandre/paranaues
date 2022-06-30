local function map(mode, shortcut, command)
  vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = true, silent = true })
end

local function nmap(shortcut, command)
  map('n', shortcut, command)
end

--local function imap(shortcut, command)
  --map('i', shortcut, command)
--end

local function vmap(shortcut, command)
  map('v', shortcut, command)
end

nmap("<C-J>", "<C-W><C-J>")
nmap("<C-K>", "<C-W><C-K>")
nmap("<C-L>", "<C-W><C-L>")
nmap("<C-H>", "<C-W><C-H>")

nmap("<A-+>", ":vertical resize +15<CR>")
nmap("<A-->", ":vertical resize -15<CR>")
nmap("<leader>v+", ":resize +15<CR>")
nmap("<leader>v-", ":resize -15<CR>")
nmap("<Leader>md", ":MarkdownPreview<CR>")
nmap("<Leader>cr", ":call Captura()<CR>")

-- Git - Vim-fugitive
nmap("<leader>gj", ":diffget //3<CR>")
nmap("<leader>gf", ":diffget //2<CR>")

nmap("<leader>gs", ":G<CR>")
nmap("<leader>gc", ":Git commit<CR>")

nmap("<leader>cx", ":call CompilaLatex()<CR>")

nmap("<leader>md", ":MarkdownPreview<CR>")
nmap("<S-l>", ":tabnex<CR>")
nmap("<S-h>", ":tabprev<CR>")

-- Troca de aba no vim
vmap("<", "<gv")
vmap(">", ">gv")

 -- colar não substitui o register
vmap("p", '"_dP')


require('telescope').setup{
defaults = {
    prompt_prefix = "$ "
    }
}

-- Harpoon
nmap('<leader>gt', ':lua require("harpoon.term").gotoTerminal(1)<CR>')
nmap("<leader>hp", ":lua require('harpoon.ui').toggle_quick_menu()<CR>")
nmap('<leader>ha', ':lua require("harpoon.mark").add_file()<CR>')
