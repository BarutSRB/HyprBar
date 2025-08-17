local config = require("config")

-- Load widgets based on configuration
if config.widgets.airpods then
  require("items.widgets.airpods")
end

if config.widgets.volume then
  require("items.widgets.volume")
end

if config.widgets.network then
  require("items.widgets.wifi")
end

if config.widgets.cpu then
  require("items.widgets.cpu")
end

if config.widgets.ram then
  require("items.widgets.ram")
end

if config.widgets.battery and config.device_type == "laptop" then
  require("items.widgets.battery")
end

if config.widgets.weather then
  require("items.weather")
end
