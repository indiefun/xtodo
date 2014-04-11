--
-- controller.lua
--

local modname = ...
local P = {}
_G[modname] = P

local _G = _G
local datasource = require 'datasource'
local protocol = require 'protocol'
local User = protocol.User
local Item = protocol.Item

local ipairs = ipairs
local table = table

setfenv(1, P)

function get_user(username, password)
    return datasource.get_user(username, password)
end

function new_user(username, password)
    return datasource.new_user(username, password)
end

function get_parent_item(user, key)
    local item = datasource.get_item(key)
    local parent = datasource.get_item(item.parent)
    return parent
end

function get_item(user, key)
    local item = datasource.get_item(key)
    return item
end

function save_item(user, item)
    return datasource.set_item(item)
end

function list_item(user, key)
    if not key then return {} end

    local item = datasource.get_item(key)
    if not item.subitems then return {} end

    local t = {}
    for _, v in ipairs(item.subitems) do
        local i = datasource.get_item(v)
        if i then table.insert(t, i) end
    end
    return t
end

function new_item(user, title, inkey)
    local super = datasource.get_item(inkey)
    if not super then return nil end
    
    local new = datasource.new_item(title, super.key)
    if not new then return nil end

    if not super.subitems then super.subitems = {} end
    table.insert(super.subitems, new.key)

    if not datasource.set_item(super) then datasource.delete_item(new) return nil end
    return new
end

local function _delete_item(key)
    local item = datasource.get_item(key)
    if not item then return true end
    
    local suc = true
    if item.subitems then
        for _, v in ipairs(item.subitems) do
            suc = _delete_item(v) and suc
        end
    end

    return datasource.delete_item(item) and suc
end

function delete_item(user, key)
    local item = datasource.get_item(key)
    if not item then return true end
    if not item.parent then return false end

    local suc = true

    local parent = datasource.get_item(item.parent)
    local idx
    for i, v in ipairs(parent.subitems) do
        if v == key then 
            idx = i 
            break
        end
    end
    if idx then 
        table.remove(parent.subitems, idx) 
        suc = datasource.set_item(parent) and suc
    end

    return _delete_item(item.key) and suc
end

return P

