--luacheck: ignore 142
function table.empty(t)
    return next(t) == nil
end
