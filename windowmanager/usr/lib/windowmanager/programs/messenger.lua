-- GUI --
local component = require("component")
local gpu = component.gpu
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local networkdriver = require("windowmanager/driver/networkdriver")

local ScreenWidth, screenHeight = gpu.getResolution()

local modemPort = networkdriver.getPort("internal")

local args = { ... }

local myID = args[1]

local ProgramName = "Messenger"
local windowWidth = 30
local windowHeight = 16


local selectedUser = 1
local window, messageInput, List, Slider

networkdriver.clearUserList()
networkdriver.modemBroadcast(modemPort,"GET USER")
os.sleep(0.5)						-- give network driver the chance to rebuild list
local userList = networkdriver.getUserList()

function sendCallback(self, win)
  local empf = userList[selectedUser].addr
  local port = networkdriver.getPort("message")
  local msg = gui.getElementText(messageInput)
  local from = wm.getUsername()
  if msg ~= "" then
    networkdriver.modemSend(empf, port, msg, from)
  end
  gui.setElementText(messageInput, "")
  gui.drawElement(window, messageInput)
end

window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(screenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight, ProgramName)
wm.disableWindowButtons(window, true)

List = gui.newList(2, 2, 25, 10, "", function() selectedUser = gui.getElementSelected(List) gui.setElementValue(Slider, selectedUser) gui.drawElement(window, Slider) end)
gui.clearElementData(List)
wm.addElement(window, List)
gui.setElementBackground(List, 0xFFFFFF)
gui.setElementActiveBackground(List, 0x202020)
gui.setElementForeground(List, 0x000000)
gui.setElementActiveForeground(List, 0xFFFFFF)
for i = 1, #userList do
  gui.insertElementData(List, userList[i].user)
end
    
Slider = gui.newVSlider(27, 2, 10, function() selectedUser = gui.getElementValue(Slider) gui.setElementSelected(List, selectedUser) gui.drawElement(window, List) end)
gui.setElementMin(Slider, 1)
gui.setElementValue(Slider, 1)
wm.addElement(window, Slider)
gui.setElementMax(Slider, #userList)

messageInput = gui.newInput(2, 13, 26, "")
wm.addElement(window, messageInput)

local SendButton = gui.newButton(2, windowHeight - 1, 6, 1, "send", sendCallback)
wm.addElement(window, SendButton)

local CloseButton = gui.newButton(20, windowHeight - 1, 7, 1, "close", function() if myID > 0 then wm.exitProgram(myID) end wm.exitProgram(myID) wm.closeWindow(window) end)
wm.addElement(window, CloseButton)

wm.raiseWindow(window)


