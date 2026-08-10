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
