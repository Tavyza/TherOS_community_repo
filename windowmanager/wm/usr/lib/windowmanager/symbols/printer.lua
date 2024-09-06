local component = require("component")
local gpu = component.gpu
local modem = component.modem
local event = require("event")
local unicode = require("unicode")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local printserver = require("windowmanager/driver/printserver")


-- Program parameters
local programName = "Print manager"
local releaseYear = "2017"
local versionMajor = 1
local versionMinor = 0
local author = "S.Kempa"
local windowWidth = 60
local windowHeight = 21
local hideWindowFromList = true


local ScreenWidth, screenHeight = gpu.getResolution()
local args = {...}
local myID = args[1]
local myIcon = args[4]

local running = true

local selectedPrinter = 0

-- Function that will called, if one of the exit buttons is clicked
local function exitButtonCallback(self, win)
  running = false
  wm.closeWindow(win)
  wm.setRunningState(myID, false)
end


local function listSliderCallback(self, win)
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.set(1,25, tostring(gui.getElementValue(self)))
  gui.setElementSelected(printQList, gui.getElementValue(self))
  gui.drawElement(window, printQList)
end

local function inputNameCallback(self, win)
  printserver.setName(selectedPrinter, gui.getElementText(self))
end

local function inputLocationCallback(self, win)
  printserver.setLocation(selectedPrinter, gui.getElementText(self))
end

local function inputDesriptionCallback(self, win)
  printserver.setDescription(selectedPrinter, gui.getElementText(self))
end

local function shareCheckboxCallback(self, win)
  printserver.setNetworkShare(selectedPrinter, gui.getElementState(self))
end

local function cancelButtonCallback(self, win)
  running = false
  wm.closeWindow(win)
  wm.setRunningState(myID, false)
end

local List = {}
local printQSlider, printQList

local function okButtonCallback(self, win)
  printserver.addPrinter("new printer", List[gui.getElementValue(printQSlider)], 0)
  running = false
  wm.closeWindow(win)
  selectedPrinter = printserver.showSelectPrinterDialog(true)
end

local function installNewPrinter()
  List = printserver.getLocalPrinter()
  windowHeight = 10
  wm.setRunningState(myID, true)
  
  window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(screenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight,  "Install new printer")
  wm.hideWindow(window, hideWindowFromList)
