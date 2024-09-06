-- GUI --
local component = require("component")
local gpu = component.gpu
local computer = require("computer")
local event = require("event")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local ser = require("serialization")


local ScreenWidth, screenHeight = gpu.getResolution()

local args = { ... }

local myID = args[1]

local function saveTable(name, tbl)
  local file = io.open(name, "w")
  file:write(ser.serialize(tbl))
  file:close()
end


function loadTable(name)
  local file = io.open(name, "r")
  local tmpTable = ser.unserialize(file:read("*all"))
  file:close()
  return tmpTable
end

local listSelectedEntry = 1
local startMenuTable = {}

local window, closeButton, menuEntryInput, programInput, paramInput, levelInput

local function redrawTextFields()
  gui.setElementText(menuEntryInput, startMenuTable[listSelectedEntry].name)
  gui.drawElement(window, menuEntryInput)
  gui.setElementText(programInput, startMenuTable[listSelectedEntry].path)
  gui.drawElement(window, programInput)
  if startMenuTable[listSelectedEntry].param then
    gui.setElementText(paramInput, startMenuTable[listSelectedEntry].param)
  else
    gui.setElementText(paramInput, "")
  end
  gui.drawElement(window, paramInput)
  gui.setElementText(levelInput, tostring(startMenuTable[listSelectedEntry].level))
  gui.drawElement(window, levelInput)
end

local function insertButtonCallback(self, win)
  gui.insertElementData(List, gui.getElementText(menuEntryInput))
  gui.setElementMax(listSlider, #List.data)
  listSelectedEntry = 1
  gui.setElementSelected(List, 1)
  gui.drawElement(window, List) gui.setElementValue(listSlider, 1)
  gui.drawElement(window, listSlider)

  if gui.getElementText(paramInput) ~= "" then
    param = gui.getElementText(paramInput) 
  else
    param = nil
  end
  table.insert(startMenuTable, { ["name"] = gui.getElementText(menuEntryInput), ["path"] = gui.getElementText(programInput), ["param"] = param, ["level"] = tonumber(gui.getElementText(levelInput)), ["type"] = 0})
  redrawTextFields()
end

local function removeButtonCallback(self, win)
  gui.removeElementData(List, listSelectedEntry)
  
  table.remove(startMenuTable, listSelectedEntry)
  
  listSelectedEntry = 1
  gui.setElementMax(listSlider, #List.data)
  gui.setElementSelected(List, 1)
  gui.drawElement(window, List)
  gui.setElementValue(listSlider, 1)
  gui.drawElement(window, listSlider)

  redrawTextFields()
end

local function changeButtonCallback(self, win)
  gui.changeElementData(List, listSelectedEntry, gui.getElementText(menuEntryInput))
  gui.drawElement(window, List)

  if gui.getElementText(paramInput) ~= "" then
    param = gui.getElementText(paramInput) 
  else
    param = nil
  end
  
  startMenuTable[listSelectedEntry].name = gui.getElementText(menuEntryInput)
  startMenuTable[listSelectedEntry].path = gui.getElementText(programInput)
  startMenuTable[listSelectedEntry].param = param
  startMenuTable[listSelectedEntry].level = tonumber(gui.getElementText(levelInput))
  redrawTextFields()
end

local function listClickCallback(self, win)
  listSelectedEntry = gui.getElementSelected(List)
  gui.setElementValue(listSlider, listSelectedEntry)
  gui.drawElement(window, listSlider)

  redrawTextFields()
end

local function sliderClickCallback(self, win)
  listSelectedEntry = gui.getElementValue(listSlider)
  gui.setElementSelected(List, listSelectedEntry)
  gui.drawElement(window, List)
  
  redrawTextFields()
end

local function saveButtonCallback(self, win)
  saveTable("/etc/windowmanager/startmenu.tbl", startMenuTable)
  wm.clearStartMenu()
  for i = 1, #startMenuTable do
    wm.addStartMenu(startMenuTable[i].name, startMenuTable[i].path, startMenuTable[i].param, startMenuTable[i].level, startMenuTable[i].type)
  end
end

local ProgramName = "Start menu config"
local windowWidth = 70
local windowHeight = 22
local windowX = math.floor(ScreenWidth/2) - math.floor(windowWidth/2)
local windowY = math.floor(screenHeight/2) - math.floor(windowHeight/2)

local ListX = 1
local ListY = 1

local running = true

window = wm.newWindow(windowX, windowY, windowWidth, windowHeight, ProgramName)
--wm.disableWindowButtons(window, true)

wm.addElement(window, gui.newFrame(ListX, ListY, 38, 21))
wm.addElement(window, gui.newFrame(ListX + 3, ListY + 17, 30, 3))

List = gui.newList(ListX + 2, ListY + 1, 33, 15, "", listClickCallback)
gui.clearElementData(List)
wm.addElement(window, List)
gui.setElementBackground(List, 0xFFFFFF)
gui.setElementActiveBackground(List, 0x202020)
gui.setElementForeground(List, 0x000000)
gui.setElementActiveForeground(List, 0xFFFFFF)

listSlider = gui.newVSlider(ListX + 35, ListY + 1, 15, sliderClickCallback)
gui.setElementMin(listSlider, 1)
gui.setElementValue(listSlider, 1)
wm.addElement(window, listSlider)
gui.setElementMax(listSlider, 1)

listInsertButton = gui.newButton(ListX + 4, ListY + 18, 8, 1, "insert", insertButtonCallback)
wm.addElement(window, listInsertButton)
  
listRemoveButton = gui.newButton(ListX + 14, ListY + 18, 8, 1, "remove", removeButtonCallback)
wm.addElement(window, listRemoveButton)

listChangeButton = gui.newButton(ListX + 24, ListY + 18, 8, 1, "change", changeButtonCallback)
wm.addElement(window, listChangeButton)

startMenuTable = loadTable("/etc/windowmanager/startmenu.tbl")

for i = 1, #startMenuTable do
  gui.insertElementData(List, startMenuTable[i].name)
end

gui.setElementMax(listSlider, #startMenuTable)

wm.addElement(window, gui.newLabel(40, 2, 12, 1, "Menu entry"))
wm.addElement(window, gui.newLabel(40, 5, 12, 1, "Program"))
wm.addElement(window, gui.newLabel(40, 8, 12, 1, "Arguments"))
wm.addElement(window, gui.newLabel(40, 11, 12, 1, "User level"))

menuEntryInput = gui.newInput(40, 3, 28, "")
programInput = gui.newInput(40, 6, 28, "")
paramInput = gui.newInput(40, 9, 28, "")
levelInput = gui.newInput(40, 12, 28, "")

wm.addElement(window, menuEntryInput)
wm.addElement(window, programInput)
wm.addElement(window, paramInput)
wm.addElement(window, levelInput)

redrawTextFields()

saveButton = gui.newButton(50, 15, 6, 1, "Save", saveButtonCallback)
wm.addElement(window, saveButton)

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

