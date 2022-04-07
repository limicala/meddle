
-- modify this github
-- https://github.com/moteus/lua-spylog-installer/blob/a762a24452e24ad02cc4a7148b88848e3de45c03/win/deps/x86/5.1/lib/lluv/utils.lua

local List = Class("List")

function List:ctor()
  self:Reset()
end

function List:Reset()
    self.first = 0
    self.last  = -1
    self.t     = {}
    return self
end

function List:PushFront(v)
    assert(v ~= nil)
    local first = self.first - 1
    self.first, self.t[first] = first, v
    return self
end

function List:PushBack(v)
    assert(v ~= nil)
    local last = self.last + 1
    self.last, self.t[last] = last, v
    return self
end

function List:PeekFront()
    return self.t[self.first]
end

function List:PeekBack()
    return self.t[self.last]
end

function List:PopFront()
    local first = self.first
    if first > self.last then 
        return
    end

    local value = self.t[first]
    self.first, self.t[first] = first + 1, nil
    return value
end

function List:PopFronts(s)
    s = math.min(self.last - self.first + 1, s)
    if s <= 0 then
        return
    end
    local t, value, first = {}, nil, nil
    for _ = 1, s do
        value, first = self.t[self.first], self.first
        self.first, self.t[first] = first + 1, nil
        table.insert(t, value)
    end
    return t
end

function List:PopBack()
    local last = self.last
    if self.first > last then
        return
    end
    local value = self.t[last]
    self.last, self.t[last] = last - 1, nil
    return value
end

function List:Size()
    return self.last - self.first + 1
end

function List:IsEmpty()
    return self.first > self.last
end

function List:Find(fn, pos)
    pos = pos or 1
    if type(fn) == "function" then
        for i = self.first + pos - 1, self.last do
            local n = i - self.first + 1
            if fn(self.t[i]) then
                return n, self.t[i]
            end
        end
    else
        for i = self.first + pos - 1, self.last do
            local n = i - self.first + 1
            if fn == self.t[i] then
                return n, self.t[i]
            end
        end
    end
end

function List:Walk(fn)
    assert(type(fn) == "function")
    for i = self.first, self.last do
        local n = i - self.first + 1
        fn(n, self.t[i])
    end
end

function List:Remove(pos)
    local s = self:size()
    if pos < 0 then
        pos = s + pos + 1
    end
    if pos <= 0 or pos > s then
        return
    end
    local offset = self.first + pos - 1
    local v = self.t[offset]
    if pos < s / 2 then
        for i = offset, self.first, -1 do
            self.t[i] = self.t[i-1]
        end
        self.first = self.first + 1
    else
        for i = offset, self.last do
            self.t[i] = self.t[i+1]
        end
        self.last = self.last - 1
    end
    return v
end

function List:Insert(pos, v)
    assert(v ~= nil)
    local s = self:size()
    if pos < 0 then pos = s + pos + 1 end
    if pos <= 0 or pos > (s + 1) then return end
    local offset = self.first + pos - 1
    if pos < s / 2 then
        for i = self.first, offset do
            self.t[i-1] = self.t[i]
        end
        self.t[offset - 1] = v
        self.first = self.first - 1
    else
        for i = self.last, offset, - 1 do
            self.t[i + 1] = self.t[i]
        end
        self.t[offset] = v
        self.last = self.last + 1
    end
    return self
end

function List:Pack()
    return table.ivalues(self.t)
end

function List:Unpack(vals)
    self.first = 1
    self.last  = #vals
    self.t     = vals
end

return List
