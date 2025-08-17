local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_brackets = {} -- Store bracket references
local workspace_names = {"1", "2", "3", "4", "5"}

for i, workspace_name in ipairs(workspace_names) do
  local space = sbar.add("item", "space." .. workspace_name, {
    icon = {
      font = { family = settings.font.numbers },
      string = workspace_name,
      padding_left = 15,
      padding_right = 8,
      color = colors.white,
      highlight_color = colors.red,
    },
    label = {
      padding_right = 20,
      color = colors.grey,
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:16.0",
      y_offset = -1,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.bg1,
      border_width = 1,
      height = 26,
      border_color = colors.black,
    },
    popup = { background = { border_width = 5, border_color = colors.black } }
  })

  spaces[workspace_name] = space

  -- Single item bracket for space items to achieve double border on highlight
  local space_bracket = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
      border_width = 2
    }
  })
  
  -- Store bracket reference for later updates
  space_brackets[workspace_name] = space_bracket

  -- Padding space
  sbar.add("item", "space.padding." .. workspace_name, {
    script = "",
    width = settings.group_paddings,
  })

  local space_popup = sbar.add("item", {
    position = "popup." .. space.name,
    padding_left= 5,
    padding_right= 0,
    background = {
      drawing = true,
      image = {
        corner_radius = 9,
        scale = 0.2
      }
    }
  })

  -- Remove native space_change subscription since we're using AeroSpace
  -- Updates will be handled by periodic refresh

  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "other" then
      space_popup:set({ background = { image = "space." .. env.SID } })
      space:set({ popup = { drawing = "toggle" } })
    else
      if env.BUTTON == "left" then
        sbar.exec("aerospace workspace " .. workspace_name)
      end
    end
  end)

  space:subscribe("mouse.exited", function(_)
    space:set({ popup = { drawing = false } })
  end)
end

local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

-- Helper function to update workspace apps
local function update_workspace_apps(workspace_name)
  local space = spaces[workspace_name]
  if not space then return end
  
  -- Get windows for this workspace using format option
  sbar.exec("aerospace list-windows --workspace " .. workspace_name .. " --format '%{app-name}'", function(windows_result)
    local icon_line = ""
    local no_app = true
    local seen_apps = {}
    
    -- Parse each line as an app name
    for line in windows_result:gmatch("[^\n]+") do
      local app = line:match("^%s*(.-)%s*$") -- trim whitespace
      if app and app ~= "" and not seen_apps[app] then
        no_app = false
        seen_apps[app] = true
        local lookup = app_icons[app]
        local icon = ((lookup == nil) and app_icons["Default"] or lookup)
        icon_line = icon_line .. icon
      end
    end
    
    if no_app then
      icon_line = " —"
    end
    
    -- Update the label with app icons
    space:set({ label = icon_line })
  end)
end

-- Helper function to update workspace highlighting
local function update_workspace_highlighting(focused_workspace)
  for _, workspace_name in ipairs(workspace_names) do
    local space = spaces[workspace_name]
    local bracket = space_brackets[workspace_name]
    
    if space then
      local selected = (workspace_name == focused_workspace)
      
      -- Update visual state
      space:set({
        icon = { highlight = selected },
        label = { highlight = selected },
        background = { border_color = selected and colors.black or colors.bg2 }
      })
      
      -- Update bracket border
      if bracket then
        bracket:set({
          background = { border_color = selected and colors.grey or colors.bg2 }
        })
      end
    end
  end
end

-- Initialize all workspace apps on startup
local function init_all_workspaces()
  for _, workspace_name in ipairs(workspace_names) do
    update_workspace_apps(workspace_name)
  end
  
  -- Get and set initial focused workspace
  sbar.exec("aerospace list-workspaces --focused", function(result)
    local focused = result:match("^%s*(.-)%s*$")
    if focused then
      update_workspace_highlighting(focused)
    end
  end)
end

local spaces_indicator = sbar.add("item", {
  padding_left = -3,
  padding_right = 0,
  icon = {
    padding_left = 8,
    padding_right = 9,
    color = colors.grey,
    string = icons.switch.on,
  },
  label = {
    width = 0,
    padding_left = 0,
    padding_right = 8,
    string = "Spaces",
    color = colors.bg1,
  },
  background = {
    color = colors.with_alpha(colors.grey, 0.0),
    border_color = colors.with_alpha(colors.bg1, 0.0),
  }
})

-- Subscribe to aerospace workspace change event
space_window_observer:subscribe("aerospace_workspace_change", function(env)
  local focused_workspace = env.FOCUSED
  if focused_workspace then
    -- Update highlighting immediately
    update_workspace_highlighting(focused_workspace)
    -- Update apps for the new workspace
    update_workspace_apps(focused_workspace)
    -- Update apps for the previous workspace if it exists
    if env.PREV then
      update_workspace_apps(env.PREV)
    end
  end
end)

-- Update on front app switch (app moved or changed)
space_window_observer:subscribe("front_app_switched", function(env)
  -- Get current focused workspace and update its apps
  sbar.exec("aerospace list-workspaces --focused", function(result)
    local focused = result:match("^%s*(.-)%s*$")
    if focused then
      update_workspace_apps(focused)
    end
  end)
end)

-- Periodic update for catching any missed changes
space_window_observer:subscribe("routine", function(env)
  -- Update all workspace apps periodically
  for _, workspace_name in ipairs(workspace_names) do
    update_workspace_apps(workspace_name)
  end
end)

-- Set update frequency for routine updates (less frequent now that we have events)
space_window_observer:set({ update_freq = 5 })

-- Initial setup
init_all_workspaces()

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set({
    icon = currently_on and icons.switch.off or icons.switch.on
  })
end)

spaces_indicator:subscribe("mouse.entered", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 1.0 },
        border_color = { alpha = 1.0 },
      },
      icon = { color = colors.bg1 },
      label = { width = "dynamic" }
    })
  end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 0.0 },
        border_color = { alpha = 0.0 },
      },
      icon = { color = colors.grey },
      label = { width = 0, }
    })
  end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)
