vim.pack.add({
        { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
})

require('nvim-treesitter').install({
        'css',
        'html',
        'typescript',
        'vue',
        'python',
        'yaml',
        'julia',
})

vim.api.nvim_create_autocmd('BufEnter', {
        callback = function(args)
                vim.schedule(function()
                        if vim.api.nvim_buf_is_valid(args.buf) then
                                pcall(vim.treesitter.start, args.buf)
                        end
                end)
        end,
})
