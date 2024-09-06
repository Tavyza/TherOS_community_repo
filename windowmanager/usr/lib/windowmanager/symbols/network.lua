local component = require("component")
local gpu = component.gpu
local modem = component.modem
local event = require("event")
local unicode = require("unicode")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local networkdriver = require("windowmanager/driver/networkdriver")

-- Program parameters
local programName = "Network"
local releaseYear = "2017"
local versionMajor = 1
local versionMinor = 1
local author = "S.Kempa"
local windowWidth = 60
local windowHeight = 11
local hideWindowFromList = true


local ScreenWidth, screenHeight = gpu.getResolution()
local args = {...}
local myID = args[1]
local myIcon = args[4]

local running = true


local function modemReceiveCallback(_, _, from, port, distance, ...)
  wm.drawSymbol(myID, 0x00FF00)
  os.sleep(0.2)
  wm.drawSymbol(myID)
end

if args[2] == "load" then
  event.listen("modem_message", modemReceiveCallback)

elseif args[2] == "unload" then
  event.ignore("modem_message", modemReceiveCallback)
  
  
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
  local infoExitButton = gui.newButton(13, 9, 6, 1, "exit", function() running = false wm.closeWindow(infoWindow) wm.setRunningState(myID, false) end)
  wm.addElement(infoWindow, infoExitButton)
  wm.raiseWindow(infoWindow)
elseif args[2] == "execute" and args[3] == 0 then
  wm.setRunningState(myID, true)
  local window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(screenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight,  programName)
  wm.hideWindow(window, hideWindowFromList)
--  wm.setWindowSticky(window, true)
  wm.disableWindowButtons(window, true)
  local modemAddress = gui.newLabel(1, 2, windowWidth - 2, 1, string.format("Modem address    : %s", modem.address))
  wm.addElement(window, modemAddress)
  local hline = gui.newLine(1, 3, windowWidth)
  wm.addElement(window, hline)
  local tmpText = ""
  if modem.isWireless() == true then
    tmpText = "wireless (strength : " .. tostring(modem.getStrength()) .. ")"
  else
    tmpText = "cable"
  end
  local modemType = gui.newLabel(1, 4, windowWidth - 2, 1, string.format("Modem type       : %s", tmpText))
  wm.addElement(window, modemType)
  local modemMaxPacketSize = gui.newLabel(1, 5, windowWidth - 2, 1, string.format("Max packet size  : %d", modem.maxPacketSize()))
  wm.addElement(window, modemMaxPacketSize)
  local modemSendCount, modemReceiveCount, modemSendSize, modemReceiveSize = networkdriver.getModemPackets()
  local modemPacketsSendLabel = gui.newLabel(1, 7, windowWidth - 2, 1, string.format("Packets send     : %5d (TX: %d Bytes)", modemSendCount, modemSendSize))
  wm.addElement(window, modemPacketsSendLabel)
  local modemPacketsReceiveLabel = gui.newLabel(1, 8, windowWidth - 2, 1, string.format("Packets received : %5d (RX: %d Bytes)", modemReceiveCount, modemReceiveSize))
  wm.addElement(window, modemPacketsReceiveLabel)
  

  local windowExitButton = gui.newButton(math.floor(windowWidth/2) - 4, windowHeight - 1, 7, 1, "close", function() running = false wm.closeWindow(window) wm.setRunningState(myID, false) end)
  wm.addElement(window, windowExitButton)
  
  
  wm.raiseWindow(window)
  
  while running == true do
    if wm.getActiveWindow() == window then					-- prevent window from updating, if it is not the top windows
      modemSendCount, modemReceiveCount, modemSendSize, modemReceiveSize = networkdriver.getModemPackets()
      gui.setElementText(modemPacketsSendLabel, string.format("Packets send     : %5d (TX: %d Bytes)", modemSendCount, modemSendSize))
      gui.setElementText(modemPacketsReceiveLabel, string.format("Packets received : %5d (RX: %d Bytes)", modemReceiveCount, modemReceiveSize))
      gui.drawElement(window, modemPacketsSendLabel)
      gui.drawElement(window, modemPacketsReceiveLabel)
    end
    os.sleep(0.5)
  end
  
end

