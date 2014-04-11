#!/usr/bin/env lua

local curs = require 'curses'
local controller = require 'controller'
local util = require 'cutil'

-- Limit
local LMT_LEN_USERNAME = 20
local LMT_LEN_PASSWORD = 20


-- View
local RW = 0            -- root window's width
local RH = 0            -- root window's height
local BW = 1            -- border width
local HM, VM = 4, 1     -- horizontal and vertical margin



local function _show_choice_dialog(title, message, choices)
    title = title or ''
    message = message or ''
    choices = choices or {}

    local lt = string.len(title)        -- length of title
    local lm = string.len(message)      -- length of message
    local cc = #choices                 -- count of choices

    local ht = (lt == 0 and 0 or 1)     -- height of title
    local hm = (lm == 0 and 0 or 1)     -- height of message
    local hc = (cc == 0 and 0 or 1)     -- height of choices

    local cw = (cc - 1) * HM            -- width of all choices layout in horizontal
    local lc = {}                       -- length of each choice
    for i, v in ipairs(choices) do 
        lc[i] = string.len(v) 
        cw = cw + lc[i]
    end    

    local dx, dy, dw, dh
    dw = math.max(lt, lm, cw) + HM * 2 + BW * 2
    dh = BW * 2 + ht + hm + hc + VM * ((lm == 0 and 0 or 1) + (cc == 0 and 0 or 1))
    dx = (RW - dw) / 2
    dy = (RH - dh) / 2

    local d = curs.newwin(dh, dw, dy, dx)
    
    local hidx = 1
    local _refresh = function ()
        local yo = 1    -- y offset
        if lt ~= 0 then
            d:mvaddstr(yo, (dw - lt - BW * 2) / 2, title)
            yo = yo + 1
        end
        if lm ~= 0 then
            yo = yo + VM
            d:mvaddstr(yo, (dw - lm - BW * 2) / 2, message)
            yo = yo + 1
        end
        if cc ~= 0 then
            yo = yo + VM
            local xo = (dw - cw - BW * 2) / 2  -- x offset
            for i, v in ipairs(choices) do
                if hidx == i then
                    d:attron(curs.A_REVERSE)
                    d:mvaddstr(yo, xo, v)
                    d:attroff(curs.A_REVERSE)
                else
                    d:mvaddstr(yo, xo, v)
                end
                xo = xo + lc[i] + HM
            end
            yo = yo + 1
        end
        d:box(0, 0)
        d:refresh()
    end

    _refresh()
    d:keypad(true)

    local choice = 0
    while true do
        local c = d:getch()
        if c == curs.KEY_LEFT then
            if hidx == 1 then
                hidx = cc
            else
                hidx = hidx - 1
            end
        elseif c == curs.KEY_RIGHT then
            if hidx == cc then
                hidx = 1
            else
                hidx = hidx + 1
            end
        elseif c == 13 then
            choice = hidx
        end

        _refresh()
        if choice ~= 0 then break end
    end

    d:close()

    local rw = curs.stdscr()
    rw:touch()
    rw:refresh()

    return choice
end

