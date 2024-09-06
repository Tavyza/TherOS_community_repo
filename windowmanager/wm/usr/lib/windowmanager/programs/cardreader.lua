-- GUI --
local component = require("component")
local gpu = component.gpu
local computer = require("computer")
local event = require("event")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")


if gui.checkComponent("os_magreader") == false then
  return
end

local ScreenWidth, screenHeight = gpu.getResolution()

local args = { ... }

local myID = args[1]

-- NOTE: Change to your options
local ProgramName = "Open security magnetic card reader"
local windowWidth = 56
local windowHeight = 14
local windowX = math.floor(ScreenWidth/2) - math.floor(windowWidth/2)
local windowY = math.floor(screenHeight/2) - math.floor(windowHeight/2)

--NOTE: Put your gui element here, if you use them global in your program
local window, dataLabel, lockedLabel, usernameLabel, uuidLabel

local running = true

local function windowCloseCallback(win)
  running = false
end


local function eventCallback(_, _, name, data, uuid, locked)
  gui.setElementText(usernameLabel, name)
  gui.setElementText(uuidLabel, uuid)
  gui.setElementText(dataLabel, data)
  if locked == true then
    gui.setElementText(lockedLabel, "yes")
  else
    gui.setElementText(lockedLabel, "no")
  end
  
  gui.drawElement(window, usernameLabel)
  gui.drawElement(window, uuidLabel)
  gui.drawElement(window, dataLabel)
  gui.drawElement(window, lockedLabel)
end

window = wm.newWindow(windowX, windowY, windowWidth, windowHeight, ProgramName)
wm.setOnCloseCallback(window, windowCloseCallback)
--wm.disableWindowButtons(window, true)
--wm.hideWindow(window, hideWindowFromList)
--wm.setWindowSticky(window, true)

wm.addElement(window, gui.newLabel(2, 2, 15, 1, "Username    :"))
wm.addElement(window, gui.newLabel(2, 4, 15, 1, "Card UUID   :"))
wm.addElement(window, gui.newLabel(2, 6, 15, 1, "Card locked :"))
wm.addElement(window, gui.newLine(1, 7, windowWidth - 2))
dataDisplayLabel = gui.newLabel(2, 9, windowWidth - 4, 1, "Data")
gui.setElementAlignment(dataDisplayLabel, "center")
wm.addElement(window, dataDisplayLabel)

usernameLabel = gui.newLabel(16, 2, 38, 1, "")
gui.setElementBackground(usernameLabel, 0xFFFFFF)
wm.addElement(window, usernameLabel)
uuidLabel = gui.newLabel(16, 4, 38, 1, "")
gui.setElementBackground(uuidLabel, 0xFFFFFF)
wm.addElement(window,uuidLabel)
lockedLabel = gui.newLabel(16, 6, 3, 1, "")
gui.setElementBackground(lockedLabel, 0xFFFFFF)
wm.addElement(window,lockedLabel)
dataLabel = gui.newLabel(2, 10, windowWidth - 4, 4, "")
gui.setElementBackground(dataLabel, 0xFFFFFF)
gui.setElementAutoWordWrap(dataLabel, true)
wm.addElement(window,dataLabel)


wm.raiseWindow(window)

event.listen("magData", eventCallback)

  while running == true do
    if wm.getActiveWindow() == window then					-- prevent window from updating, if it is not the top windows
    end
  os.sleep(0.000001)
  end

event.ignore("magData", eventCallback)

if myID > 0 then 
  wm.exitProgram(myID) 
end 
wm.closeWindow(window) 
