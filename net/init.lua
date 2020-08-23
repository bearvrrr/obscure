local setmetatable = setmetatable
local tostring = tostring
local string = string
local table = table
local math = math
local io = io
local pairs = pairs

local wibox = require("wibox")
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")

local get_net_data = require("obvious.net").get_data
local timer = require("obvious.lib.hooks").timer

local function round(num)
    return math.floor(num + 0.5)
end

local function modulo(x, y)
    local res = x/y
    return round((res - math.floor(res)) * y)
end

local function sig_fig(num, figures)
    local figures = figures or 1
    if num == 0 or figures < 1 then
        return 0.0
    end
    local x = math.floor(figures) - math.ceil(math.log(math.abs(num), 10))
    return (math.floor(num*10^x+0.5)/10^x)
end

local function human(num)
    local num = num
    local postfixes = { "", "K", "M", "G" }
    local postfix = ""
    for i = 1, #postfixes do
        postfix = postfixes[i]
        if num < 1000 then
            break
        end
        num = num / 1000
    end
    local rounded = tostring(sig_fig(num, 3))
    if string.sub(rounded, -2) == ".0" then
        rounded = string.sub(rounded, 1, -3)
    end
    return rounded .. postfix
end

local function device_text(name, send_rate, recv_rate)
    return name .. " ▲" .. human(send_rate) .. "/s ▼" .. human(recv_rate) .. "/s"
end

function create(label, show_first)
    -- label is used as the name for the display of the total throughput on all
    -- interfaces
    local label = label or "net"
    local sources = {} -- holds data and textboxes

    -- First item in the sequence is the total
    sources[1] = { 
        data = { device = label },
        widget = wibox.widget.textbox(label .. " --")
    }

    local net_dev = io.open("/proc/net/dev", "r")
    for line in net_dev:lines() do
        name = line:match("^%s*(%w+):")
        if name then
            table.insert(sources, {
                data = { device = name },
                widget = wibox.widget.textbox(name .. " --")
            })
        end
    end
    net_dev:close()
    
    -- background container to do themeing stuff and used to set display widget
    local theme = beautiful.get()
    local widget = wibox.container.background()
    widget.fg = theme.graph_fg_color or theme.widget_fg_color or theme.fg_normal
    widget.bg = theme.graph_bg_color or theme.widget_bg_color or theme.bg_normal

    widget.sources = sources

    widget.set_source = function(widget, index)
        if index > 0 and index <= #widget.sources then
            widget.widget = widget.sources[index].widget
            widget.source_index = index
        end
    end

    if show_first then
        for k, v in pairs(sources) do
            if show_first == v.data.device then
                widget:set_source(k)
                break
            end
        end
    end
    if not widget.source_index then widget:set_source(1) end

    widget.update = function(widget)
        local sources = widget.sources
        local total_rate = { send = 0, recv = 0 }

        for i = 2 , #sources do -- first item is not a real interface
            local cur = sources[i]
            local stats = get_net_data(cur.data)
            
            if stats.period == 0 then
                -- too short a time period, don't update widget and flag
                -- total_rate not to update
                total_rate = nil
            else
                local send_rate = stats.send/stats.period
                local recv_rate = stats.recv/stats.period
                if total_rate then
                    total_rate.send = total_rate.send + send_rate
                    total_rate.recv = total_rate.recv + recv_rate
                end
                cur.widget.text = device_text(cur.data.device, send_rate, recv_rate)
            end
        end
        if total_rate then
            widget.sources[1].widget.text = device_text(
                widget.sources[1].data.device, total_rate.send, total_rate.recv)
        end
    end

    widget.cycle = function(widget, vector)
        local vector = vector or 1
        widget:set_source(
            modulo(
                widget.source_index - 1 + vector, -- -1 to convert to 0-index
                #widget.sources
            ) + 1) -- +1 to get back to 1-index
    end

    -- Buttons
    widget:buttons(gears.table.join(
        awful.button({}, 1, function() widget:cycle(1) end),
        awful.button({}, 3, function() widget:cycle(-1) end)
    ))

    -- Timer stuff
    function update()
        widget:update()
    end
    timer.register(10, 60, update)
    timer.start(update)
    update()

    return widget
end

return setmetatable({}, { __call = function(_, ...) return create(...) end })
