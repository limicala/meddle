--luacheck: ignore
local type          = type

STANDARD_CLASS_DEF  = STANDARD_CLASS_DEF  or {}
STANDARD_MODULE_DEF = STANDARD_MODULE_DEF or {}
STANDARD_DEFINE_DEF = STANDARD_DEFINE_DEF or {}

function Class(className, super)
    if STANDARD_CLASS_DEF[className] ~= nil then
        return STANDARD_CLASS_DEF[className]
    end

    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        super = nil
    end

    if super then
        cls = {}
        setmetatable(cls, {__index = super})
        cls.super = super
    else
        cls = {ctor = function() end}
    end

    cls.__cname = className
    cls.__index = cls

    function cls.new(...)
        local instance = {}
        setmetatable(instance, cls)
        instance.Class = cls
        instance:ctor(...)

        return instance
    end
    STANDARD_CLASS_DEF[className] = cls
    return cls
end

function Module(moduleName)
    if type(moduleName) ~= "string" then
        return
    end
    if STANDARD_MODULE_DEF[moduleName] == nil then
        STANDARD_MODULE_DEF[moduleName] = {}
    end
    return STANDARD_MODULE_DEF[moduleName]
end

function Define(defineName)
    if type(defineName) ~= "string" then
        return
    end
    if STANDARD_DEFINE_DEF[defineName] == nil then
        STANDARD_DEFINE_DEF[defineName] = {}
    end
    return STANDARD_DEFINE_DEF[defineName]
end
