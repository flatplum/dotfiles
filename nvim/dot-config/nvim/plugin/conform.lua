vim.pack.add({
        { src = 'https://github.com/stevearc/conform.nvim' },
})

local conform = require('conform')
conform.setup({
        formatters_by_ft = {
                lua = { 'stylua' },
        },
})

vim.keymap.set('n', '<leader>lf', conform.format)
