local component = require("component")
local gpu = component.gpu
local computer = require("computer")
local unicode = require("unicode")
local event = require("event")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")

-- Program parameters
-- NOTE: Change to your options
local programName = "Memory monitor"
local releaseYear = "2017"
local versionMajor = 1
local versionMinor = 0
local author = "S.Kempa"
local windowWidth = 60
local windowHeight = 20
local hideWindowFromList = true


local ScreenWidth, screenHeight = gpu.getResolution()
local args = {...}
local myID = args[1]
local myIcon = args[4]

local symbols = {
  unicode.char(0x2581),
  unicode.char(0x2582),
  unicode.char(0x2583),
  unicode.char(0x2584),
  unicode.char(0x2585),
  unicode.char(0x2586),
  unicode.char(0x2587),
  unicode.char(0x2588),
}

-- Function that will called, if one of the exit buttons is clicked
local function exitButtonCallback(self, win)
  --NOTE: Put code here, that you need before window is closed
  
  wm.closeWindow(win)
  wm.setRunningState(myID, false)
end

local function timerMemCallback()
  local memory, maxMemory
  local posX, posY = wm.getSymbolPos(myID)
    memory = computer.freeMemory()
    maxMemory = computer.totalMemory()
    memorySymbol = math.floor(8 / maxMemory * memory)
    gpu.setBackground(0x202020)
    if memorySymbol < 4 and memorySymbol > 2 then
      gpu.setForeground(0xA0A000)
    elseif memorySymbol > 2 then
      gpu.setForeground(0x008000)
    else
      gpu.setForeground(0xFF0000)
    end
    if memorySymbol > 0 then
      gpu.set(posX, posY, symbols[memorySymbol])
    end

end

if args[2] == "load" then
    timerMem = event.timer(0.5, timerMemCallback, math.huge)
  
elseif args[2] == "unload" then
    event.ignore(timerMem)
  
elseif args[2] == "execute" and args[3] == 1 then
  wm.setRunningState(myID, true)
  local infoWindow = wm.newWindow(math.floor(ScreenWidth/2) - 15, math.floor(screenHeight/2) - 4, 32, 10, "Info")
  wm.setWindowSticky(infoWindow, true)
  wm.disableWindowButtons(infoWindow, true)
  local infoVersion = gui.newLabel(1, 2, 30, 1, string.format("%s v%d.%d", programName, versionMajor, versionMinor))
  gui.setElementAlignment(infoVersion, "center")
  wm.addElement(infoWindow, infoVersion)
  local infoCopyright = gui.newLabel(1, 4, 30, 1, string.format("Copyright%s %s by",  unicode.char(0x00A9), releaseYear))
  gui.setElementAlignment(infoCopyright, "center")
  wm.addElement(infoWindow, infoCopyright)
  local infoCopyright2 = gui.newLabel(1, 5, 30, 1, string.format("%s", author))
  gui.setElementAlignment(infoCopyright2, "center")
  wm.addElement(infoWindow, infoCopyright2)
  local infoExitButton = gui.newButton(13, 9, 6, 1, "exit", exitButtonCallback)
  wm.addElement(infoWindow, infoExitButton)
  wm.raiseWindow(infoWindow)
end


