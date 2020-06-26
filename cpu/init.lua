local setmetatable = setmetatable
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

module("obscure.cpu")

local function create(_)

    local gradient = gears.color({
        type = "linear",
        from = { 0, 0 },
        to = { beautiful.graph_width, 0 },
        stops = { { 0, beautiful.bg_normal }, { 1, beautiful.fg_focus } },
    })

    local widget = wibox.widget {
        {
            text = "hello",
            widget = wibox.widget.textbox
        },
        bg = gradient,
        forced_width = beautiful.graph_width,
        widget = wibox.container.background
    }

    return widget
end

setmetatable(_M, { __call = create })
