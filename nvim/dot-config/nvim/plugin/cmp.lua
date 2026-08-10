vim.pack.add({
        { src = 'https://github.com/hrsh7th/nvim-cmp' },
        { src = 'https://github.com/hrsh7th/cmp-nvim-lsp' },
        { src = 'https://github.com/hrsh7th/cmp-buffer' },
        { src = 'https://github.com/hrsh7th/cmp-path' },
        { src = 'https://github.com/hrsh7th/cmp-cmdline' },
        { src = 'https://github.com/L3MON4D3/LuaSnip' },
        { src = 'https://github.com/saadparwaiz1/cmp_luasnip' },
})
-- Set up nvim-cmp.
local luasnip = require('luasnip')
local cmp = require('cmp')

cmp.setup({
        snippet = {
                -- REQUIRED - you must specify a snippet engine
                expand = function(args)
                        vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
                end,
        },
        window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                                if luasnip.expandable() then
                                        luasnip.expand()
                                        return
                                elseif cmp.get_active_entry() then
                                        cmp.confirm({
                                                behavior = cmp.ConfirmBehavior.Replace,
                                                select = false,
                                        })
                                        return
                                end
                        end
                        fallback()
                end),
                ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                                cmp.select_next_item()
                        elseif luasnip.locally_jumpable(1) then
                                luasnip.jump(1)
                        else
                                fallback()
                        end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                                cmp.select_prev_item()
                        elseif luasnip.locally_jumpable(-1) then
                                luasnip.jump(-1)
                        else
                                fallback()
                        end
                end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
        }, {
                { name = 'buffer' },
        }),
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
require('cmp_git').setup() ]]
--

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
                { name = 'buffer' },
        },
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
                { name = 'path' },
        }, {
                { name = 'cmdline' },
        }),
        matching = { disallow_symbol_nonprefix_matching = false },
})

local lsps = require('lsp')
local capabilities = require('cmp_nvim_lsp').default_capabilities()
for _, v in pairs(lsps) do
        vim.lsp.config(v, {
                capabilities = capabilities,
        })
end

-- Somewhere in your Neovim startup, e.g. init.lua
require('luasnip').config.set_config({ -- Setting LuaSnip config

        -- Enable autotriggered snippets
        enable_autosnippets = true,

        -- Use Tab (or some other key if you prefer) to trigger visual selection
        store_selection_keys = '<Tab>',
})

require('luasnip.loaders.from_lua').load({
        paths = vim.fn.stdpath('config') .. '/snippets',
})
