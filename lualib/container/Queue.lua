
-- modify this github
-- https://github.com/moteus/lua-spylog-installer/blob/a762a24452e24ad02cc4a7148b88848e3de45c03/win/deps/x86/5.1/lib/lluv/utils.lua

local List = require "container.List"

local Queue = Class("Queue")

function Queue:ctor()
  self.listObj = List.new()
end

function Queue:Reset()
    self.listObj:Reset()
    return self
end

function Queue:Push(v)
    self.listObj:PushBack(v)
    return self
end

function Queue:PushFront(v)
    self.listObj:PushFront(v)
    return self
end

function Queue:Pop()
    return self.listObj:PopFront()
end

function Queue:Pops(s)
    return self.listObj:PopFronts(s)
end

function Queue:Peek()
    return self.listObj:PeekFront()
end

function Queue:PeekBack()
    return self.listObj:PeekBack()
end

function Queue:Size()
    return self.listObj:Size()
end

function Queue:IsEmpty()
    return self.listObj:IsEmpty()
end

function Queue:Pack()
    return self.listObj:Pack()
end

function Queue:Unpack(vals)
    return self.listObj:Unpack(vals)
end

function Queue:Remove(pos)
    return self.listObj:Remove(pos)
end

function Queue:Find(fn, pos)
    return self.listObj:Find(fn, pos)
end

function Queue:Walk(fn)
    self.listObj:Walk(fn)
end

return Queue
