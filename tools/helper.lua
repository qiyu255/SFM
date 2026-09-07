
local helper = {}
function helper.show(text)
    local nu = 1
    for line in text:gmatch("[^\n]*") do
        print(string.format("%2d| %s", nu, line))
        nu = nu + 1
    end
end

function helper.diff(source, target, horizontal)
    horizontal = horizontal or false
    local nu = 1

    -- 将字符串按行存入表
    local source_lines = {}
    for line in source:gmatch("[^\n]*") do
        table.insert(source_lines, line)
    end

    local target_lines = {}
    for line in target:gmatch("[^\n]*") do
        table.insert(target_lines, line)
    end

    local max_lines = math.max(#source_lines, #target_lines)

    if horizontal then
        local max_width = 0
        for i, line in ipairs(source_lines) do
            max_width = math.max(max_width, #line)
        end
        for i = 1, max_lines do
            local s = source_lines[i] or ""
            local t = target_lines[i] or ""
            s = s .. string.rep(" ", max_width - #s)
            print(string.format("%2d| %s | %s", i, s, t))
        end
    else
        -- 逐行比较
        for i = 1, max_lines do
            local s = source_lines[i] or ""
            local t = target_lines[i] or ""
            if s ~= t then
                print(string.format("%2d| %s", i, s))
                print(string.format("%2d| %s", i, t))
            end
        end
    end
end

function helper.tprint(t)
    for k, v in pairs(t) do
        print(string.format('%s = %s', k, v))
    end
end

return helper