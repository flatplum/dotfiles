local M = {}

---@param nodetype string|string[]
---@return TSNode?
function M.find_first_ancestor(nodetype)
        local node = vim.treesitter.get_node()
        if type(nodetype) == 'string' then
                nodetype = { nodetype }
        end

        while node do
                for _, v in pairs(nodetype) do
                        if node:type() == v then
                                return node
                        end
                end

                node = node:parent()
        end

        return nil
end

return M
