--luacheck: ignore 142
function table.empty(t)
    return next(t) == nil
end

function table.keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.ivalues(t)
    local keys = table.keys(t)
    table.sort(keys)
    local values = {}
    for _, key in ipairs(keys) do
        values[#values + 1] = t[key]
    end
    return values
end

function table.weakReference(obj)
    return setmetatable({weakReference = obj}, { __mode = 'v', __call = function(self)
        return self.weakReference
    end})
end
