local component = require("component")
local ser = require("serialization")
local gpu = component.gpu
local event = require("event")
local filesystem = require("filesystem")
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
--local networkdriver = require("windowmanager/driver/networkdriver")

local ScreenWidth, ScreenHeight = gpu.getResolution()


local printServer = {}

local version = "1.0"
--// exportstring( string )
--// returns a "Lua" portable version of the string
function exportstring( s )
	s = string.format( "%q",s )
	-- to replace
	s = string.gsub( s,"\\\n","\\n" )
	s = string.gsub( s,"\r","\\r" )
	s = string.gsub( s,string.char(26),"\"..string.char(26)..\"" )
	return s
end
--// The Save Function
function saveTable(tbl,filename )
	local charS,charE = "   ","\n"
	local file,err
	-- create a pseudo file that writes to a string and return the string
	if not filename then
		file =  { write = function( self,newstr ) self.str = self.str..newstr end, str = "" }
		charS,charE = "",""
	-- write table to tmpfile
	elseif filename == true or filename == 1 then
		charS,charE,file = "","",io.tmpfile()
	-- write table to file
	-- use io.open here rather than io.output, since in windows when clicking on a file opened with io.output will create an error
	else
		file,err = io.open( filename, "w" )
		if err then 
		  print ("Gui-lib: Error saving table " .. filename .." -> " .. err)
		  return _,err 
		end
	end
	-- initiate variables for save procedure
	local tables,lookup = { tbl },{ [tbl] = 1 }
	file:write( "return {"..charE )
	for idx,t in ipairs( tables ) do
		if filename and filename ~= true and filename ~= 1 then
			file:write( "-- Table: {"..idx.."}"..charE )
		end
		file:write( "{"..charE )
		local thandled = {}
		for i,v in ipairs( t ) do
			thandled[i] = true
			-- escape functions and userdata
			if type( v ) ~= "userdata" then
				-- only handle value
				if type( v ) == "table" then
					if not lookup[v] then
						table.insert( tables, v )
						lookup[v] = #tables
					end
					file:write( charS.."{"..lookup[v].."},"..charE )
				elseif type( v ) == "function" then
					file:write( charS.."loadstring("..exportstring(string.dump( v )).."),"..charE )
				else
					local value =  ( type( v ) == "string" and exportstring( v ) ) or tostring( v )
					file:write(  charS..value..","..charE )
				end
			end
		end
		for i,v in pairs( t ) do
			-- escape functions and userdata
			if (not thandled[i]) and type( v ) ~= "userdata" then
				-- handle index
				if type( i ) == "table" then
					if not lookup[i] then
						table.insert( tables,i )
						lookup[i] = #tables
					end
					file:write( charS.."[{"..lookup[i].."}]=" )
				else
					local index = ( type( i ) == "string" and "["..exportstring( i ).."]" ) or string.format( "[%d]",i )
					file:write( charS..index.."=" )
				end
				-- handle value
				if type( v ) == "table" then
					if not lookup[v] then
						table.insert( tables,v )
						lookup[v] = #tables
					end
					file:write( "{"..lookup[v].."},"..charE )
				elseif type( v ) == "function" then
					file:write( "loadstring("..exportstring(string.dump( v )).."),"..charE )
				else
					local value =  ( type( v ) == "string" and exportstring( v ) ) or tostring( v )
					file:write( value..","..charE )
				end
			end
		end
		file:write( "},"..charE )
	end
	file:write( "}" )
	-- Return Values
	-- return stringtable from string
	if not filename then
		-- set marker for stringtable
		return file.str.."--|"
	-- return stringttable from file
	elseif filename == true or filename == 1 then
		file:seek ( "set" )
		-- no need to close file, it gets closed and removed automatically
		-- set marker for stringtable
		return file:read( "*a" ).."--|"
	-- close file and return 1
	else
		file:close()
		return 1
	end
end
 
--// The Load Function
function loadTable( sfile )
	local tables, err, _

	-- catch marker for stringtable
	if string.sub( sfile,-3,-1 ) == "--|" then
		tables,err = loadstring( sfile )
	else
		tables,err = loadfile( sfile )
	end
	if err then 
	  print("Gui-lib: Error loading table " ..sfile .. " -> " ..err)
	  return _,err
	end
	tables = tables()
	for idx = 1,#tables do
		local tolinkv,tolinki = {},{}
		for i,v in pairs( tables[idx] ) do
			if type( v ) == "table" and tables[v[1]] then
				table.insert( tolinkv,{ i,tables[v[1]] } )
			end
			if type( i ) == "table" and tables[i[1]] then
				table.insert( tolinki,{ i,tables[i[1]] } )
			end
		end
		-- link values, first due to possible changes of indices
		for _,v in ipairs( tolinkv ) do
			tables[idx][v[1]] = v[2]
		end
		-- link indices
		for _,v in ipairs( tolinki ) do
			tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
		end
	end
	return tables[1]
