vim.g.mapleader = ' '

vim.keymap.set('n', '<leader>e', vim.cmd.Ex)

vim.api.nvim_create_user_command('SetIndent', function (opts)
        local n = tonumber(opts.args) or 8

        vim.o.shiftwidth = n
        vim.o.softtabstop = n
        vim.o.tabstop = n
end, { nargs = '?' })
