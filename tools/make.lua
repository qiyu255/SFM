local m = require('tools.template')

-- 配置
local OUT_DIR = "dist"
local TIME_FMT = "%Y-%m-%d %H:%M:%S"
local sep = package.config:sub(1, 1)



local function mkdir(path)
    return os.execute("mkdir " .. string.format("%q", path))
end

local function dirname(filepath)
    if filepath == "" then
        return ""
    end

    local path = filepath:gsub("[/\\]+$", "")

    if path == "" then
        return "/"
    end

    local dir = path:match("(.*)[/\\][^/\\]*$")

    return dir or ""
end


m.init({
    cmd_prefix = '---',
    var_prefix = '%',

    head = function()
        return 'build at ' .. os.date('%Y-%m-%d', os.time()) .. '\n'
    end
})


local function write(fp, text)
    local f, err = io.open(fp,'w')
    if err then
        local ok = mkdir(dirname(fp))
        f, err = io.open(fp,'w')
        if err or not ok then
            print(err)
            os.exit(2)
            return
        end
    end
    
    f:write(text)
    f:close()
end

local function make(fp)
    local data = {
        
    }
    
    write(OUT_DIR .. sep .. fp, m.load_file(fp, data))
end



local function main(args)
    if #args == 0 then
        print("Usage: lua make.lua <inputfile1> [inputfile2] ...")
        os.exit(1)
    end

    for _, fp in ipairs(args) do
        print('build ', fp)
        make(fp)
    end
end

main(arg)