local function _show_user_dialog(title, message)
    title = title or ''
    message = message or ''
    local namelabel = 'Username:'
    local passlabel = 'Password:'
    local inputname = ''
    local inputpass = ''
    local inputholder = string.rep(' ', 8)

    -- length
    local lt = string.len(title)        -- title
    local lm = string.len(message)      -- message
    local ln = string.len(namelabel)    -- name label
    local lp = string.len(passlabel)    -- pass label
    local li = string.len(inputholder)  -- input placeholder

    -- height
    local ht = (lt == 0 and 0 or 1)     -- title
    local hm = (lm == 0 and 0 or 1)     -- message

    -- dialog
    local dx, dy, dw, dh
    dw = math.max(lt, lm, (ln + li + HM), (lp + li + HM)) + HM * 2 + BW * 2
    dh = ht + (lm == 0 and 0 or (VM + hm)) + VM + 1 + 1 + BW * 2
    dx = (RW - dw) / 2
    dy = (RH - dh) / 2

    -- input field point recording
    local rinx, riny, ripx, ripy = 1, 1, 1, 1   -- record input [name|pass] [x|y]

    local d = curs.newwin(dh, dw, dy, dx)

    local _refresh = function ()
        local yo = 1    -- y offset

        if lt ~= 0 then
            d:mvaddstr(yo, (dw - lt) / 2 - BW, title)
            yo = yo + 1
        end
        if lm ~= 0 then
            yo = yo + VM
            d:mvaddstr(yo, (dw - lm) / 2 - BW, message)
            yo = yo + 1
        end

        -- user label
        local lin = #inputname
        local displayname = (lin < li and inputname or string.sub(inputname, -li))

        yo = yo + VM
        d:mvaddstr(yo, (dw - HM) / 2 - ln, namelabel)
        d:attron(curs.A_UNDERLINE)
        riny, rinx = yo, ((dw + HM) / 2)
        d:mvaddstr(riny, rinx, inputholder)
        d:mvaddstr(riny, rinx, displayname)
        d:attroff(curs.A_UNDERLINE)
        yo = yo + 1

        -- pass label
        local lip = #inputpass
        local displaypass = (lip < li and inputpass or string.sub(inputpass, -li))
        displaypass = string.rep('*', #displaypass)

        d:mvaddstr(yo, (dw - HM) / 2 - lp, passlabel)
        d:attron(curs.A_UNDERLINE)
        ripy, ripx = yo, ((dw + HM) / 2)
        d:mvaddstr(ripy, ripx, inputholder)
        d:mvaddstr(ripy, ripx, displaypass)
        d:attroff(curs.A_UNDERLINE)
        yo = yo + 1


        d:box(0, 0)
        d:refresh()
    end

    local cs = curs.curs_set(2)

    _refresh()
    local name_inputting = true
    while true do
        local cx = (name_inputting and rinx or ripx)
        local cy = (name_inputting and riny or ripy)
        local xo = (name_inputting and math.min(#inputname, li) or math.min(#inputpass, li))
        local c = d:mvgetch(cy, cx + xo)
        if c == 9 then          -- TAB : switch to next
            name_inputting = not name_inputting
        elseif c == 127 then    -- BACKSPACE : delete last char
            local sub = string.sub((name_inputting and inputname or inputpass) or '', 1, -2)
            if name_inputting then inputname = sub else inputpass = sub end
        elseif c == 13 then     -- ENTER
            local lin, lip = #inputname, #inputpass
            if lin > 0 and lip > 0 then break end
            name_inputting = (lin == 0 and true or false)
        else                    -- input
            local str = string.format('%s%c', ((name_inputting and inputname or inputpass) or ''), c)
            if name_inputting then inputname = str else inputpass = str end
        end
        _refresh()
    end

    d:close()

    curs.curs_set(cs)

    local rw = curs.stdscr()
    rw:touch()
    rw:refresh()

    return inputname, inputpass
end

local function show_welcome_dialog()
    local title = 'Welcome'
    local message = 'Login with exist account, or Register new account'
    local choices = {
        '[Login]',
        '[Register]',
        '[Exit]',
    }
    return _show_choice_dialog(title, message, choices)
end

local function show_login_dialog()
    local title = 'Login'
    local message = '[TAB] to switch, [ENTER] to finished'
    return _show_user_dialog(title, message)
end

local function show_register_dialog()
    local title = 'Register'
    local message = '[TAB] to switch, [ENTER] to finished'
    return _show_user_dialog(title, message)
end

local function show_alert_dialog()
    local title = 'Alert'
    local message = 'Username not exist or Password wrong'
    _show_choice_dialog(title, message, nil)
end

local function show_items(win, items, selindex)
    win:clear()
    if items then
        local h, w = win:getmaxyx()
        for i, v in ipairs(items) do
            if selindex == i then
                win:attron(curs.A_REVERSE)
                win:mvaddstr(i, 1, v.title, w)
                win:attroff(curs.A_REVERSE)
            else
                win:mvaddstr(i, 1, v.title, w)
            end
        end
    end
    win:box(0, 0)
    win:refresh()
end

local function _show_input_dialog(title, input)
    title = title or ''
    input = input or ''

    local holder = string.rep(' ', RW / 3)

    -- length
    local lt = string.len(title)        -- title
    local lh = string.len(holder)       -- holder

    -- height
    local ht = (lt == 0 and 0 or 1)     -- title
    local hh = (lh == 0 and 0 or 1)     -- holder

    -- dialog
    local dx, dy, dw, dh
    dw = math.max(lt, lh) + HM * 2 + BW * 2
    dh = ht + VM + hh + BW * 2
    dx = (RW - dw) / 2
    dy = (RH - dh) / 2

    local d = curs.newwin(dh, dw, dy, dx)

    local ix, iy = 0, 0

    local _refresh = function ()
        local yo = 1    -- y offset

        if lt ~= 0 then
            d:mvaddstr(yo, (dw - lt) / 2 - BW, title)
            yo = yo + 1
        end

        local li = #input
        local dis = (li < lh and input or string.sub(input, -lh))

        yo = yo + VM
        iy, ix = yo, ((dw - lh) / 2 - BW)
        d:attron(curs.A_UNDERLINE)
        d:mvaddstr(iy, ix, holder)
        d:mvaddstr(iy, ix, dis)
        d:attroff(curs.A_UNDERLINE)
        yo = yo + 1

        d:box(0, 0)
        d:refresh()
    end

    local cs = curs.curs_set(2)

    _refresh()

    while true do
        local cx, cy = ix, iy
        local xo = math.min(#input, lh)
        local c = d:mvgetch(cy, cx + xo)

        if c == 127 then        -- BACKSPACE : delete last char
            input = string.sub(input, 1, -2)
        elseif c == 13 then     -- ENTER
            break;
        else                    -- input
            input = string.format('%s%c', input, c)
        end

        _refresh()
    end

    d:close()

    curs.curs_set(cs)

    local rw = curs.stdscr()
    rw:touch()
    rw:refresh()

    return input
end

local function init_xtodo(user)
    local rw = curs.stdscr()
    local pw, cw, sw            -- parent, current, sub window
    local pi, ci, si            -- parent, current, sub item
    local pis, cis, sis         -- parent, current, sub items
    local psi, csi              -- parent, current select index

    psi, csi = 0, 1
    ci = controller.get_item(user, user.itemskey)
    cis = controller.list_item(user, ci.key)
    si = cis[csi]
    sis = (si and controller.list_item(user, si.key) or {})

    local pwh, pww, pwy, pwx = RH, RW / 4, 0, 0
    local cwh, cww, cwy, cwx = RH, RW / 2, 0, RW / 4
    local swh, sww, swy, swx = RH, RW / 4, 0, RW * 3 / 4

    pw = curs.newwin(pwh, pww, pwy, pwx)
    cw = curs.newwin(cwh, cww, cwy, cwx)
    sw = curs.newwin(swh, sww, swy, swx)

    rw:keypad(true)
    while true do
        show_items(pw, pis, psi)
        show_items(cw, cis, csi)
        show_items(sw, sis, nil)

        local c = rw:getch()
        if     c == 104 or c == curs.KEY_LEFT  then    -- h | left
            if pi then
                si = ci
                sis = cis
                ci = pi
                cis = pis
                csi = psi
                pi = controller.get_item(user, pi.parent)
                pis = (pi and controller.list_item(user, pi.key) or {})
                for i, v in ipairs(pis) do
                    if v.key == ci.key then
                        psi = i
                        break
                    end
                end
            end
        elseif c == 106 or c == curs.KEY_DOWN  then    -- j | down
            csi = ((csi + 1) > #cis and 1 or (csi + 1))
            si = cis[csi]
            sis = (si and controller.list_item(user, si.key) or {})
        elseif c == 107 or c == curs.KEY_UP    then    -- k | up
            csi = ((csi - 1) < 1 and #cis or (csi - 1))
            si = cis[csi]
            sis = (si and controller.list_item(user, si.key) or {})
        elseif c == 108 or c == curs.KEY_RIGHT then    -- l | right
            if si then
                pi = ci
                pis = cis
                psi = csi
                ci = si
                cis = sis
                csi = 1
                si = cis[csi]
                sis = (si and controller.list_item(user, si.key) or {})
            end
        elseif c == 110 then    -- n : new item
            local input = _show_input_dialog('Input Title')
            if #input > 0 then
                local inkey = ci.key
                local item = controller.new_item(user, input, inkey)
                cis = controller.list_item(user, ci.key)
                si = cis[csi]
                sis = (si and controller.list_item(user, si.key) or {})
            end
        elseif c == 100 then    -- d : delete item
            local item = cis[csi]
            local suc = controller.delete_item(user, item.key)
            cis = controller.list_item(user, ci.key)
            csi = math.min(csi, #cis)
            si = cis[csi]
            sis = (si and controller.list_item(user, si.key) or {})
        elseif c == 13  then    -- ENTER : edit item
            local item = cis[csi]
            local input = _show_input_dialog('Edit Title', item.title)
            if #input == 0 then
                controller.delete_item(user, item.key)
            else
                item.title = input
                controller.save_item(user, item)
            end
            cis = controller.list_item(user, ci.key)
        elseif c == 113 then    -- q : quit
            break
        end

        rw:refresh()
    end

    pw:close()
    cw:close()
    sw:close()

    rw:touch()
    rw:refresh()
end

local function main()

    curs.initscr()
    curs.cbreak()
    curs.echo(false)  -- not noecho !
    curs.nl(false)    -- not nonl !
    curs.curs_set(0)  -- set curs invisible

    -- root window
    local rw   = curs.stdscr()
    rw:clear()

    RW = curs.cols()
    RH = curs.lines()

    while true do
        local choice = show_welcome_dialog()
        local user = nil

        if choice == 3 then
            break
        elseif choice == 2 then
            local name, pass = show_register_dialog()
            user = controller.new_user(name, pass)
        else
            local name, pass = show_login_dialog()
            user = controller.get_user(name, pass)
        end

        if user then
            init_xtodo(user)
        else
            show_alert_dialog()
        end
    end

    rw:clrtoeol()
    rw:refresh()
    rw:close()

    curs.endwin()
end

main()

