local component = require("component")
local gpu = component.gpu
local computer = require("computer")
local event = require("event")
local unicode = require("unicode")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local ser = require("serialization")

-- Program parameters
-- NOTE: Change to your options
local programName = "Framework"
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

-- Function that will called, if one of the exit buttons is clicked
local function exitButtonCallback(self, win)
  --NOTE: Put code here, that you need before window is closed
  
  wm.closeWindow(win)
  wm.setRunningState(myID, false)
end

if args[2] == "load" then
  -- NOTE: insert code that will executed when program is loaded
  
elseif args[2] == "unload" then
  -- NOTE: insert code that will executed when program is unloaded
  
  
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
  --[[
  local infoMemory = gui.newLabel(1, 7, 30, 1, string.format("%d Kb of %d Kb mem free", computer.freeMemory()/1024, computer.totalMemory()/1024))
  gui.setElementAlignment(infoMemory, "center")
  wm.addElement(infoWindow, infoMemory)
  ]]--
  local infoExitButton = gui.newButton(13, 9, 6, 1, "exit", exitButtonCallback)
  wm.addElement(infoWindow, infoExitButton)
  wm.raiseWindow(infoWindow)
elseif args[2] == "execute" and args[3] == 0 then
  wm.setRunningState(myID, true)
  local window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(screenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight,  programName)
  wm.hideWindow(window, hideWindowFromList)
--  wm.setWindowSticky(window, true)
  wm.disableWindowButtons(window, true)
  local windowExitButton = gui.newButton(math.floor(windowWidth/2) - 4, windowHeight - 1, 7, 1, "close", exitButtonCallback)
  wm.addElement(window, windowExitButton)
  wm.raiseWindow(window)

  -- NOTE: Insert your program code here
  
end


