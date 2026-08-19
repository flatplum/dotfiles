---@class ViewerData
---@field process vim.SystemObj
---@field callback function
---@class State
---@field viewers table<integer, ViewerData>
---@field autocommands integer[]
---@field dependencies table<string, integer[]>
local state = {
        viewers = {},
        autocommands = {},
        dependencies = {},
}

local M = {}

-- function M.inspect()
--         vim.notify(vim.inspect(state))
-- end

---@param buf integer
---@param ext string?
local function get_canonical(buf, ext)
        return vim.fs.normalize(
                vim.fn.expand('#' .. buf .. ':p' .. (ext and ':r' or ''))
                        .. (ext or '')
        )
end

---@param buf integer
local function config_compiler(buf)
        vim.api.nvim_set_option_value(
                'makeprg',
                'latexmk -pdf -g -interaction=nonstopmode -synctex=1 -file-line-error -outdir=%:h %',
                { buf = buf }
        )
        vim.api.nvim_buf_call(buf, function()
                vim.cmd([[
                        " Push file to file stack
                        setlocal errorformat=%-P**%f
                        setlocal errorformat+=%-P**\"%f\"

                        " Match errors
                        setlocal errorformat+=%+E!\ Emergency\ stop.
                        setlocal errorformat+=%E!\ LaTeX\ %trror:\ %m
                        setlocal errorformat+=%E!pdfTeX\ error:\ %m
                        setlocal errorformat+=%E%f:%l:\ \ ==>\ %m
                        setlocal errorformat+=%E%f:%l:\ %m
                        setlocal errorformat+=%+ERunaway\ argument?
                        setlocal errorformat+=%-G{/%m
                        setlocal errorformat+=%+C{%m
                        setlocal errorformat+=%C!\ %m

                        " More info for undefined control sequences
                        setlocal errorformat+=%Z<argument>\ %m

                        " More info for some errors
                        setlocal errorformat+=%Cl.%l\ %m

                        "
                        " Define general warnings
                        "
                        setlocal errorformat+=%+WLaTeX\ Font\ Warning:\ %.%#line\ %l%.%#
                        setlocal errorformat+=%+WLaTeX\ Font\ Warning:\ %m
                        setlocal errorformat+=%-C(Font)\ %#%m\ on\ input\ line\ %l%.
                        setlocal errorformat+=%-C(Font)%m

                        setlocal errorformat+=%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#
                        setlocal errorformat+=%+WLaTeX\ %.%#Warning:\ %m
                        setlocal errorformat+=%-C\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ %m\ on\ input\ line\ %l%.

                        setlocal errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
                        setlocal errorformat+=%+WOverfull\ %\\%\\hbox%.%#\ at\ line\ %l
                        setlocal errorformat+=%+WOverfull\ %\\%\\vbox%.%#\ at\ line\ %l
                        setlocal errorformat+=%+WOverfull\ %\\%\\vbox%.%#\ %m

                        setlocal errorformat+=%+WUnderfull\ %\\%\\hbox%.%#\ at\ lines\ %l--%*\\d
                        setlocal errorformat+=%+WUnderfull\ %\\%\\vbox%.%#\ at\ line\ %l

                        setlocal errorformat+=%+WMissing\ character:\ %m

                        "
                        " Define package related warnings
                        "
                        setlocal errorformat+=%+WPackage\ natbib\ Warning:\ %m\ on\ input\ line\ %l.

                        setlocal errorformat+=%+WPackage\ biblatex\ Warning:\ %m
                        setlocal errorformat+=%-C(biblatex)%.%#in\ t%.%#
                        setlocal errorformat+=%-C(biblatex)%.%#Please\ v%.%#
                        setlocal errorformat+=%-C(biblatex)%.%#LaTeX\ a%.%#
                        setlocal errorformat+=%-C(biblatex)%m

                        setlocal errorformat+=%+WPackage\ babel\ Warning:\ %m
                        setlocal errorformat+=%-Z(babel)%.%#input\ line\ %l.
                        setlocal errorformat+=%-C(babel)%m

                        setlocal errorformat+=%+WPackage\ hyperref\ Warning:\ %m
                        setlocal errorformat+=%-C(hyperref)%m\ on\ input\ line\ %l.
                        setlocal errorformat+=%-C(hyperref)%m

                        setlocal errorformat+=%+WPackage\ scrreprt\ Warning:\ %m
                        setlocal errorformat+=%-C(scrreprt)%m

                        setlocal errorformat+=%+WPackage\ fixltx2e\ Warning:\ %m
                        setlocal errorformat+=%-C(fixltx2e)%m

                        setlocal errorformat+=%+WPackage\ titlesec\ Warning:\ %m
                        setlocal errorformat+=%-C(titlesec)%m

                        setlocal errorformat+=%+WPackage\ silence\ Warning:\ %m
                        setlocal errorformat+=%-C(silence)%m

                        setlocal errorformat+=%+WPackage\ %.%#\ Warning:\ %m\ on\ input\ line\ %l.
                        setlocal errorformat+=%+WPackage\ %.%#\ Warning:\ %m
                        setlocal errorformat+=%-Z(%.%#)\ %m\ on\ input\ line\ %l.
                        setlocal errorformat+=%-C(%.%#)\ %m

                        setlocal errorformat+=%+W%.%#\ Warning:\ %m\ on\ input\ line\ %l.

                        " Ignore unmatched lines
                        setlocal errorformat+=%-G%.%#
                ]])
        end)
end

---@param buf integer
---@return vim.SystemObj
local function create_viewer(buf)
        return vim.system(
                {
                        'zathura',
                        '-x',
                        [[bash -c 'nvim --server ]]
                                .. vim.v.servername
                                .. [[ --remote "%{input}" && nvim --server ]]
                                .. vim.v.servername
                                .. [[ --remote-send "%{line}G"']],
                        get_canonical(buf, '.pdf'),
                },
                nil,
                vim.schedule_wrap(function()
                        local viewer = state.viewers[buf]
                        if viewer then
                                viewer.callback()
                        end
                end)
        )
end

---@param buf integer
---@param file string?
local function synctex_view(buf, file)
        file = file or get_canonical(buf)
        local pdf = get_canonical(buf, '.pdf')
        local r, c = unpack(vim.api.nvim_win_get_cursor(0))
        local function run()
                return vim.system({
                        'zathura',
                        '--synctex-forward',
                        r .. ':' .. c + 1 .. ':' .. file,
                        '--synctex-pid',
                        tostring(state.viewers[buf].process.pid),
                        pdf,
                })
        end
        local result = run():wait()
        if result.stderr ~= '' then
                -- This happens if the current file open by the viewer has
                -- changed.
                local callback = state.viewers[buf].callback
                state.viewers[buf].callback = function()
                        state.viewers[buf].process = create_viewer(buf)
                        state.viewers[buf].callback = callback
                        vim.defer_fn(function()
                                run()
                        end, 150)
                end
                state.viewers[buf].process:kill('sigterm')
        end
end

---@class Options
---@field noorder boolean?
---@field viewfile string?
---@param buf integer
---@param opts Options?
local function make(buf, opts)
        opts = opts or {}
        local x = vim.fn.winsaveview()
        vim.api.nvim_buf_call(buf, function()
                vim.cmd('silent make')
        end)
        for line in io.lines(get_canonical(buf, '.fls')) do
                local file = line:match('^INPUT (.+)$')
                if file then
                        local path = vim.fs.normalize(vim.fs.abspath(file))
                        state.dependencies[path] = state.dependencies[path]
                                or {}
                        local i = vim.iter(state.dependencies[path])
                                :enumerate()
                                :find(function(_, v)
                                        return v == buf
                                end)
                        if not opts.noorder and i then
                                table.remove(state.dependencies[path], i)
                        end
                        if not opts.noorder or not i then
                                table.insert(state.dependencies[path], 1, buf)
                        end
                end
        end
        vim.fn.winrestview(x)
        if state.viewers[buf] then
                vim.defer_fn(function()
                        synctex_view(buf, opts.viewfile)
                end, 150)
        end
        if next(vim.fn.getqflist()) ~= nil then
                vim.cmd('copen')
                return
        end
        vim.cmd('cclose')
end

local function cleanup()
        for _, id in pairs(state.autocommands) do
                vim.api.nvim_del_autocmd(id)
        end
        state.autocommands = {}
        state.dependencies = {}
end

function M.view_one(file)
        local buf = (state.dependencies[file] or {})[1]
        if not buf then
                return
        end
        synctex_view(buf, file)
end

function M.view_all(file)
        local bufs = state.dependencies[file]
        if not bufs then
                return
        end
        for _, v in pairs(bufs) do
                synctex_view(v, file)
        end
end

---@param buf integer
function M.toggle_compilation(buf)
        -- Comfortable checking for existence of viewer process as viewer
        -- lifecycle is linked to compilation
        if state.viewers[buf] then
                vim.cmd('compiler make')
        else
                vim.cmd('compiler tex')
        end
end

---@param buf integer
function M.reset(buf)
        vim.b[buf]._compiler = nil
        vim.api.nvim_buf_call(buf, function()
                vim.cmd('setlocal makeprg&')
                vim.cmd('setlocal errorformat&')
        end)
        if state.viewers[buf] then
                local process = state.viewers[buf].process
                process:kill('sigterm')
                state.viewers[buf] = nil
        end
        for _, v in pairs(state.dependencies) do
                for i, w in pairs(v) do
                        if w == buf then
                                table.remove(v, i)
                        end
                end
        end
        if vim.tbl_count(state.viewers) == 0 then
                cleanup()
        end
end

---@param buf integer?
function M.setup(buf)
        buf = buf or vim.api.nvim_get_current_buf()

        if vim.bo[buf].filetype ~= 'tex' then
                return
        end

        local ifile = get_canonical(buf)
        local ofile = get_canonical(buf, '.pdf')

        -- Set initial compiler settings and attempt make
        vim.b[buf]._compiler = 'tex'
        config_compiler(buf)
        make(buf)

        -- If resulting file is malformed, gracefully exit
        if vim.fn.filereadable(ofile) == 0 then
                M.reset(buf)
                vim.system({
                        'latexmk',
                        '-c',
                        ifile,
                        '--outdir=' .. vim.fn.expand('#' .. buf .. ':p:h'),
                })
                return
        end

        -- If compiler already running, gracefully exit
        if state.viewers[buf] then
                return
        end

        -- Create new viewer process
        local process = create_viewer(buf)
        state.viewers[buf] = {
                process = process,
                callback = function()
                        M.reset(buf)
                end,
        }
        vim.defer_fn(function()
                synctex_view(buf)
        end, 150)

        -- If there are autocommands, then we expect at least one other
        -- instance of the tex compiler. Otherwise something has gone seriously
        -- wrong!
        if vim.tbl_count(state.autocommands) ~= 0 then
                if vim.tbl_count(state.viewers) ~= 1 then
                        return
                end
                vim.notify(
                        'Orphaned autocommands found,'
                                .. ' refusing to enable buffer.'
                                .. ' A restart might fix this.'
                )
                return
        end

        table.insert(
                state.autocommands,
                vim.api.nvim_create_autocmd('VimLeavePre', {
                        callback = function()
                                for _, p in pairs(state.viewers) do
                                        p.process:kill('sigterm')
                                end
                        end,
                })
        )
        table.insert(
                state.autocommands,
                vim.api.nvim_create_autocmd('BufWritePost', {
                        pattern = { '*.tex' },
                        callback = function(args)
                                local file = vim.fs.normalize(
                                        vim.fs.abspath(args.file)
                                )
                                local dependencies = state.dependencies[file]
                                        or {}
                                for _, v in ipairs(dependencies) do
                                        make(v, {
                                                noorder = #dependencies > 1,
                                                viewfile = file,
                                        })
                                end
                        end,
                })
        )
        table.insert(
                state.autocommands,
                vim.api.nvim_create_autocmd('BufDelete', {
                        pattern = { '*.tex' },
                        callback = function(args)
                                M.reset(args.buf)
                        end,
                })
        )
end

return M
