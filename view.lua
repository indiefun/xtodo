--
-- view.lua
--

local modname = ...
local P = {}
_G[modname] = P

local curs = require 'curses'
local protocol = require 'protocol'
local Obj = protocol.Obj

setfenv(1, P)

View = Obj:new {
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    parent = nil,
    subviews = nil,
}

function View:draw()
end

function View:layout_subviews()
end

function View:add_subview(view)
end

function View:remove_from_parent()
end


return P

