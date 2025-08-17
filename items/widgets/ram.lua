local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local widget_utils = require("helpers.widget_utils")

-- Initialize the RAM event provider
widget_utils.init_event_provider("ram_load", "ram_update", 2.0)

-- Create the RAM graph widget
local ram = widget_utils.create_graph_widget("widgets.ram", icons.ram or "􀫦", "ram")

ram:subscribe("ram_update", function(env)
  -- env contains: used_percentage, used_gb, total_gb
  local usage = tonumber(env.used_percentage)
  ram:push({ usage / 100. })

  -- Use custom thresholds for RAM (different from CPU)
  local color = widget_utils.get_threshold_color(usage, {
    {50, colors.blue},
    {70, colors.yellow},
    {85, colors.orange},
    {100, colors.red}
  })

  ram:set({
    graph = { color = color },
    label = "ram " .. env.used_percentage .. "%",
  })
end)

ram:subscribe("mouse.clicked", function(env)
  sbar.exec("open -a 'Activity Monitor'")
end)

-- Add bracket and padding using helper
widget_utils.add_bracketed_widget("widgets.ram", { ram.name })