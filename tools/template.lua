--[[
为什么下面这个模板 %i没有插入变量i
--- n = 9
--- for i=1, n do
echo x_%i
--- end

]]
local sandbox = {
    rawequal = rawequal,
    xpcall = xpcall,
    rawlen = rawlen,
    rawset = rawset,
    tonumber = tonumber,
    setmetatable = setmetatable,
    coroutine = coroutine,
    assert = assert,
    ipairs = ipairs,
    print = print,
    math = math,
    select = select,
    utf8 = utf8,
    pairs = pairs,
    rawget = rawget,
    arg = arg,
    next = next,
    pcall = pcall,
    getmetatable = getmetatable,
    string = string,
    error = error,
    _VERSION = _VERSION,
    warn = warn,
    collectgarbage = collectgarbage,
    tostring = tostring,
    table = table,
    type = type,

}

sandbox.__index = sandbox

function sandbox.now(fmt)
    return os.date(fmt or '%Y-%m-%d %H:%M:%S', os.time())
end

local m = {}
m.__index = m

function string.join(t, s)
    local _t = {}
    for i, v in ipairs(t) do
        _t[i] = tostring(v)
    end
    return table.concat(_t, s)
end

function m.expand(env, ...)
    for _, t in ipairs { ... } do
        if type(t) == 'table' then
            for k, v in pairs(t) do
                env[k] = v
            end
        end
    end

    env._G = env
    setmetatable(env, sandbox)

    return env
end

function m.create(env)
    local sb = {}
    sb._NAME = 'sandbox'
    sb._CMD = '---'
    sb._VAR = '%'
    sb._FMT = 'string.format'
    sb.head = nil
    sb.tail = nil
    m.expand(sb, env)
    sb.DATE = sb.now()

    return sb
end

function m.init(env)
    m.env = m.create()
end



function m.compile(line_iter, env)
    local nodes, t = {}, 'lua'

    for line in line_iter do
        local stripped = line:match("^%s*(.*)$")
        if stripped:sub(1, #env._CMD) == env._CMD then
            if t == 'doc' then
                nodes[#nodes] = nodes[#nodes] .. '}'
            end
            nodes[#nodes + 1] = stripped:sub(#env._CMD + 1)
            t = 'lua'
        else
            line = m.translate(line, env)
            line = line .. (line ~= '' and ', ' or '') .. '"\\n"'
            if t == 'doc' then
                nodes[#nodes] = nodes[#nodes] .. '\n, ' .. line
            else
                nodes[#nodes + 1] = 'put {' .. line
                t = 'doc'
            end
        end
    end
    if t == 'doc' then
        nodes[#nodes] = nodes[#nodes] .. '}'
    end

    return table.concat(nodes, '\n')
end

function m.translate(tl, env)
    local parts = {} -- 存放每个片段（字符串或表达式）
    local buf = ""   -- 累积纯文本
    local len = #tl
    local i = 1

    -- 将累积的纯文本作为字符串加入 parts
    local function flush()
        if #buf > 0 then
            table.insert(parts, string.format("%q", buf))
            buf = ""
        end
    end

    while i <= len do
        local c = tl:sub(i, i)
        if c == env._VAR then
            local nextc = tl:sub(i + 1, i + 1)

            if nextc == "{" then
                -- 1. %{ ... }
                flush()
                local close = tl:find("}", i + 2, true) -- 寻找配对 }
                if not close then
                    error("unmatched '{' in template")
                end
                local content = tl:sub(i + 2, close - 1)
                -- 检查是否含有格式说明符（第一个冒号）
                local colon = content:find(":", 1, true)
                if colon then
                    local expr = content:sub(1, colon - 1)
                    local spec = content:sub(colon + 1)
                    if #spec > 0 then
                        -- 带格式：format('%.2f', expr)
                        table.insert(parts, env._FMT .. "('%" .. spec .. "', " .. expr .. ")")
                    else
                        -- 冒号后无内容，视为普通表达式
                        table.insert(parts, expr)
                    end
                else
                    -- 普通表达式
                    table.insert(parts, content)
                end
                i = close + 1
            elseif nextc == env._VAR then
                -- 2. %% → 输出百分号本身
                buf = buf .. env._VAR
                i = i + 2
            elseif nextc and nextc:match("[%a_]") then
                -- 3. %identifier
                flush()
                -- 读取完整的标识符（字母、数字、下划线）
                local ident = tl:match("^[%a_][%w_%.]*", i + 1)
                -- table.insert(parts, string.format('_id(%q)', ident))
                table.insert(parts, ident)
                i = i + #ident + 1

            else
                -- 4. % 后接其他字符，当作普通字符处理
                buf = buf .. c
                if nextc then
                    buf = buf .. nextc
                    i = i + 2
                else
                    i = i + 1
                end
            end
        else
            -- 普通字符，累积到纯文本缓冲区
            buf = buf .. c
            i = i + 1
        end
    end

    flush()
    return table.concat(parts, ", ")
end

function m.eval(line_iter, env)
    local sb = {
        _NAME = 'sandbox',
        _doc = {},
        output = '',
    }

    function sb.put(t)
        table.insert(sb._doc, table.concat(t))
    end

    function sb.divider()
        sb.put { '------------\n' }
    end

    function sb._id(id)
        if not id or id == "" then
            return sb._VAR..id
        end

        local current = sb
        for part in string.gmatch(id, "[^.]+") do
            if type(current) ~= "table" then
                return sb._VAR..id
            end
            current = current[part]
            if current == nil then
                return sb._VAR..id
            end
        end
        return tostring(current)
    end

    m.expand(sb, env)

    local code = m.compile(line_iter, sb)

    if m._debug then
        print(code)
    end

    local render, err = load(code, sb._NAME, "t", sb)
    if not render then
        error("Template load error: " .. err)
    end

    render()

    sb.output = table.concat(sb._doc)

    if type(sb.head) == "function" then
        sb.output = sb:head() .. sb.output
    end

    if type(sb.tail) == "function" then
        sb.output = sb.output .. sb:tail()
    end

    return sb.output
end

function m.load_string(s, env)
    return m.eval(s:gmatch("[^\n]*"), m.expand({}, m.env, env))
end

function m.load_file(path, env)
    local sb = {
        _NAME = path
    }
    sb = m.expand({}, m.env, sb, env)
    return m.eval(io.lines(path), sb)
end

return m
