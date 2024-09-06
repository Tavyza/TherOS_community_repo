-- GUI --
local component = require("component")
local gpu = component.gpu
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local user = require("windowmanager/driver/usermanagement")


local ScreenWidth, screenHeight = gpu.getResolution()

local args = { ... }

local myID = args[1]

local ProgramName = "User manager"
local windowWidth = 40
local windowHeight = 16

local running = true
local selectedUser = 1

local List, Slider, levelInput, window, errorLabel, passwordInput, secondPassword, newWindow, usernameInput, newLevelInput, userlist

local function update()
  userlist = user.getUserList()
  gui.clearElementData(List)
  for i = 1, #userlist do
    gui.insertElementData(List, userlist[i].user)
  end
  gui.setElementMax(Slider, #userlist)
  gui.setElementText(levelInput, tostring(userlist[selectedUser].level))
  gui.drawElement(window, List)
  gui.drawElement(window, levelInput)
end

local function levelInputCallback(self, win)
  local l = gui.getElementText(levelInput)
  local us = userlist[selectedUser].user
  user.setLevel(us, tonumber(l))
  update()
end


function okButtonCallback(self, win)
   local p1 = gui.getElementText(passwordInput) 
   local p2 = gui.getElementText(secondPassword)
  if p1 ~= p2 then
    gui.setElementText(errorLabel, "Passwords don't match!")
    gui.drawElement(newWindow, errorLabel)
    os.sleep(1)
    gui.setElementText(errorLabel, "")
    gui.drawElement(newWindow, errorLabel)
    return
  end
  local us = gui.getElementText(usernameInput)
  if us == "" then
    gui.setElementText(errorLabel, "Invalid user name!")
    gui.drawElement(newWindow, errorLabel)
    os.sleep(1)
    gui.setElementText(errorLabel, "")
    gui.drawElement(newWindow, errorLabel)
    return
  end
  local l = tonumber(gui.getElementText(newLevelInput))
  if l > 99 then
    gui.setElementText(errorLabel, "Level too hight!")
    gui.drawElement(newWindow, errorLabel)
    os.sleep(1)
    gui.setElementText(errorLabel, "")
    gui.drawElement(newWindow, errorLabel)
    return
  end
  if l < 0 then
    gui.setElementText(errorLabel, "Level too low!")
    gui.drawElement(newWindow, errorLabel)
    os.sleep(1)
    gui.setElementText(errorLabel, "")
    gui.drawElement(newWindow, errorLabel)
    return
  end
  local r, t = user.addUser(us, p1, l)
  if r ~= true then
    gui.setElementText(errorLabel, t)
    gui.drawElement(newWindow, errorLabel)
    os.sleep(1)
    gui.setElementText(errorLabel, "")
    gui.drawElement(newWindow, errorLabel)
  end
  update()
  wm.closeWindow(win)
  wm.raiseWindow(window)
end




local function addCallback(self, win)
 
  newWindow = wm.newWindow(math.floor(ScreenWidth/2) - 20, math.floor(screenHeight/2) - 6, 40, 12, "Add user")
  wm.disableWindowButtons(newWindow, true)
--  wm.setWindowSticky(newWindow, true)

  wm.addElement(newWindow, gui.newLabel(2, 2, 14, 1, "User name :"))
  usernameInput = gui.newInput(16, 2, 20, "")
  wm.addElement(newWindow, usernameInput)
  wm.addElement(newWindow, gui.newLabel(2, 4, 14, 1, "Level     :"))
  newLevelInput = gui.newInput(16, 4, 3, "")
  wm.addElement(newWindow, newLevelInput)

  wm.addElement(newWindow, gui.newLine( 1, 5, 38))

  wm.addElement(newWindow, gui.newLabel(2, 6, 11, 1, "Password :"))
  wm.addElement(newWindow, gui.newLabel(2, 8, 11, 1, "Again    :"))
  
  passwordInput = gui.newInput(14, 6, 20, "")
  gui.setElementProtected(passwordInput, true)
  wm.addElement(newWindow, passwordInput)

  secondPassword = gui.newInput(14, 8, 20, "")
  gui.setElementProtected(secondPassword, true)
  wm.addElement(newWindow, secondPassword)
  
  
  wm.addElement(newWindow, gui.newLine( 1, 9, 38))

  errorLabel = gui.newLabel(1, 10, 38, 1, "")
  gui.setElementAlignment(errorLabel, "center")
  gui.setElementForeground(errorLabel, 0xFF0000)
  wm.addElement(newWindow, errorLabel)

  local okButton = gui.newButton(18, 11, 4, 1, "ok", okButtonCallback)
  wm.addElement(newWindow, okButton)

  local cancelButton = gui.newButton(2, 11, 8, 1, "cancel", function() wm.closeWindow(win) wm.raiseWindow(window) end)
  wm.addElement(newWindow, cancelButton)

  wm.closeWindow(window)
  
  wm.raiseWindow(newWindow)
end

local function removeCallback(self, win)
  user.remove(userlist[selectedUser].user)
  update()
end


window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(screenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight, ProgramName)
wm.disableWindowButtons(window, true)
--wm.setWindowSticky(window, true)

List = gui.newList(2, 2, windowWidth - 5, 8, "", function() selectedUser = gui.getElementSelected(List) gui.setElementValue(Slider) gui.drawElement(window, Slider) end)
wm.addElement(window, List)
gui.setElementBackground(List, 0xFFFFFF)
gui.setElementActiveBackground(List, 0x202020)
gui.setElementForeground(List, 0x000000)
gui.setElementActiveForeground(List, 0xFFFFFF)
    
Slider = gui.newVSlider(37, 2, 8, function() selectedUser = gui.getElementValue(Slider) gui.setElementSelected(List, selectedUser) gui.drawElement(window, List) end)
gui.setElementMin(Slider, 1)
gui.setElementValue(Slider, 1)
wm.addElement(window, Slider)

wm.addElement(window, gui.newLine(1, 11, 38))

wm.addElement(window, gui.newLabel(2, 12, 20, 1, "Level :"))

levelInput = gui.newInput(10, 12, 3, "", levelInputCallback)
wm.addElement(window, levelInput)

wm.addElement(window, gui.newLine(1, 13, 38))

local addButton = gui.newButton(2, windowHeight - 1, 10, 1, "add user", addCallback)
wm.addElement(window, addButton)

local removeButton = gui.newButton(13, windowHeight - 1, 13, 1, "remove user", removeCallback)
wm.addElement(window, removeButton)

local CloseButton = gui.newButton(31, windowHeight - 1, 7, 1, "close", function() if myID > 0 then wm.exitProgram(myID) end wm.closeWindow(window) running = false end)
wm.addElement(window, CloseButton)

wm.raiseWindow(window)

update()


while running == true do
  if wm.getActiveWindow() == window and window.moving == false then
  end
  
  os.sleep(0.000001)
end
