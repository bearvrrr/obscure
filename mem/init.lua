local setmetatable = setmetatable
local wibox = require("wibox")

local timer = require("obvious.lib.hooks").timer
local mem_usage = require("obvious.mem").mem_usage
local gradient_graph = require("obscure.widget.gradient_graph")

module("obscure.mem")


local function create(label, field)
    local label = label or "MEM"
    local field = field or "perc"

    local data = {}
    data.max = 100
    data.get = function()
        local result = mem_usage()
        return result[field]
    end

    local widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        {
            text = label,
            widget = wibox.widget.textbox
        },
        gradient_graph(data)
    }

    return widget
end

setmetatable(_M, { __call = function(_, ...) return create(...) end })
