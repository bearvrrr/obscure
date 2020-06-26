local setmetatable = setmetatable
local wibox = require("wibox")

local timer = require("obvious.lib.hooks").timer
local cpu_usage = require("obvious.cpu").cpu_usage
local gradient_graph = require("obscure.widget.gradient_graph")

module("obscure.cpu")


local function create(label)
    local label = label or "CPU"
    local data = {}
    data.max = 100
    data.get = function(obj)
        return cpu_usage(obj).perc
    end

    local widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        {
            text = "CPU",
            widget = wibox.widget.textbox
        },
        gradient_graph(data)
    }

    return widget
end

setmetatable(_M, { __call = function(_, ...) return create(...) end })
