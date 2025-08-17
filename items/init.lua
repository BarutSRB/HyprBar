local config = require("config")

-- Load items based on configuration
if config.widgets.apple_menu then
  require("items.apple")
end

if config.widgets.menus then
  require("items.menus")
end

if config.widgets.spaces then
  require("items.spaces")
end

if config.widgets.front_app then
  require("items.front_app")
end

if config.widgets.calendar then
  require("items.calendar")
end

-- Load widget collection
require("items.widgets")

if config.widgets.media then
  require("items.media")
end
