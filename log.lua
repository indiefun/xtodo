--
-- log.lua
--

local modname = ...
local P = {}
_G[modname] = P

local io = io
local string = string

setfenv(1, P)

local out = io.stderr

function log(...)
    out:write(...)
    out:write('\n')
end

function logf(f, ...)
    log(string.format(f, ...))
end

return P

