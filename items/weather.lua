local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local weather = sbar.add("item", "widgets.weather", {
  position = "right",
  icon = {
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
    string = "🌤",
    color = colors.blue,
  },
  label = { 
    font = { family = settings.font.text },
    string = "Loading...",
  },
  update_freq = 1800, -- Update every 30 minutes
  script = "$CONFIG_DIR/plugins/weather.sh",
})

local moon = sbar.add("item", "widgets.weather.moon", {
  position = "right",
  icon = {
    font = {
      style = settings.font.style_map["Regular"], 
      size = 14.0,
    },
    string = "🌙",
    color = colors.yellow,
  },
  label = { drawing = false },
})

sbar.add("bracket", "widgets.weather.bracket", { weather.name, moon.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.weather.padding", {
  position = "right",
  width = settings.group_paddings
})