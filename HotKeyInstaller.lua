-- ============================================================================
-- HotkeyBuilder Installer & Loader
-- ============================================================================
local RAW_URL = "https://raw.githubusercontent.com/s3rvxnt/PlasmiiPlugins/refs/heads/main/HotKeyBuilder.lua"
local PLUGIN_DIR = "Plasmii/Plugins"
local PLUGIN_PATH = "Plasmii/Plugins/HotkeyBuilder.txt"

-- 1. Ensure folders exist
if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
    if not isfolder("Plasmii") then makefolder("Plasmii") end
    if not isfolder(PLUGIN_DIR) then makefolder(PLUGIN_DIR) end
end

-- 2. Check if HotkeyBuilder already exists in the plugins folder
local alreadyInstalled = (typeof(isfile) == "function" and isfile(PLUGIN_PATH))

if not alreadyInstalled then
    print("[HotkeyBuilder]: Not found in plugins folder. Installing...")
    local success, content = pcall(function()
        return game:HttpGet(RAW_URL)
    end)

    if success and content and #content > 0 then
        writefile(PLUGIN_PATH, content)
        print("[HotkeyBuilder]: Successfully installed to " .. PLUGIN_PATH)
    else
        warn("[HotkeyBuilder]: Failed to download plugin from GitHub:", content)
        return
    end
else
    print("[HotkeyBuilder]: Already installed in " .. PLUGIN_PATH .. ". Skipping download.")
end

-- 3. Execute and launch the plugin
if typeof(loadfile) == "function" then
    loadfile(PLUGIN_PATH)()
elseif typeof(readfile) == "function" then
    loadstring(readfile(PLUGIN_PATH))()
end
