-- LSP Setup para golang
-- go install golang.org/x/tools/gopls@latest

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
require'lspconfig'.gopls.setup{
    capabilities=capabilities,
    on_attach = function()
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer=0 })
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer=0 })
    vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { buffer=0 })
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer=0 })
    vim.keymap.set("n", "<leader>dj", vim.diagnostic.goto_next, { buffer=0 })
    vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics<cr>", { buffer=0 })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer=0 })
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer=0 })
end,
}
