-- Sync clipboard between OS and Neovim. Schedule the setting after `UiEnter`
-- because it can increase startup-time.
vim.api.nvim_create_autocmd('UIEnter', {
        callback = function()
                vim.o.clipboard = 'unnamedplus'
        end,
})
vim.o.mouse = ''
vim.o.scrolloff = 11

-- Display
vim.o.cc = '80'
vim.o.cursorcolumn = true
vim.o.cursorline = true
vim.o.list = true
vim.o.number = true
vim.o.relativenumber = true

-- Tab
vim.o.expandtab = true
vim.o.shiftwidth = 8
vim.o.softtabstop = 8
vim.o.tabstop = 8

-- Highlight when yanking (copying) text.
vim.api.nvim_create_autocmd('TextYankPost', {
        desc = 'Highlight when yanking (copying) text',
        callback = function()
                vim.hl.on_yank()
        end,
})
