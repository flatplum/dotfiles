if vim.b._compiler then
        require('compilers.' .. vim.b._compiler).reset(
                vim.api.nvim_get_current_buf()
        )
end
