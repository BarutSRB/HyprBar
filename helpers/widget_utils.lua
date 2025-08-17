local colors = require("colors")
local settings = require("settings")

local M = {}

-- Helper function to add a widget with bracket and padding
-- @param name: widget name (e.g., "widgets.cpu")
-- @param items: table of item names to bracket together
-- @param options: optional table with bracket_color override
function M.add_bracketed_widget(name, items, options)
  options = options or {}
  local bracket_color = options.bracket_color or colors.bg1
  
  -- Add the bracket
  sbar.add("bracket", name .. ".bracket", items, {
    background = { color = bracket_color }
  })
  
  -- Add padding
  sbar.add("item", name .. ".padding", {
    position = "right",
    width = settings.group_paddings
  })
end

-- Helper function to initialize C event providers
-- @param provider_name: name of the provider binary (e.g., "cpu_load")
-- @param event_name: name of the event to trigger (e.g., "cpu_update")
-- @param interval: update interval in seconds
-- @param extra_args: optional extra arguments (e.g., network interface)
function M.init_event_provider(provider_name, event_name, interval, extra_args)
  interval = interval or 2.0
  extra_args = extra_args or ""
  
  local cmd
  if extra_args ~= "" then
    -- For network_load which needs interface before event name
    cmd = string.format(
      "killall %s >/dev/null; $CONFIG_DIR/helpers/event_providers/%s/bin/%s %s %s %.1f",
      provider_name, provider_name, provider_name, extra_args, event_name, interval
    )
  else
    cmd = string.format(
      "killall %s >/dev/null; $CONFIG_DIR/helpers/event_providers/%s/bin/%s %s %.1f",
      provider_name, provider_name, provider_name, event_name, interval
    )
  end
  
  sbar.exec(cmd)
end

-- Helper function to get color based on threshold values
-- @param value: current value to check
-- @param thresholds: table of {threshold, color} pairs in ascending order
-- @return: color for the current value
function M.get_threshold_color(value, thresholds)
  thresholds = thresholds or {
    {30, colors.blue},
    {60, colors.yellow},
    {80, colors.orange},
    {100, colors.red}
  }
  
  for _, threshold in ipairs(thresholds) do
    if value <= threshold[1] then
      return threshold[2]
    end
  end
  
  return thresholds[#thresholds][2] -- Return highest threshold color
end

-- Helper function to create a graph widget with standard settings
-- @param name: widget name
-- @param icon: icon string
-- @param label_prefix: prefix for the label (e.g., "cpu", "ram")
function M.create_graph_widget(name, icon, label_prefix)
  return sbar.add("graph", name, 42, {
    position = "right",
    graph = { color = colors.blue },
    background = {
      height = 22,
      color = { alpha = 0 },
      border_color = { alpha = 0 },
      drawing = true,
    },
    icon = { string = icon },
    label = {
      string = label_prefix .. " ??%",
      font = {
        family = settings.font.numbers,
        style = settings.font.style_map["Bold"],
        size = 9.0,
      },
      align = "right",
      padding_right = 0,
      width = 0,
      y_offset = 4
    },
    padding_right = settings.paddings + 6
  })
end

return M