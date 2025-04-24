local component = require("component")
local gpu = component.gpu
local event = require("event")
local ser = require("serialization")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local term = require("term")
local text = require("text")
local crypt = require("windowmanager/libs/crypt")
local computer = require("computer")

local args = { ... }


local symbolTable = {
  { ["icon"] = "P", ["path"] = "/usr/lib/windowmanager/symbols/printer.lua", ["level"] = 0 },
  { ["icon"] = "N", ["path"] = "/usr/lib/windowmanager/symbols/network.lua", ["level"] = 0 },
--  { ["icon"] = "F", ["path"] = "/usr/lib/windowmanager/symbols/plugin_framework.lua", ["level"] = 0 },
  { ["icon"] = " ", ["path"] = "/usr/lib/windowmanager/symbols/memorymonitor.lua", ["level"] = 0 },
  { ["icon"] = " ", ["path"] = "/usr/lib/windowmanager/symbols/energymonitor.lua", ["level"] = 0 },
}

local startMenuTable = {
  { ["name"] = "User Manager", ["path"] = "/usr/lib/windowmanager/programs/usermanager.lua", ["param"] = nil, ["level"] = 99, ["type"] = 0},
  { ["name"] = "Config Start Menu", ["path"] = "/usr/lib/windowmanager/programs/startmenu_config.lua", ["param"] = nil, ["level"] = 99, ["type"] = 0},
  { ["name"] = "Driver Info", ["path"] = "/usr/lib/windowmanager/programs/driverinfo.lua", ["param"] = nil, ["level"] = 0, ["type"] = 0},
--  { ["name"] = "Program Frame", ["path"] = "/usr/lib/windowmanager/programs/program_frame.lua", ["param"] = nil, ["level"] = 0, ["type"] = 0},
  { ["name"] = "Messenger", ["path"] = "/usr/lib/windowmanager/programs/messenger.lua", ["param"] = nil, ["level"] = 0, ["type"] = 0},
  { ["name"] = "Card Reader", ["path"] = "/usr/lib/windowmanager/programs/cardreader.lua", ["param"] = nil, ["level"] = 0, ["type"] = 0},
  { ["name"] = "Card Writer", ["path"] = "/usr/lib/windowmanager/programs/cardwriter.lua", ["param"] = nil, ["level"] = 0, ["type"] = 0},
}

local driverTable = {
  { ["driver"] = user, ["file"] = "windowmanager/driver/usermanagement", ["startfunc"] = "start", ["extrafunc"] = "login" },
  { ["driver"] = printserver, ["file"] = "windowmanager/driver/printserver", ["startfunc"] = "start", ["extrafunc"] = nil },
  { ["driver"] = networkdriver, ["file"] = "windowmanager/driver/networkdriver", ["startfunc"] = "start", ["extrafunc"] = nil },
  { ["driver"] = keyboard, ["file"] = "windowmanager/driver/keyboarddriver", ["startfunc"] = "start", ["extrafunc"] = nil },
}

local function save(name, tbl)
  print("saving " .. name)
  local file = io.open(name, "w")
  file:write(ser.serialize(tbl))
  file:close()
end


function load(name)
  local file = io.open(name, "r")
  local tmpTable = ser.unserialize(file:read("*all"))
  file:close()
  return tmpTable
end

if args[1] == "save-config" then
  term.write("Admin user name : ")
  adminUserName = text.trim(term.read())
  
  while adminUserPassword ~= adminUserPassword2 or adminUserPassword == "" or adminUserPassword == nil do
    term.write("Admin user password : ")
    adminUserPassword = text.trim(term.read({pwchar = "*"}))
    term.write("Again : ")
    adminUserPassword2 = text.trim(term.read({pwchar = "*"}))
    if adminUserPassword ~= adminUserPassword2 then
      print("Passwords not matching")
    end
  end
  
  print("saving /etc/windowmanager/passwd")
  local k = crypt.string2key(adminUserPassword)
  local password = crypt.crypt(adminUserPassword,k)
  local file = io.open("/etc/windowmanager/passwd","w")
  file:write(adminUserName .. ":99:" .. password)
  file:close()
  
  computer.removeUser(adminUserName)		-- just in case
  computer.addUser(adminUserName)
  
  save("/etc/windowmanager/symbol.tbl", symbolTable)
  save("/etc/windowmanager/startmenu.tbl", startMenuTable)
  save("/etc/windowmanager/driver.tbl", driverTable)
  os.exit()
else
  symbolTable = load("/etc/windowmanager/symbol.tbl")
  startMenuTable = load("/etc/windowmanager/startmenu.tbl")
  driverTable = load("/etc/windowmanager/driver.tbl")
end

if args[1] == "single-user" then
  driverTable[1].extrafunc = nil

end

wm.startGui()
--wm.useShadows(false)
local versionMajor, versionMinor, versionState = wm.getVersion()
wm.setTopText(string.format("Window Manager v%d.%d %s", versionMajor, versionMinor, versionState))

for i = 1, #symbolTable do
  wm.newSymbol(symbolTable[i].icon, symbolTable[i].path, symbolTable[i].level)
end

for i = 1, #startMenuTable do
  wm.addStartMenu(startMenuTable[i].name, startMenuTable[i].path, startMenuTable[i].param, startMenuTable[i].level, startMenuTable[i].type)
end

wm.setSystemMenuPos("right")
wm.addSystemMenu("Exit", wm.exitGui, nil, 0, 1)
wm.addSystemMenu("Shutdown", wm.shutdown, nil, 0, 1)
wm.addSystemMenu("Reboot", wm.shutdown, true, 0, 1)
if wm.getUsername() ~= "" then
  wm.addSystemMenu("logout", user.logout, nil, 0, 1)
end


for i = 1,# driverTable do
  driverTable[i].driver = require(driverTable[i].file)
  driverTable[i].driver[driverTable[i].startfunc]()
  if driverTable[i].extrafunc ~= nil then
    driverTable[i].driver[driverTable[i].extrafunc]()
  end
end

local running = true
while running == true do
  os.sleep(0)
end
