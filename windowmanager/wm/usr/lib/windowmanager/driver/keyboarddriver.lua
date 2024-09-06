local component = require("component")
local gpu = component.gpu
local event = require("event")
local modem = component.modem
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local sh = require("sh")
local fs = require("filesystem")

local ScreenWidth, ScreenHeight = gpu.getResolution()

local function identifyProgram(path)
  local file = io.open(path, "r")
  if file then
    l = file:read("*l")
    io.close(file)
    if l == "-- GUI --" then
      return true
    end
  end
  return false
end

local keyboarddriver = {}

local version = "1.0"

local window

local function commandInputCallback(self, win)
  local command = gui.getElementText(self)
  gui.setElementText(self, "")
  wm.closeWindow(win)
  if command ~= "" then
    if fs.exists(command) then
      if identifyProgram(command) == true then
	wm.startProgram(command, 0)
      end
    end
  end
  
end


local function runCommand()
    local windowWidth = 50
    local windowHeight = 4
  
    window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), 2, windowWidth, windowHeight, "Run command")
    wm.setWindowSticky(window, true)

    commandInput = gui.newInput(1, 2, windowWidth - 2, "", commandInputCallback)
    wm.addElement(window, commandInput)

    wm.raiseWindow(window)
end

function key_downCallback(_, _, ch, code)
  local alt = keyboard.isAltDown()
  local ctrl = keyboard.isControlDown()
  local shift = keyboard.isShiftDown()
--  gpu.set(1,2, "                                                             ")
--  gpu.set(1,2, tostring(ch) .. " " .. tostring(code) .. " " .. tostring(ctrl))
  if code == 3 and ctrl then		-- ctrl-2
    runCommand()
  end
end

function key_upCallback(_, _, ch, code)
  local alt = keyboard.isAltDown()
  local ctrl = keyboard.isControlDown()
  local shift = keyboard.isShiftDown()
end


function keyboarddriver.start()
  wm.registerDriver("keyboard", "A driver that handles background keyboard events", "S.Kempa", version)
  event.listen("key_down", key_downCallback)
  event.listen("key_up", key_downCallback)
end

function keyboarddriver.stop()
  event.ignore("key_down", key_downCallback)
  event.ignore("key_up", key_downCallback)
end

return keyboarddriver

