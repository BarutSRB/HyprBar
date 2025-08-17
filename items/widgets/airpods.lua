local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local airpods = sbar.add("item", "widgets.airpods", {
  position = "right",
  icon = {
    font = {
      style = settings.font.style_map["Regular"],
      size = 19.0,
    }
  },
  label = { font = { family = settings.font.numbers } },
  update_freq = 30,
  popup = { align = "center" }
})

local battery_details = sbar.add("item", {
  position = "popup." .. airpods.name,
  label = {
    string = "Not connected",
    align = "center"
  },
})

airpods:subscribe({"routine", "system_woke"}, function()
  sbar.exec("$CONFIG_DIR/plugins/airpods.sh", function(result)
    if result == "" or result:match("^Not connected") then
      airpods:set({
        drawing = false
      })
      return
    end
    
    -- Parse the result: "icon|label|details"
    local icon, label, details = result:match("([^|]+)|([^|]+)|(.*)")
    if not icon then
      airpods:set({ drawing = false })
      return
    end
    
    -- Parse battery percentage for color
    local battery = tonumber(label:match("(%d+)"))
    local color = colors.green
    if battery and battery <= 20 then
      color = colors.red
    elseif battery and battery <= 40 then
      color = colors.orange
    elseif battery and battery <= 60 then
      color = colors.yellow
    end
    
    airpods:set({
      drawing = true,
      icon = {
        string = icon,
        color = color
      },
      label = { string = label },
    })
    
    -- Store details for popup
    airpods.details = details
  end)
end)

airpods:subscribe("mouse.clicked", function(env)
  local drawing = airpods:query().popup.drawing
  airpods:set( { popup = { drawing = "toggle" } })

  if drawing == "off" and airpods.details then
    battery_details:set( { label = airpods.details })
  end
end)

sbar.add("bracket", "widgets.airpods.bracket", { airpods.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.airpods.padding", {
  position = "right",
  width = settings.group_paddings
})