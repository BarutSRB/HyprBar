local icons = require("icons")
local colors = require("colors")

local whitelist = { ["Spotify"] = true,
                    ["Music"] = true    };

local media_cover = sbar.add("item", "media_cover", {
  position = "center",
  background = {
    color = colors.transparent,
  },
  label = { drawing = false },
  icon = { 
    drawing = false,
    background = {
      height = 30,
      corner_radius = 6,
    }
  },
  drawing = false,
  updates = true,
  popup = {
    align = "center",
    horizontal = true,
  }
})

-- Set the script after creation
media_cover:set({
  script = "$CONFIG_DIR/plugins/spotify_artwork.sh",
  click_script = "$CONFIG_DIR/plugins/media_click.sh",
  update_freq = 2
})

-- Subscribe to initial trigger events for auto-loading on startup
media_cover:subscribe({"routine", "forced", "system_woke"}, function()
  sbar.exec("$CONFIG_DIR/plugins/spotify_artwork.sh")
end)

local media_artist = sbar.add("item", "media_artist", {
  position = "center",
  drawing = false,
  padding_left = 3,
  padding_right = 0,
  width = 0,
  icon = { drawing = false },
  label = {
    width = 0,
    font = { size = 9 },
    color = colors.with_alpha(colors.white, 0.6),
    max_chars = 18,
    y_offset = 6,
  },
})

local media_title = sbar.add("item", "media_title", {
  position = "center",
  drawing = false,
  padding_left = 3,
  padding_right = 0,
  icon = { drawing = false },
  label = {
    font = { size = 11 },
    width = 0,
    max_chars = 16,
    y_offset = -5,
  },
})

sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.back },
  label = { drawing = false },
  click_script = "osascript -e 'tell application \"Spotify\" to previous track'",
})
sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.play_pause },
  label = { drawing = false },
  click_script = "osascript -e 'tell application \"Spotify\" to playpause'",
})
sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.forward },
  label = { drawing = false },
  click_script = "osascript -e 'tell application \"Spotify\" to next track'",
})

local interrupt = 0
local function animate_detail(detail)
  if (not detail) then interrupt = interrupt - 1 end
  if interrupt > 0 and (not detail) then return end

  sbar.animate("tanh", 30, function()
    media_artist:set({ label = { width = detail and "dynamic" or 0 } })
    media_title:set({ label = { width = detail and "dynamic" or 0 } })
  end)
end

-- Remove the media_change subscription since we're using script updates

media_cover:subscribe("mouse.entered", function(env)
  interrupt = interrupt + 1
  animate_detail(true)
end)

media_artist:subscribe("mouse.entered", function(env)
  interrupt = interrupt + 1
  animate_detail(true)
end)

media_title:subscribe("mouse.entered", function(env)
  interrupt = interrupt + 1
  animate_detail(true)
end)

media_title:subscribe("mouse.exited", function(env)
  animate_detail(false)
end)

media_artist:subscribe("mouse.exited", function(env)
  animate_detail(false)
end)
