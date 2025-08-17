local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local widget_utils = require("helpers.widget_utils")

-- Initialize the CPU event provider
widget_utils.init_event_provider("cpu_load", "cpu_update", 2.0)

-- Create the CPU graph widget
local cpu = widget_utils.create_graph_widget("widgets.cpu", icons.cpu, "cpu")

cpu:subscribe("cpu_update", function(env)
  -- Also available: env.user_load, env.sys_load
  local load = tonumber(env.total_load)
  cpu:push({ load / 100. })

  local color = widget_utils.get_threshold_color(load)
  
  cpu:set({
    graph = { color = color },
    label = "cpu " .. env.total_load .. "%",
  })
end)

cpu:subscribe("mouse.clicked", function(env)
  sbar.exec("open -a 'Activity Monitor'")
end)

-- Add bracket and padding using helper
widget_utils.add_bracketed_widget("widgets.cpu", { cpu.name })
