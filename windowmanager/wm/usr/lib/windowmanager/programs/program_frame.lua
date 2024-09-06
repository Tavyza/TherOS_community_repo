-- GUI --
---------------------------------------
-- the top line is needed to identify programs for internal usage

local component = require("component")
local gpu = component.gpu
local computer = require("computer")
local event = require("event")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local printserver = require("windowmanager/driver/printserver")
local networkdriver = require("windowmanager/driver/networkdriver")
local user = require("windowmanager/driver/usermanagement")
local keyboard = require("windowmanager/driver/keyboard.lua")


local ScreenWidth, screenHeight = gpu.getResolution()

local args = { ... }

local myID = args[1]

-- NOTE: Change to your options
local ProgramName = "Test Program"
local windowWidth = 60
local windowHeight = 20
local windowX = math.floor(ScreenWidth/2) - math.floor(windowWidth/2)
local windowY = math.floor(screenHeight/2) - math.floor(windowHeight/2)

--NOTE: Put your gui element here, if you use them global in your program
local window, closeButton

local running = true

local function windowCloseCallback(win)
  -- NOTE: Insert your code, that will be execute before closing the window here
  running = false
end



local function windowLowerCallback(win)
  -- NOTE: Insert your code, that will be execute when lowering the window here
end



local function buttonCallback(self, win)
  -- NOTE: Insert your code, that will be execute before closing the window here
  running = false
end


window = wm.newWindow(windowX, windowY, windowWidth, windowHeight, ProgramName)
wm.setOnCloseCallback(window, windowCloseCallback)
wm.setOnLowerCallback(window, windowLowerCallback)
--wm.disableWindowButtons(window, true)
--wm.hideWindow(window, hideWindowFromList)
--wm.setWindowSticky(window, true)

local closeButton = gui.newButton(math.floor(windowWidth/2) - 4, windowHeight - 1, 7, 1, "close", buttonCallback)
wm.addElement(window, closeButton)

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

