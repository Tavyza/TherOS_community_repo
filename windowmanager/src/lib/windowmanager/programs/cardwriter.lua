-- GUI --
local component = require("component")
local gpu = component.gpu
local computer = require("computer")
local event = require("event")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")


if gui.checkComponent("os_cardwriter") == false then
  return
end

local writer = component.os_cardwriter

local ScreenWidth, screenHeight = gpu.getResolution()

local args = { ... }

local myID = args[1]

local ProgramName = "Open security card writer"
local windowWidth = 40
local windowHeight = 9
local windowX = math.floor(ScreenWidth/2) - math.floor(windowWidth/2)
local windowY = math.floor(screenHeight/2) - math.floor(windowHeight/2)

local running = true

local nameInput, dataInput

local function writeButtonCallback(self, win)
  local name = gui.getElementText(nameInput)
  local data = gui.getElementText(dataInput)
  local lock = gui.getElementState(checkbox)
  writer.write(data, name, lock)
  gui.setElementText(nameInput, "")
  gui.setElementText(dataInput, "")
  gui.setElementState(checkbox, false)
  gui.drawElement(win, nameInput)
  gui.drawElement(win, dataInput)
  gui.drawElement(win, checkbox)
end



local function windowCloseCallback(win)
  running = false
end


window = wm.newWindow(windowX, windowY, windowWidth, windowHeight, ProgramName)
wm.setOnCloseCallback(window, windowCloseCallback)
--wm.disableWindowButtons(window, true)
--wm.hideWindow(window, hideWindowFromList)
--wm.setWindowSticky(window, true)

wm.addElement(window, gui.newLabel(2, 2, 14, 1, "Card name :"))
wm.addElement(window, gui.newLabel(2, 4, 14, 1, "Card data :"))
  
nameInput = gui.newInput(15, 2, 23, "")
wm.addElement(window, nameInput)

dataInput = gui.newInput(15, 4, 23, "")
wm.addElement(window, dataInput)

checkbox = gui.newCheckbox(2, 6, "Lock card : ")
wm.addElement(window, checkbox)

local writeButton = gui.newButton(math.floor(windowWidth/2) - 4, windowHeight - 1, 7, 1, "write", writeButtonCallback)
wm.addElement(window, writeButton)

wm.raiseWindow(window)

  while running == true do
    if wm.getActiveWindow() == window then					-- prevent window from updating, if it is not the top windows
    end
  os.sleep(0.000001)
  end

  if myID > 0 then 
    wm.exitProgram(myID) 
  end 
  wm.closeWindow(window) 

