--
-- protocol.lua
-- 

local modname = ...
local P = {}
_G[modname] = P

local _G = _G
local setmetatable = setmetatable

setfenv(1, P)


-- Obj
Obj = {
    key = nil,
}

function Obj:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


-- Item
Item = Obj:new {
    title = '',
    subitems = nil,
    parent = nil,
}

-- User
User = Obj:new {
    username = '',
    password = '',
    itemskey = '',
}


-- Array2D protocol

Array2D = Obj:new {}

function Array2D:set(x, y, v)
    local _x = self[x] or {}
    _x[y] = v
    self[x] = _x
end

function Array2D:get(x, y)
    local _x = self[x]
    if not _x then return nil end
    return _x[y]
end


return P

