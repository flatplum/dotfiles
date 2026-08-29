vim.g.mapleader = ' '

vim.keymap.set('n', '<leader>e', vim.cmd.Ex)
vim.keymap.set('n', '<leader>t', vim.cmd.terminal)
vim.keymap.set('n', '<leader>rr', vim.cmd.restart)
vim.keymap.set('n', '<leader>m', ':make ')

vim.keymap.set('n', '<leader>ss', function()
        vim.wo.spell = not vim.wo.spell
                or vim.api.nvim_get_option_info2('spell').default
end)
-- Adapted from https://castel.dev/post/lecture-notes-1/
-- I might enjoy short variable names a little too much
vim.keymap.set({ 'n', 'i' }, '<C-l>', function()
        if not vim.wo.spell then
                return
        end
        local function nfk(k)
                vim.api.nvim_feedkeys(
                        vim.api.nvim_replace_termcodes(k, true, false, true),
                        'n',
                        false
                )
        end
        local cb = #vim.api.nvim_get_current_line()
        local r, c = unpack(vim.api.nvim_win_get_cursor(0))
        local ni = vim.api.nvim_get_mode().mode == 'n'
        nfk((ni and 'a' or '') .. '<C-g>u')
        vim.cmd('normal! l')
        vim.cmd('normal! [S1z=')
        local ca = #vim.api.nvim_get_current_line()
        local cn = r == vim.api.nvim_win_get_cursor(0)[1] and c + ca - cb or c
        vim.api.nvim_win_set_cursor(0, {
                r,
                cn,
        })
        nfk('<C-g>u' .. (ni and '<Esc>' or ''))
end)

vim.api.nvim_create_user_command('SetIndent', function(opts)
        local n = tonumber(opts.args) or 8

        vim.o.shiftwidth = n
        vim.o.tabstop = n
end, { nargs = '?' })
