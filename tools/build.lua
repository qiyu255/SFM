
local m = require('tools.template')


m.init({
    cmd_prefix = '---',
    var_prefix = '%',

    head = function ()
        return 'generate at '..os.date('%Y-%m-%d', os.time())..'\n'
    end
})


function build(input_file, output_file)

end

function build_all(filepaths_iter)
    
end

function use_cache(input_file)
    return false
end

function iter_dir(dir)
    
end

function main()
    build_all(iter_dir('src'))
end
