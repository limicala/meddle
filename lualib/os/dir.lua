local lfs = require "lfs"

local ldir = lfs.dir
local mkdir = lfs.mkdir
local sub = string.sub
local os,pcall,ipairs,pairs,require,setmetatable,_G = os,pcall,ipairs,pairs,require,setmetatable,_G
local remove = os.remove
local append = table.insert
local wrap = coroutine.wrap
local yield = coroutine.yield


-- https://github.com/katka-juhasova/BP-data/blob/7e9d23d217f69af7b8f0a9c063d9be54e992d8d5/modules/lusty-log-console/share/lua/5.3/pl/dir.lua

local dir = Module("dir")

function dir.attrib(file,aname)
    file = dir.normalize(file)
    return lfs.attributes(file, aname)
end

function dir.exists(path)
    return dir.attrib(path,'mode') ~= nil
end

function dir.isDir(path)
    if not type(path)=="string" then
        return false; 
    end
    return dir.attrib(path,'mode') == 'directory'
end

function dir.normalize(path)
    path = path:gsub("\\","/")
               :gsub("//","/")
    local m_2d_string, m_1d_string = "/[^/]+/%.%.", "/%./"
    while path:match(m_2d_string) or path:match(m_1d_string) do
        path = path:gsub(m_2d_string,"") 
                   :gsub(m_1d_string,"/")
                   :gsub("/$","")
    end
    return path
end

local dirpat = '(.+)/[^/]+$'
function dir.make_path(p)
    if not dir.isDir(p) then
        local subp = p:match(dirpat)
        local ok, err = dir.make_path(subp)
        if not ok then return nil, err end
        return mkdir(p)
   else
        return true
   end
end

function dir.getallfiles(start_path, all_files, pattern)
    pattern = pattern or ""

    local normalize = dir.normalize
    for filename, mode in dir.dirtree( start_path ) do
        if not mode then
            local mask = pattern:gsub('%%%*','.+'):gsub('%%%?','.')..'$'
            if normalize(filename):find( mask ) then
                table.insert(all_files, filename)
            end
        end
    end
    return all_files
end

function dir.dirtree( d )
    local exists, isdir = dir.exists, dir.isDir
    local sep = "/"

    local last = sub ( d, -1 )
    if last == sep or last == '/' then
        d = sub( d, 1, -2 )
    end

    local function yieldtree( dir_path )
        for entry in ldir( dir_path ) do
            if entry ~= "." and entry ~= ".." then
                entry = dir_path .. sep .. entry
                if exists(entry) then  
                    local is_dir = isdir(entry)
                    yield( entry, is_dir )
                    if is_dir then
                        yieldtree( entry )
                    end
                end
            end
        end
    end
    return wrap( function() yieldtree( d ) end )
end

return dir