end

local selectedPrinter = 0

local Printer = {}
Printer.__index = Printer
local PrinterList = {}


function Printer:New(name, addr, typ, position)
  pr = setmetatable({
    name = name or "",
    addr = addr or "",
    typ = typ or 0,
    position = position or "",
    description = "",
    shared = false,
    isStandard = false,
    proxy = nil,
  },Printer)
  table.insert(PrinterList, pr)
  return pr
end

function printServer.addPrinter(name, addr, typ, position)
  local self = Printer:New(name, addr, typ, position)
  self.proxy = component.proxy(addr)
  saveTable(PrinterList, "/etc/windowmanager/printserver.dat")
  return self
end

local function addLocalPrinter()
  for addr,v in component.list("openprinter") do 
    printServer.addPrinter(v, addr, 0)
  end
  PrinterList[1].isStandard = true
end

function removePrinter(id)
  table.remove(PrinterList, id)
  saveTable(PrinterList, "/etc/windowmanager/printserver.dat")
end

function printServer.getLocalPrinter()
  local tmpTable = {}
  for addr,v in component.list("openprinter") do 
    table.insert(tmpTable, addr)
  end
  return tmpTable
end

function printServer.getStandardPrinter()
  for i = 1, #PrinterList do
    if PrinterList[i].isStandard == true then
      selectedPrinter = i
      return PrinterList[i]
    end
  end
end

function printServer.setName(id, txt)
  PrinterList[id].name = txt
  saveTable(PrinterList, "/etc/windowmanager/printserver.dat")
end

function printServer.setLocation(id, txt)
  PrinterList[id].position = txt
  saveTable(PrinterList, "/etc/windowmanager/printserver.dat")
end

function printServer.setDescription(id, txt)
  PrinterList[id].description = txt
  saveTable(PrinterList, "/etc/windowmanager/printserver.dat")
end

function printServer.setNetworkShare(id, state)
  PrinterList[id].shared = state
  saveTable(PrinterList, "/etc/windowmanager/printserver.dat")
end

function printServer.getName(id)
  return PrinterList[id].name
end

function printServer.getLocation(id)
  return PrinterList[id].position
end

function printServer.getDescription(id)
  return PrinterList[id].description
end

function printServer.getNetworkShare(id)
  return PrinterList[id].shared
end

function printServer.getPrinterList()
  return PrinterList
end


-- FIXME: has to be changed to loading list
--addLocalPrinter()


local function showPrinterList()
  for i = 1, #PrinterList do
    if PrinterList[i].isStandard == true then
      print(ser.serialize(PrinterList[i]))
    end
  end
end

local modem = nil
local modemPort = 0

local ScreenWidth, ScreenHeight = gpu.getResolution()


local color={}
color.black=0x000000
color.gray=0xA9A9A9
color.lightBlue=0x808080
color.white=0xFFFFFF
color.magenta=0xFF00FF
color.yellow=0xFFFF00
color.green=0x00FF00
color.darkGreen=0x008000
color.blue=0x0000ff
color.red=0xFF0000
color.orange=0xFFA500
color.brown=0xA52A2A
color.lightRed=0xF00000
color.darkGray=0x202020

-- screen colors
local Color = {}
Color.TopLineBackground = color.darkGray
Color.RunningDot = color.green


local waitingTime = 3

-- table to store all print jobs
local printJobList = {["id"] = 0}

-- tmp table for a print job
local printJobTable = {}
printJobTable.__index = printJobTable

function printJobTable:New(title, data, addr, printerID)
  pj = setmetatable ({
    id = printJobList.id,
    title = title or "no title",
    data = data or {},
    pages = 1,
    page = 1,
    status = "idle",
    line = 1,				-- what line is printed
    printerID = printerID or 1,		-- id of the printer in list
  },printJobTable)
  printJobList.id = printJobList.id + 1
  table.insert(printJobList, pj)
  return pj
end


