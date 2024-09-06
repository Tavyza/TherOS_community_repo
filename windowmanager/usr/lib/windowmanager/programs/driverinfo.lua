-- GUI --
local component = require("component")
local gpu = component.gpu
local computer = require("computer")
local event = require("event")
local ser = require("serialization")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")

local args = { ... }

local myID = args[1]

local running = true

local Slider, List

local selected = 1

local window = wm.newWindow(35, 2, 40, 13, "Driver info")
wm.disableWindowButtons(window, true)

List = gui.newList(2, 2, 15, 10, "", function() selected = gui.getElementSelected(List) gui.setElementValue(Slider, selected) gui.drawElement(window, Slider) end)
gui.clearElementData(List)
wm.addElement(window, List)
gui.setElementBackground(List, 0xFFFFFF)
gui.setElementActiveBackground(List, 0x202020)
gui.setElementForeground(List, 0x000000)
gui.setElementActiveForeground(List, 0xFFFFFF)
local driverList = wm.getDriverList()
for i = 1, #driverList do
  gui.insertElementData(List, driverList[i].name)
end
    
Slider = gui.newVSlider(17, 2, 10, function() selected = gui.getElementValue(Slider) gui.setElementSelected(List, selected) gui.drawElement(window, List) end)
gui.setElementMin(Slider, 1)
gui.setElementValue(Slider, 1)
wm.addElement(window, Slider)
gui.setElementMax(Slider, #driverList)

local nameLabel = gui.newLabel(20, 2, 18, 1, "")
local descriptionLabel = gui.newLabel(20, 4, 18, 4, "")
gui.setElementAutoWordWrap(descriptionLabel, true)
local copyrightLabel = gui.newLabel(20, 9, 18, 1, "")
wm.addElement(window, nameLabel)
wm.addElement(window, descriptionLabel)
wm.addElement(window, copyrightLabel)

local OkButton = gui.newButton(20, 11, 4, 1, "ok", function() if myID > 0 then wm.exitProgram(myID) end wm.closeWindow(window) running = false end)
wm.addElement(window, OkButton)

wm.raiseWindow(window)


while running == true do
  if wm.getActiveWindow() == window and window.moving == false then
    gui.setElementText(nameLabel, driverList[selected].name .. " v" .. driverList[selected].version)
    gui.drawElement(window, nameLabel)
    gui.setElementText(descriptionLabel, driverList[selected].description)
    gui.drawElement(window, descriptionLabel)
    gui.setElementText(copyrightLabel, "(c) by " .. driverList[selected].copyright)
    gui.drawElement(window, copyrightLabel)
  end
  
  os.sleep(0.000001)
end
