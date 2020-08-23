local setmetatable = setmetatable
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local timer = require("obvious.lib.hooks").timer

local function create(data)
    local theme  = beautiful.get()
    local fg     = theme.graph_fg_color or theme.widget_fg_color or theme.fg_normal
    local bg     = theme.graph_bg_color or theme.widget_bg_color or theme.bg_normal
    local border = theme.graph_border or theme.widget_border or theme.border_normal
    local width  = theme.graph_width or theme.widget_width

    -- Lighter colour represents more recently added values
    local gradient = gears.color({
        type = "linear",
        from = { 0, 0 },
        to = { beautiful.graph_width, 0 },
        stops = { { 0, fg }, { 1, bg } }
    })

    local graph_widget = wibox.widget.graph()
    graph_widget.color = gradient
    graph_widget.background_color = bg
    graph_widget.border_color = border
    if width then graph_widget.width = width end
    if data.max then
        graph_widget.scale = false
    else
        graph_widget.scale = true
    end

    graph_widget.data = data

    -- New values to be displayed added to the right
    local widget = wibox.widget {
        graph_widget,
        reflection = { horizontal = true },
        widget = wibox.container.mirror
    }

    local function update()
        local max = graph_widget.data.max or 1
        local val = graph_widget.data:get() or max
        graph_widget:add_value(val / max)
    end

    -- Add timer and update
    timer.register(10, 60, update)
    timer.start(update)
    update()
    return widget
end

return setmetatable({}, { __call = function(_, ...) return create(...) end })
