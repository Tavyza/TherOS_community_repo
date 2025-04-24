local component = require("component")
local gpu = component.gpu
local event = require("event")
local modem = component.modem
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")

local ScreenWidth, ScreenHeight = gpu.getResolution()


local networkdriver = {}

local messagePort
local internalPort

local version = "1.0"

local portList = {
  ["printserver"] = 9100,
  ["message"] = 4662,
  ["internal"] = 148,
}

local userList = {}


local function displayMessageWindow(sender, message)
  local windowWidth = 40
  local windowHeight = 10
  
  local window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(ScreenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight, "Message")
  wm.disableWindowButtons(window, true)
  wm.setWindowSticky(window, true)

  wm.addElement(window, gui.newLabel(2, 2, windowWidth - 4, 1, "Sender: " .. sender))
  wm.addElement(window, gui.newLine(1, 3, windowWidth - 4))
  msgLabel = gui.newLabel(2, 4, windowWidth - 4, 4, message)
  gui.setElementAutoWordWrap(msgLabel, true)
  wm.addElement(window, msgLabel)
  wm.addElement(window, gui.newLine(1, 8, windowWidth - 4))
  
  local CloseButton = gui.newButton(math.floor(windowWidth/2) - 3, windowHeight - 1, 7, 1, "close", function() wm.closeWindow(window) end)
  wm.addElement(window, CloseButton)

  wm.raiseWindow(window)

end


local modemPacketsSend = 0
local modemPacketsReceive = 0
local modemPacketsSendSize = 0
local modemPacketsReceiveSize = 0

function networkdriver.modemSend(addr, port, ...)
  local message = { ... }
  for i = 1, #message do
    if type(message[i]) == "boolean" or type(message[i]) == "nil" then
      modemPacketsSendSize = modemPacketsSendSize + 6
    end
    if type(message[i]) == "string" then
      modemPacketsSendSize = modemPacketsSendSize + string.len(message[i]) + 2
    end
    if type(message[i]) == "number" then
      modemPacketsSendSize = modemPacketsSendSize + 10
    end
  end
  modemPacketsSend = modemPacketsSend + 1
  modem.send(addr, port, ...)
end

function networkdriver.modemBroadcast(port, ...)
  local message = { ... }
  for i = 1, #message do
    if type(message[i]) == "boolean" or type(message[i]) == "nil" then
      modemPacketsSendSize = modemPacketsSendSize + 6
    end
    if type(message[i]) == "string" then
      modemPacketsSendSize = modemPacketsSendSize + string.len(message[i]) + 2
    end
    if type(message[i]) == "number" then
      modemPacketsSendSize = modemPacketsSendSize + 10
    end
  end
  modemPacketsSend = modemPacketsSend + 1
  modem.broadcast(port, ... )
end

local function modemReceiveCallback(_, _, from, port, distance, ...)
  local message = { ... }
  for i = 1, #message do
    if type(message[i]) == "boolean" or type(message[i]) == "nil" then
      modemPacketsReceiveSize = modemPacketsReceiveSize + 6
    end
    if type(message[i]) == "string" then
      modemPacketsReceiveSize = modemPacketsReceiveSize + string.len(message[i]) + 2
    end
    if type(message[i]) == "number" then
      modemPacketsReceiveSize = modemPacketsReceiveSize + 10
    end
  end
  modemPacketsReceive = modemPacketsReceive + 1
  
  if port == messagePort then
    if message[2] then
      displayMessageWindow(message[2], message[1])
    else
      displayMessageWindow(from, message[1])
    end
  end
  
  
  if port == internalPort then
    if message[1] == "PING" then
      networkdriver.modemSend(from, internalPort, "PONG")
    end
    if message[1] == "GET USER" then
	networkdriver.modemSend(from, internalPort, "GIVE USER", wm.getUsername())
    end
    if message[1] == "GIVE USER" then
      local tmpTable = {}
      tmpTable.user = message[2]
      tmpTable.addr = from
--[[
      for i = 1, #userList do
	if userList[i] == message[2] then
	  num = i
	  break
	end
      end
      table.remove(userList, num)
]]--
      table.insert(userList, tmpTable)
    end
  end
end

function networkdriver.broadcastMessage(message)
  networkdriver.modemBroadcast(messagePort, message)
end


function networkdriver.getModemPackets()
  return modemPacketsSend, modemPacketsReceive, modemPacketsSendSize, modemPacketsReceiveSize
end

function networkdriver.getPort(service)
  for key, value in pairs(portList) do
    if key == service then
      return value
    end
  end
end

function networkdriver.openPort(service)
  for key, value in pairs(portList) do
    if key == service then
      if component.isAvailable("modem") == true then
	local modemPort = value
	modem = component.modem
	return modem.open(modemPort), value
      end
    end
  end
  return false
end

function networkdriver.clearUserList()
  userList = {}
end

function networkdriver.getUserList()
  return userList
end


function networkdriver.start()
  _, messagePort = networkdriver.openPort("message")
  _, internalPort = networkdriver.openPort("internal")
  wm.registerDriver("network", "A driver for modems that collects traffic usage informations", "S.Kempa", version)
  event.listen("modem_message", modemReceiveCallback)
end

function networkdriver.stop()
  event.ignore("modem_message", modemReceiveCallback)
end

return networkdriver

