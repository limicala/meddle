local dir  = require "os.dir"
local skynet = require "skynet"

local file = Module("file")

function file.write(file_pathname, file_content)
    local dir_pat = '(.+)/[^/]+$'
    local directory = file_pathname:match(dir_pat)
    dir.make_path(directory)

    local f = assert(io.open(file_pathname, 'w'))
    f:write(file_content)
    f:flush()
    f:close()
end

function file.read(file_pathname)
    local f = assert(io.open(file_pathname, 'rb'))
    local content = f:read('*a')
    f:close()
    return content
end

function file.dofile(file_pathname)
    local content = assert(file.read(file_pathname))
    local doFile = assert(load(content, "chunk", "bt", setmetatable({}, { __index = _ENV })))
    local _, ret = assert(skynet.pcall(doFile))
    return ret
end

return file
