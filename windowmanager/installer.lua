print([[
    ===========================================================
    Windowmanager 1.2
    Created by Dustpuppy
    Maintained by Þeros (because all development halted 7 years ago)
    -----------------------------------------------------------
    This is not the original installer, it is rebuilt from scratch because the old one does not work with modern OpenOS versions,
    as the website it's hosted on is http.
    ===========================================================
]])
local files = {
    "/usr/bin/windowmanager.lua",
    "/usr/lib/windowmanager/doc/docu",
    "/usr/lib/windowmanager/driver/keyboarddriver.lua",
    "/usr/lib/windowmanager/driver/networkdriver.lua",
    "/usr/lib/windowmanager/driver/printserver.lua",
    "/usr/lib/windowmanager/driver/usermanagement.lua",
    "/usr/lib/windowmanager/libs/crypt.lua",
    "/usr/lib/windowmanager/libs/guiElements.lua",
    "/usr/lib/windowmanager/libs/wm.lua",
    "/usr/lib/windowmanager/programs/driverinfo.lua",
    "/usr/lib/windowmanager/programs/cardwriter",
    "/usr/lib/windowmanager/programs/cardreader",
    "/usr/lib/windowmanager/programs/messenger.lua",
    "/usr/lib/windowmanager/programs/program_frame.lua",
    "/usr/lib/windowmanager/programs/startmenu_config.lua",
    "/usr/lib/windowmanager/programs/usermanager.lua",
    "/usr/lib/windowmanager/symbols/energymonitor.lua",
    "/usr/lib/windowmanager/symbols/memorymonitor.lua",
    "/usr/lib/windowmanager/symbols/network.lua",
    "/usr/lib/windowmanager/symbols/plugin_framework.lua",
    "/usr/lib/windowmanager/symbols/printer.lua"
}
print("Creating directories...")
local fs = require("filesystem")
fs.makeDirectory("/usr/bin")
fs.makeDirectory("/usr/lib")
fs.makeDirectory("/usr/lib/windowmanager")
fs.makeDirectory("/usr/lib/windowmanager/doc")
fs.makeDirectory("/usr/lib/windowmanager/driver")
fs.makeDirectory("/usr/lib/windowmanager/libs")
fs.makeDirectory("/usr/lib/windowmanager/programs")
fs.makeDirectory("/usr/lib/windowmanager/symbols")
fs.makeDirectory("/etc/windowmanager")
print("Installing...")
for _, file in ipairs(files) do
    io.write("-> Installing " .. file)
    require("shell").execute("wget -q -f https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/windowmanager/" .. file .. " " .. file)
    io.write(" [DONE]\n")
end
print("running setup...")
require("shell").execute("windowmanager save-config")
print("Finished.")
os.exit()