function printServer.newPrintjob(title, data, netAddress, printerID)
  if not printerID then
    printerID = printServer.showSelectPrinterDialog()
  end
  if netAddress then
    ret = printJobTable:New(title, data, netAddress, printerID)
    ret.pages = math.ceil(#ret.data/20)
--    networkdriver.modemSend(netAddress, modemPort, ret.id)
  else
    ret = printJobTable:New(title, data, nil, printerID)
    ret.pages = math.ceil(#ret.data/20)
    return ret 
  end
end

function printServer.printJobInsertLine(job, text)
  table.insert(job.data, text)
  job.pages = math.ceil(#job.data/20)
end

local function splitWords(Lines, limit)
    while #Lines[#Lines] > limit do
        Lines[#Lines+1] = Lines[#Lines]:sub(limit+1)
        Lines[#Lines-1] = Lines[#Lines-1]:sub(1,limit)
    end
end
local function wrap(str, limit)
    local Lines, here, limit, found = {}, 1, limit or 72, str:find("(%s+)()(%S+)()")
    if found then
        Lines[1] = string.sub(str,1,found-1)  -- Put the first word of the string in the first index of the table.
    else Lines[1] = str end
    str:gsub("(%s+)()(%S+)()",
        function(sp, st, word, fi)  -- Function gets called once for every space found.
            splitWords(Lines, limit)

            if fi-here > limit then
                here = st
                Lines[#Lines+1] = word                                             -- If at the end of a line, start a new table index...
            else Lines[#Lines] = Lines[#Lines].." "..word end  -- ... otherwise add to the current table index.
        end)
    splitWords(Lines, limit)

    return Lines
end

function printServer.printJobInsertText(job, text)
  local t = wrap(text, 31)
  for i = 1, #t do
    table.insert(job.data, t[i])
  end
  job.pages = math.ceil(#job.data/20)
end


local function printPage(job)
  if job.page <= job.pages then
    local printer = PrinterList[job.printerID].proxy
    job.status = "printing"
    local start = (job.page * 20) - 19
    printer.clear()
    printer.setTitle(job.title .. "(" .. tostring(job.page) .. ")")
    for i = start, start + 19 do		-- 20 lines per page
      if i <= #job.data then		-- end of table not reached
	printer.writeln(job.data[i])
      end
    end
    
    if printer.getBlackInkLevel() == false then
      job.status = "stopped"
      return
    end
    if printer.getPaperLevel() == false then
      job.status = "stopped"
      return
    end
    if printer.getColorInkLevel() == false then
      job.status = "stopped"
      return
    end
    
    if printer.print() ~= true then
      job.status = "stopped"
      return
    end
    job.page = job.page + 1
  end
  if job.page > job.pages then
    job.status = "finished"
  end
end


function printServer.getPrintJobs(netAddress)
--  gpu.set(1,1,"giving jobs")
  local tmpTable = {}
  local jobList = {}
  for i = 1, #printJobList do
    tmpTable = {}
    tmpTable.id = printJobList[i].id
    tmpTable.title = printJobList[i].title
    tmpTable.page = printJobList[i].page - 1
    tmpTable.pages = printJobList[i].pages
    tmpTable.addr = printJobList[i].addr
    tmpTable.status = printJobList[i].status
    tmpTable.printerID = printJobList[i].printerID
    table.insert(jobList, tmpTable)
  end
  if netAddress then
--   networkdriver.modemSend(netAddress, modemPort, ser.serialize(jobList))
  end
  return jobList
end

function printServer.getPrinterStatus(netAddress, printerID)
  local tmpTable = {}
  if component.isAvailable("openprinter") == false then
    if netAddress then
      tmpTable.ret = false
      tmpTable.addr = ""
      tmpTable.colorInk = 0
      tmpTable.blackInk = 0
      tmpTable.paper = 0
--      networkdriver.modemSend(netAddress, modemPort, ser.serialize(tmpTable))
    end
    return false, "", 0, 0, 0, "No printer conected"
  end
  if not printerID then
    printerID = printServer.showSelectPrinterDialog()
  end
  local printer = PrinterList[printerID].proxy
  local addr = printer.address
  local colorInk = printer.getColorInkLevel()
  local blackInk = printer.getBlackInkLevel()
  local paper = printer.getPaperLevel()
  tmpTable.addr = addr
  tmpTable.colorInk = colorInk
  tmpTable.blackInk = blackInk
  tmpTable.paper = paper
  if colorInk == false then
    if netAddress then
      tmpTable.ret = false
      tmpTable.status = "Out of color ink"
--      networkdriver.modemSend(netAddress, modemPort, ser.serialize(tmpTable))
    end
    return false, addr, colorInk, blackInk, paper, "Out of color ink"
  end
  if blackInk == false then
    if netAddress then
      tmpTable.ret = false
      tmpTable.status = "Out of black ink"
--      networkdriver.modemSend(netAddress, modemPort, ser.serialize(tmpTable))
    end
    return false, addr, colorInk, blackInk, paper, "Out of black ink"
  end
  if paper == false then
    if netAddress then
      tmpTable.ret = false
      tmpTable.status = "Out paper"
--      networkdriver.modemSend(netAddress, modemPort, ser.serialize(tmpTable))
    end
    return false, addr, colorInk, blackInk, paper, "Out of paper"
  end
  if netAddress then
      tmpTable.ret = true
      tmpTable.status = "ready"
--    networkdriver.modemSend(netAddress, modemPort, ser.serialize(tmpTable))
  end
  return true, addr, colorInk, blackInk, paper, "ready"
end

function printServer.cancelPrintJob(job)
  job.status = "canceled"
end

function printServer.resumePrintJob(job)
  job.status = "waiting"
end

function printServer.print(job, netAddress)
  job.status = "waiting"
end

function printServer.isPrinting()
  for i = 1, #printJobList do
    if printJobList[i].status == "printing" then
      return true
    end
  end
  return false
end


function showJobs()
  j = printServer.getPrintJobs()
  for i = 1, #j do
    print(string.format("id: %-5d title: %-20s pages: %4d  status: %s %d",j[i].id, j[i].title, j[i].pages, j[i].addr, j[i].status, j[i].printerID))
  end
end

function printServer.setPrinterTimeout(t)
  waitingTime = t
end

function printServer.getPrinterTimeout()
  return waitingTime
end

function printServer.printText(title, text)
  local ps = printServer.showSelectPrinterDialog()
  local job = printServer.newPrintjob(title, nil, nil, ps)
  printServer.printJobInsertText(job, text)
  printServer.print(job)
end




local printTimer = nil

local function printTimerCallback()
  for p = 1, #PrinterList do
    if printServer.getPrinterStatus(nil, p) == true then
      for i = 1, #printJobList do
	if printJobList[i].printerID == p and printJobList[i].status ~= "finished" and printJobList[i].status ~= "canceled" and printJobList[i].status ~= "idle" then
	  printPage(printJobList[i])
	  break
	end
      end
    end
  end
end

--[[
local function openModem()
  if component.isAvailable("modem") == true then
    _, modemPort = networkdriver.openPort("printserver")
  end
end

local function modemReceiveCallback(_, addr, from, port, distance, ...)
  local message = { ... }
  if message[1] == "GET PRINTSERVER" and port == modemPort then
    networkdriver.modemSend(from, modemPort, "ok")
  end
  if message[1] == "GET PRINTERSTATUS" and port == modemPort then
    printServer.getPrinterStatus(from, message[2])
  end
  if message[1] == "GET PRINTJOBS" and port == modemPort then
    printServer.getPrintJobs(from)
  end
  if message[1] == "NEW PRINTJOB" and port == modemPort then
    printServer.newPrintjob(message[2], {}, from, message[3])
  end
  if message[1] == "INSERTLINE" and port == modemPort then
    for i = 1, #printJobList do
      if printJobList[i].id == message[2] then
	printServer.printJobInsertLine(printJobList[i], message[3])
	networkdriver.modemSend(from, modemPort, "ok")
	break
      end
    end
  end
  if message[1] == "PRINT" and port == modemPort then
    for i = 1, #printJobList do
      if printJobList[i].id == message[2] then
	printServer.print(printJobList[i], from)
	networkdriver.modemSend(from, modemPort, "ok")
	break
      end
    end
  end
end
]]--

function printServer.start()
  if filesystem.exists("/etc/windowmanager/printserver.dat") == true then
    local List = loadTable("/etc/windowmanager/printserver.dat")
    for i = 1, # List do
       printServer.addPrinter(List[i].name, List[i].addr, List[i].typ, List[i].position)
       printServer.setDescription(i, List[i].description)
       printServer.setNetworkShare(i, List[i].shared)
    end
--    print(ser.serialize(List))
  end

--  openModem()
  wm.registerDriver("printer", "A driver for using multiple printer from openprinter mod", "S.Kempa", version)
  printTimer = event.timer(waitingTime, printTimerCallback, math.huge)
--  event.listen("modem_message", modemReceiveCallback)
end

function printServer.stop()
  event.cancel(printTimer)
--  event.ignore("modem_message", modemReceiveCallback)
end

local List = {}
local printerList
local printerSlider
local selectPrinterRunning
local PrinterListWindow 
local selectedPrinter = 1

  

function printServer.showSelectPrinterDialog(fromManager)
  List = printServer.getPrinterList()
  if #List == 0 then  
    return -1
  end
  selectPrinterRunning = true
  
  PrinterListWindow = wm.newWindow(math.floor(ScreenWidth/2) - 20, math.floor(ScreenHeight/2) - 8, 40, 12, "Select printer")
  wm.hideWindow(PrinterListWindow, true)
  wm.setWindowSticky(PrinterListWindow, true)
  wm.disableWindowButtons(PrinterListWindow, true)

  printerList = gui.newList(2, 2, 35, 3, "", function() selectedPrinter = gui.getElementSelected(printerList) gui.setElementValue(printerSlider, selectedPrinter) gui.drawElement(PrinterListWindow, printerSlider) end)
  wm.addElement(PrinterListWindow, printerList)
  gui.setElementBackground(printerList, 0xFFFFFF)
  gui.setElementActiveBackground(printerList, 0x202020)
  gui.setElementForeground(printerList, 0x000000)
  gui.setElementActiveForeground(printerList, 0xFFFFFF)

  for i = 1, #List do
    gui.insertElementData(printerList, List[i].addr)
  end
    
  printerSlider = gui.newVSlider(37, 2, 3, function() selectedPrinter = gui.getElementValue(printerSlider) gui.setElementSelected(printerList, selectedPrinter) gui.drawElement(PrinterListWindow, printerList) end)
  gui.setElementMin(printerSlider, 1)
  gui.setElementValue(printerSlider, 1)
  gui.setElementMax(printerSlider, #List)
  wm.addElement(PrinterListWindow, printerSlider)

  wm.addElement(PrinterListWindow, gui.newLine(1, 5, 38))
  
  wm.addElement(PrinterListWindow, gui.newLabel(2,  6, 14, 1, "Name        : "))
  wm.addElement(PrinterListWindow, gui.newLabel(2,  7, 25, 1, "Type        : "))
  wm.addElement(PrinterListWindow, gui.newLabel(2,  8, 14, 1, "Location    : "))
  wm.addElement(PrinterListWindow, gui.newLabel(2,  9, 14, 1, "Description : "))
  labelName = gui.newLabel(16,  6, 20, 1, "")
  wm.addElement(PrinterListWindow, labelName)
  labelType = gui.newLabel(16,  7, 20, 1, "")
  wm.addElement(PrinterListWindow, labelType)
  labelLocation = gui.newLabel(16, 8, 20, 1, "")
  wm.addElement(PrinterListWindow, labelLocation)
  labelDescription = gui.newLabel(16, 9, 20, 1, "")
  wm.addElement(PrinterListWindow, labelDescription)
  
  wm.addElement(PrinterListWindow, gui.newLine(1, 10, 38))
  
  local PrinterListOkButton = gui.newButton(2, 11, 4, 1, "ok", function()wm.closeWindow(PrinterListWindow) selectPrinterRunning = false end)
  wm.addElement(PrinterListWindow, PrinterListOkButton)
  
  local PrinterListCancelButton = gui.newButton(7, 11, 8, 1, "cancel", function()wm.closeWindow(PrinterListWindow) selectPrinterRunning = false selectedPrinter = 0 end)
  wm.addElement(PrinterListWindow, PrinterListCancelButton)
  
  if fromManager == true then
    local PrinterNewButton = gui.newButton(16, 11, 13, 1, "new printer", function()wm.closeWindow(PrinterListWindow) selectPrinterRunning = false selectedPrinter = -1 end)
    wm.addElement(PrinterListWindow, PrinterNewButton)

    local PrinterRemoveButton = gui.newButton(30, 11, 8, 1, "remove", function()removePrinter(gui.getElementValue(printerSlider)) wm.closeWindow(PrinterListWindow) selectPrinterRunning = false selectedPrinter = 0 end)
    wm.addElement(PrinterListWindow, PrinterRemoveButton)
  end
  
  wm.raiseWindow(PrinterListWindow)
  while selectPrinterRunning == true do
    
    gui.setElementText(labelName, List[selectedPrinter].name)
    gui.drawElement(PrinterListWindow, labelName)
    if List[selectedPrinter].typ == 0 then
      gui.setElementText(labelType, "Local printer")
    else
      gui.setElementText(labelType, "Network printer")
    end
    gui.drawElement(PrinterListWindow, labelType)
    gui.setElementText(labelLocation, List[selectedPrinter].position)
    gui.drawElement(PrinterListWindow, labelLocation)
    gui.setElementText(labelDescription, List[selectedPrinter].description)
    gui.drawElement(PrinterListWindow, labelDescription)
    os.sleep(0.00001)
  end
  
  return selectedPrinter
end
return printServer
