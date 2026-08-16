local M = {}

local find_first_ancestor = require('utils.treesitter').find_first_ancestor

---@return integer
local function get_cursor_byte()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        return vim.api.nvim_buf_get_offset(0, row - 1) + col
end

---@return boolean
function M.in_mathmode()
        local node = find_first_ancestor({
                'text_mode',
                'inline_formula',
                'math_environment',
                'displayed_equation',
        })
        if not node then
                return false
        end

        local cursor_byte = get_cursor_byte()
        if node:type() == 'text_mode' then
                -- Ignore first character as its technically outside
                if select(3, node:range(true)) ~= cursor_byte then
                        return false
                end
                node = find_first_ancestor({
                        'inline_formula',
                        'math_environment',
                        'displayed_equation',
                })
                if not node then
                        return false
                end
        end

        local inner
        local text = vim.treesitter.get_node_text(node, 0)
        local _, _, node_start = node:range(true)
        local exps = {
                [[^%$%$(.*)%$%$$]],
                [[^%$(.*)%$$]],
                [[^\%((.*)\%)$]],
                [[^\%[(.*)\%]$]],
                [[^\begin{.-}(.*)\end{.-}$]],
        }
        for _, exp in ipairs(exps) do
                inner = select(3, text:find(exp))
                if inner then
                        break
                end
        end
        if not inner then
                -- In theory, this shouldn't happen
                return false
        end

        local inner_start, inner_end = text:find(inner, 1, true) -- Relative
        return cursor_byte >= node_start + inner_start - 1
                and cursor_byte <= node_start + inner_end
end

---@return boolean
function M.notin_mathmode()
        return not M.in_mathmode()
end

return M
