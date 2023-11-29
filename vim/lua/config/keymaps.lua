local mapkey = require("util.keymapper").mapkey
-- Buffer Navigation
mapkey("<leader>bn", "bnext", "n") -- Next buffer
mapkey("<leader>bp", "bprevious", "n") -- Prev buffer
mapkey("<leader>bb", "e #", "n") -- Switch to Other Buffer
mapkey("<leader>`", "e #", "n") -- Switch to Other Buffer

-- Directory Navigatio}n
mapkey("<leader>m", "NvimTreeFocus", "n")
mapkey("<F3>", "NvimTreeToggle", "n")

-- Pane and Window Navigation
mapkey("<C-h>", "<C-w>h", "n") -- Navigate Left
mapkey("<C-j>", "<C-w>j", "n") -- Navigate Down
mapkey("<C-k>", "<C-w>k", "n") -- Navigate Up
mapkey("<C-l>", "<C-w>l", "n") -- Navigate Right
mapkey("<C-h>", "wincmd h", "t") -- Navigate Left
mapkey("<C-j>", "wincmd j", "t") -- Navigate Down
mapkey("<C-k>", "wincmd k", "t") -- Navigate Up
mapkey("<C-l>", "wincmd l", "t") -- Navigate Right
mapkey("<C-h>", "TmuxNavigateLeft", "n") -- Navigate Left
mapkey("<C-j>", "TmuxNavigateDown", "n") -- Navigate Down
mapkey("<C-k>", "TmuxNavigateUp", "n") -- Navigate Up
mapkey("<C-l>", "TmuxNavigateRight", "n") -- Navigate Right

-- Window Management
mapkey("<leader>sv", "vsplit", "n") -- Split Vertically
mapkey("<leader>sh", "split", "n") -- Split Horizontally

-- Indenting
mapkey("<", "v", "<gv") -- Shift Indentation to Left
mapkey(">", "v", ">gv") -- Shift Indentation to Right

-- Show Full File-Path
mapkey("<leader>pa", "echo expand('%:p')", "n") -- Show Full File Path

local api = vim.api

-- Comments
api.nvim_set_keymap("n", "<C-_>", "gtc", { noremap = false })
api.nvim_set_keymap("v", "<C-_>", "goc", { noremap = false })

-- Git - Vim-fugitive
vim.keymap.set("n", "<leader>gj", ":diffget //3<CR>")
vim.keymap.set("n", "<leader>gf", ":diffget //2<CR>")

vim.keymap.set("n", "<leader>gs", ":G<CR>")
vim.keymap.set("n", "<leader>gc", ":Git commit<CR>")

vim.keymap.set("n", "<leader>cx", ":call CompilaLatex()<CR>")

vim.keymap.set("n", "<leader>md", ":MarkdownPreview<CR>")
vim.keymap.set("n", "<S-l>", ":tabnex<CR>")
vim.keymap.set("n", "<S-h>", ":tabprev<CR>")

-- Split resize
vim.keymap.set("n", "<A-+>", ":vertical resize +15<CR>")
vim.keymap.set("n", "<A-->", ":vertical resize -15<CR>")
vim.keymap.set("n", "<leader>v+", ":resize +15<CR>")
vim.keymap.set("n", "<leader>v-", ":resize -15<CR>")

-- Identação em blocos
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set("v", "p", '"_dP') -- colar não substitui o register

-- MarkDown
vim.keymap.set("n", "<Leader>md", ":MarkdownPreview<CR>")
vim.keymap.set("n", "<Leader>cr", ":call Captura()<CR>")

-- Harpoon
vim.keymap.set("n", "<leader>gt", function()
	term_number = vim.fn.input("Número do terminal: ")
	if term_number == nil or term_number == "" then
		term_number = 1
	end
	require("harpoon.term").gotoTerminal(tonumber(term_number))
end)
vim.keymap.set("n", "<leader>hp", ":lua require('harpoon.ui').toggle_quick_menu()<CR>")
vim.keymap.set("n", "<leader>ha", ':lua require("harpoon.mark").add_file()<CR>')

-- Undoo tree
vim.keymap.set("n", "<F5>", ":UndotreeToggle<CR>")
