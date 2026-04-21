vim.pack.add({
        { src = 'https://github.com/hrsh7th/nvim-cmp', },
        { src = 'https://github.com/hrsh7th/cmp-nvim-lsp', },
        { src = 'https://github.com/hrsh7th/cmp-buffer', },
        { src = 'https://github.com/hrsh7th/cmp-path', },
        { src = 'https://github.com/hrsh7th/cmp-cmdline', },
})
-- Set up nvim-cmp.
local cmp = require'cmp'

cmp.setup({
        snippet = {
                -- REQUIRED - you must specify a snippet engine
                expand = function(args)
                        vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
                end,
        },
        window = {
                -- completion = cmp.config.window.bordered(),
                -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                ['<Tab>'] = cmp.mapping(function (fallback)
                        (cmp.visible() and cmp.select_next_item or fallback)()
                end),
                ['<S-Tab>'] = cmp.mapping(function (fallback)
                        (cmp.visible() and cmp.select_prev_item or fallback)()
                end)
        }),
        sources = cmp.config.sources({
                { name = 'nvim_lsp' },
        }, {
                { name = 'buffer' },
        })
})

-- To use git you need to install the plugin petertriho/cmp-git and uncomment lines below
-- Set configuration for specific filetype.
--[[ cmp.setup.filetype('gitcommit', {
        sources = cmp.config.sources({
                { name = 'git' },
        }, {
                { name = 'buffer' },
        })
})
require('cmp_git').setup() ]]--

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
                { name = 'buffer' }
        }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
                { name = 'path' }
        }, {
                { name = 'cmdline' }
        }),
        matching = { disallow_symbol_nonprefix_matching = false }
})

local lsps = require('lsp')
local capabilities = require('cmp_nvim_lsp').default_capabilities()
for _, v in pairs(lsps) do
        vim.lsp.config(v, {
                capabilities = capabilities
        })
end
