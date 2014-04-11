--
-- datasource.lua
--

local modname = ...
local P = {}
_G[modname] = P

local _G = _G
local io = io
local os = os
local string = string
local table = table

local protocol = require 'protocol'
local Json = require 'cjson'
local util = require 'cutil'
local Item = protocol.Item
local User = protocol.User

local ipairs = ipairs
local type = type
local print = print
local error = error

setfenv(1, P)

local data_dir_name = 'data'

do
    local cmd = string.format('if [ ! -d \"%s\" ]; then mkdir \"%s\"; fi;', data_dir_name, data_dir_name)
    os.execute(cmd)
end

local function file_path(name)
    if not name then return nil end
    return data_dir_name .. '/' .. name
end

local function open_file(name, mode)
    return io.open(file_path(name), mode)
end

-- util

local function exist_file(name)
    if not name then return false end

    local file = open_file(name, 'r')
    if file then
        io.close(file)
        return true
    else
        return false
    end
end


-- users internal logic

local users_file_name = 'users'

local function _read_users()
    local users
    if exist_file(users_file_name) then
        local file = open_file(users_file_name, 'r')
        local info = file:read('*a')
        io.close(file)
        users = Json.decode(info)
    else
        users = {}
    end
    return users
end

local function _save_users(users)
    users = users or {}
    local info = Json.encode(users)

    local file = open_file(users_file_name, 'w')
    file:write(info)
    file:close()
end

local function _get_user_in(username, users)
    local user, v
    for _, v in ipairs(users) do
        if v.username == username then
            user = User:new(v)
        end
    end
    return user
end

local function _get_user(username)
    local users = _read_users()
    return _get_user_in(username, users)
end


-- item internal logic

local function _read_item(key)
    if not key then return nil end

    local item = nil
    if exist_file(key) then
        local file = open_file(key, 'r')
        local info = file:read('*a')
        io.close(file)
        item = Json.decode(info)
    end
    return item
end

local function _save_item(item)
    if not item then return false end
    if not item.key then return false end

    local info = Json.encode(item)
    local file = open_file(item.key, 'w')
    file:write(info)
    file:close()

    return true
end


-- users public interface

function get_user(username, password)
    local user = _get_user(username)
    if not user then return nil end
    if user.password ~= password then return nil end
    return user
end

function new_user(username, password)
    local users = _read_users()
    local user = _get_user_in(username, users)
    if user then return nil end
    user = User:new()

    user.key = util.uuid()
    user.username = username
    user.password = password
    user.itemskey = util.uuid()

    local item = Item:new()
    item.key = user.itemskey
    item.title = user.username
    item.subitems = {}
    _save_item(item)

    table.insert(users, user)
    _save_users(users)
    return user
end


-- item

function get_item(key)

    return _read_item(key)
end

function set_item(item)
    
    return _save_item(item)
end

function new_item(title, parent)
    local item = Item:new()
    item.key = util.uuid()
    item.title = title
    item.subitems = {}
    item.parent = parent

    if not _save_item(item) then return nil end
    return item
end

function delete_item(item)
    if not item then return false end
    if not item.key then return false end
    if not exist_file(item.key) then return false end

    os.remove(item.key)
    return true
end

return P

