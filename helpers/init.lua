-- Add the sketchybar module to the package cpath
-- Try multiple possible locations for SbarLua
local sbarlua_paths = {
    "/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so",
    "/usr/local/share/sketchybar_lua/?.so",
    "/opt/homebrew/share/sketchybar_lua/?.so",
}

for _, path in ipairs(sbarlua_paths) do
    package.cpath = package.cpath .. ";" .. path
end

-- Check if binaries exist, if not, suggest running install.sh
local function check_binary(name)
    local binary_path = os.getenv("CONFIG_DIR") .. "/helpers/event_providers/" .. name .. "/bin/" .. name
    local file = io.open(binary_path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- List of required binaries
local required_binaries = {"cpu_load", "ram_load", "network_load"}
local missing_binaries = {}

for _, binary in ipairs(required_binaries) do
    if not check_binary(binary) then
        table.insert(missing_binaries, binary)
    end
end

if #missing_binaries > 0 then
    print("Warning: Missing C binaries: " .. table.concat(missing_binaries, ", "))
    print("Please run './install.sh' from the sketchybar config directory to compile them.")
    print("Some widgets may not function properly without these binaries.")
end
