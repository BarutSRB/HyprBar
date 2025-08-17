-- SketchyBar User Configuration
-- This file contains user preferences for enabling/disabling features
-- Modify these settings to customize your bar configuration

local M = {}

-- Device type configuration
-- Set to "laptop" to enable battery widget and other laptop-specific features
-- Set to "desktop" for desktop-specific optimizations
M.device_type = "desktop"  -- "laptop" or "desktop"

-- Widget Enable/Disable Flags
M.widgets = {
  -- System Monitors
  cpu = true,           -- CPU usage graph
  ram = true,           -- RAM usage graph
  network = true,       -- Network upload/download speeds
  battery = false,      -- Battery status (auto-enabled for laptops)
  
  -- Audio & Media
  volume = true,        -- Volume controls with device switcher
  media = true,         -- Spotify/Apple Music controls with artwork
  airpods = true,       -- AirPods battery status
  
  -- Information
  weather = true,       -- Weather widget with moon phase
  calendar = true,      -- Date and time display
  
  -- System
  front_app = true,     -- Current application display
  spaces = true,        -- Workspace/Space indicators
  apple_menu = true,    -- Apple menu icon
  menus = true,         -- Custom menu system
}

-- Window Manager Configuration
M.window_manager = "aerospace"  -- "aerospace", "yabai", or "native"

-- Update Intervals (in seconds)
M.update_intervals = {
  cpu = 2.0,
  ram = 2.0,
  network = 2.0,
  battery = 180,        -- 3 minutes
  weather = 1800,       -- 30 minutes
  media = 2.0,
}

-- Network Interface
-- Change this if your network interface is different
M.network_interface = "en0"

-- Auto-detect laptop and enable battery
if M.device_type == "laptop" then
  M.widgets.battery = true
end

return M