-- wm.setWindowSticky(window, true)
  wm.disableWindowButtons(window, true)

  printQList = gui.newList(2, 2, windowWidth - 5, 5, "", function() gui.setElementValue(printQSlider, gui.getElementSelected(printQList)) end)
  wm.addElement(window, printQList)
  gui.setElementBackground(printQList, 0xFFFFFF)
  gui.setElementActiveBackground(printQList, 0x202020)
  gui.setElementForeground(printQList, 0x000000)
  gui.setElementActiveForeground(printQList, 0xFFFFFF)

  for i = 1, #List do
    gui.insertElementData(printQList, List[i])
  end
    
  printQSlider = gui.newVSlider(windowWidth - 3, 2, 5, function() gui.setElementSelected(printQList, gui.getElementValue(printQSlider)) end)
  gui.setElementMin(printQSlider, 1)
  gui.setElementMax(printQSlider, #List)
  gui.setElementValue(printQSlider, 1)
  wm.addElement(window, printQSlider)
  
  local windowOkButton = gui.newButton(3, windowHeight - 1, 4, 1, "ok", okButtonCallback)
  wm.addElement(window, windowOkButton)

  local windowCancelButton = gui.newButton(16, windowHeight - 1, 6, 1, "cancel", cancelButtonCallback)
  wm.addElement(window, windowCancelButton)

  wm.raiseWindow(window)

    while running == true do
	
	if wm.getActiveWindow() == window then					-- prevent window from updating, if it is not the top windows
	  gui.drawElement(window, printQList)
	  gui.drawElement(window, printQSlider)
	end
	os.sleep(0.1)
    end

end

if args[2] == "load" then

elseif args[2] == "unload" then
 
  
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
  local infoExitButton = gui.newButton(13, 9, 6, 1, "exit", exitButtonCallback)
  wm.addElement(infoWindow, infoExitButton)
  wm.raiseWindow(infoWindow)
elseif args[2] == "execute" and args[3] == 0 then
    selectedPrinter = printserver.showSelectPrinterDialog(true)
    if selectedPrinter == -1 then
      installNewPrinter()
    end
  if selectedPrinter <= 0 then
    return
  end
  wm.setRunningState(myID, true)
  running = true
  
  local printQList, printQSlider
  
  windowHeight = 21
  window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(screenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight,  programName)
  wm.hideWindow(window, hideWindowFromList)
--  wm.setWindowSticky(window, true)
  wm.disableWindowButtons(window, true)

  local printerStatus, printerAddress, colorLevel, blackLevel, paperLevel = printserver.getPrinterStatus(nil, selectedPrinter)
--  if printerStatus == true then
    local printerAddressLabel = gui.newLabel(2, 2, windowWidth - 2, 1, string.format("Printer address  : %s", printerAddress))
    gui.setElementAlignment(printerAddressLabel, "left")
    wm.addElement(window, printerAddressLabel)

    wm.addElement(window, gui.newLine(1, 3, windowWidth))
  
    wm.addElement(window, gui.newLabel(2,  5, 14, 1, "Name        : "))
    wm.addElement(window, gui.newLabel(2,  7, 14, 1, "Location    : "))
    wm.addElement(window, gui.newLabel(2,  9, 14, 1, "Description : "))
    
    local inputName = gui.newInput(16, 5, 41, "", inputNameCallback)
    wm.addElement(window, inputName)
    local inputLocation = gui.newInput(16, 7, 41, "", inputLocationCallback)
    wm.addElement(window, inputLocation)
    local inputDescription = gui.newInput(16, 9, 41, "", inputDesriptionCallback)
    wm.addElement(window, inputDescription)

    gui.setElementText(inputName, printserver.getName(selectedPrinter))
    gui.setElementText(inputLocation, printserver.getLocation(selectedPrinter))
    gui.setElementText(inputDescription, printserver.getDescription(selectedPrinter))

    local shareCheckbox = gui.newCheckbox(2, 11, "Share on network ", shareCheckboxCallback)
    gui.setElementState(shareCheckbox, printserver.getNetworkShare(selectedPrinter))
    wm.addElement(window, shareCheckbox)

    wm.addElement(window, gui.newLine(1, 12, windowWidth))

    if colorLevel == false then
      colorLevel = 0
    else
      colorLevel = math.floor(100/4000*colorLevel)
    end
    local colorLevelLabel = gui.newLabel(5, 13, 10, 1, "Color ink")
    wm.addElement(window, colorLevelLabel)
    colorLevelBar = gui.newHBar(15, 13, 12, 1)
    gui.setElementMax(colorLevelBar, 100)
    gui.setElementMin(colorLevelBar, 0)
    gui.setElementValue(colorLevelBar, colorLevel)
    wm.addElement(window, colorLevelBar)

    if blackLevel == false then
      blackLevel = 0
    else
      blackLevel = math.floor(100/4000*blackLevel)
    end
    local blackLevelLabel = gui.newLabel(32, 13, 10, 1, "Black ink")
    wm.addElement(window, blackLevelLabel)
    blackLevelBar = gui.newHBar(42, 13, 12, 1)
    gui.setElementMax(blackLevelBar, 100)
    gui.setElementMin(blackLevelBar, 0)
    gui.setElementValue(blackLevelBar, blackLevel)
    wm.addElement(window, blackLevelBar)

    if paperLevel == false then
      paperLevel = 0
    end
    paperLevelLabel = gui.newLabel(5, 14, 10, 1, string.format("Paper %d", paperLevel))
    wm.addElement(window, paperLevelLabel)

    errorLabel = gui.newLabel(20, 14, 40, 1, "")
    wm.addElement(window, errorLabel)

    wm.addElement(window, gui.newLine(1, 15, windowWidth))

    -- we use a list for the print q :-) 
    printQList = gui.newList(2, 16, windowWidth - 5, 3, "", function() gui.setElementValue(printQSlider, gui.getElementSelected(printQList)) end)
    wm.addElement(window, printQList)
    gui.setElementBackground(printQList, 0xFFFFFF)
    gui.setElementActiveBackground(printQList, 0x202020)
    gui.setElementForeground(printQList, 0x000000)
    gui.setElementActiveForeground(printQList, 0xFFFFFF)

    
    printQSlider = gui.newVSlider(windowWidth - 3, 16, 3, function() gui.setElementSelected(printQList, gui.getElementValue(printQSlider)) end)
    gui.setElementMin(printQSlider, 1)
    gui.setElementMax(printQSlider, 1)
    gui.setElementValue(printQSlider, 1)
    wm.addElement(window, printQSlider)

    local windowExitButton = gui.newButton(math.floor(windowWidth/2) - 4, windowHeight - 1, 7, 1, "close", exitButtonCallback)
    wm.addElement(window, windowExitButton)

    wm.raiseWindow(window)
  
    while running == true do
      printerStatus, printerAddress, colorLevel, blackLevel, paperLevel, status = printserver.getPrinterStatus(nil, selectedPrinter)
      if printerStatus == true then
	gui.setElementForeground(errorLabel, 0x000000)
      else
	gui.setElementForeground(errorLabel, 0xFF0000)
      end
      gui.setElementText(errorLabel, "Printer msg: " .. status)
      gui.setElementText(printerAddressLabel, string.format("Printer address  : %s", printerAddress))
      if colorLevel == false then
	colorLevel = 0
      else
	colorLevel = math.floor(100/4000*colorLevel)
      end
      gui.setElementValue(colorLevelBar, colorLevel)
      if blackLevel == false then
	blackLevel = 0
      else
	blackLevel = math.floor(100/4000*blackLevel)
      end
      gui.setElementValue(blackLevelBar, blackLevel)
      if paperLevel == false then
	paperLevel = 0
      end
      gui.setElementText(paperLevelLabel, string.format("Paper %d", paperLevel))
	gui.clearElementData(printQList)
	j = printserver.getPrintJobs()
	for i = 1, #j do
	  if j[i].printerID == selectedPrinter then
	    t = string.format(" %-5d  %-10s  %3d/%-3d %-8s", j[i].id, j[i].title, j[i].page, j[i].pages, j[i].status)
	    gui.insertElementData(printQList, t)
	  end
	end
	gui.setElementMax(printQSlider, #j)
	
	if wm.getActiveWindow() == window then					-- prevent window from updating, if it is not the top windows
	  gui.drawElement(window, printerAddressLabel)
	  gui.drawElement(window, colorLevelBar)
	  gui.drawElement(window, blackLevelBar)
	  gui.drawElement(window, paperLevelLabel)
	  gui.drawElement(window, errorLabel)
	  gui.drawElement(window, printQList)
	  gui.drawElement(window, printQSlider)
	end
	os.sleep(0.1)
    end
    wm.setRunningState(myID, false)
end

