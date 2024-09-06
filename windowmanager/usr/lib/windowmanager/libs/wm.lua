local component = require("component")
local gpu = component.gpu
local event = require("event")
local unicode = require("unicode")
local computer = require("computer")

-- libthread from Zer0Galaxy found on openprograms.ru
local computer = require("computer")
computer.SingleThread = computer.pullSignal
--local thread = {}

local mainThread
local timeouts

local function MultiThread( _timeout )
  if coroutine.running()==mainThread then
    local mintime = _timeout or math.huge
    local co=next(timeouts)
    while co do
      if coroutine.status( co ) == "dead" then
        timeouts[co],co=nil,next(timeouts,co)
      else
        if timeouts[co] < mintime then mintime=timeouts[co] end
        co=next(timeouts,co)
      end
    end
    if not next(timeouts) then
      computer.pullSignal=computer.SingleThread
      computer.pushSignal("AllThreadsDead")
    end
    local event={computer.SingleThread(mintime)}
    local ok, param
    for co in pairs(timeouts) do
      ok, param = coroutine.resume( co, table.unpack(event) )
      if not ok then timeouts={} error( param )
      else timeouts[co] = param or math.huge end
    end
    return table.unpack(event)
  else
    return coroutine.yield( _timeout )
  end
end

function threadInit()
  mainThread=coroutine.running()
  timeouts={}
end



local wm = {}

function wm.threadCreate(f,...)
  computer.pullSignal=MultiThread
  local co=coroutine.create(f)
  timeouts[co]=math.huge
  local ok, param = coroutine.resume( co, ... )
  if not ok then timeouts={} error( param )
  else timeouts[co] = param or math.huge end
  return co
end




local versionMajor = 1
local versionMinor = 2
local versionState = "Release 1"


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
Color.ScreenBackground = color.lightBlue
Color.ScreenForeground = color.white
Color.TopLineBackground = color.darkGray
Color.TopLineForeground = color.white
Color.BottomLineBackground = color.darkGray
Color.BottomLineForeground = color.white
Color.BottomLineActive = color.red
Color.TopLineActive = color.red
Color.RunningDot = color.green

-- window colors
Color.WindowBackground = color.gray
Color.WindowForeground = color.black
Color.WindowActiveFrameBackground = color.blue
Color.WindowActiveFrameForeground = color.white
Color.WindowInactiveFrameBackground = color.magenta
Color.WindowInactiveFrameForeground = color.white
Color.Shadow = color.black
Color.Frame = color.white

--menu colors
Color.MenuBackground = color.darkGray
Color.MenuForeground = color.white
Color.MenuSelectedBackground = color.darkGreen
Color.MenuSelectedForeground = color.white
Color.startMenuBackground = color.darkGray
Color.startMenuForeground = color.white
Color.startMenuActiveBackground = color.darkGray
Color.startMenuActiveForeground = color.red
Color.systemMenuBackground = color.darkGray
Color.systemMenuForeground = color.white
Color.systemMenuActiveBackground = color.darkGray
Color.systemMenuActiveForeground = color.red

-- frames
local frame = {
  -- horizontal, vertical, left-top, right-top, left-bottom, right-bottom
  ["Flat"] = {0x0020, 0x0020, 0x0020, 0x0020, 0x0020, 0x0020},
  ["Double"] = {0x2550, 0x2551, 0x2554, 0x2557, 0x255A, 0x255D},
  ["Small"] = {0x2500, 0x2502, 0x250C, 0x2510, 0x2514, 0x2518},
  ["Bold"] = {0x2501, 0x2503, 0x0250F, 0x2513, 0x2517, 0x251B}
}

local windowFrame = frame.Bold 		-- standard frame for windows is double line
local useWindowShadows = true
local useBoxShadows = true

local menuFrame = frame.Small

local ScreenWidth, ScreenHeight = gpu.getResolution()

local blockMouse = false 

function wm.setBoxShadow(state)
  useBoxShadows = state
end

function wm.useShadows(state)
  useWindowShadows = state
end

function wm.getShadowState()
  return useWindowShadows
end

function wm.getShadowBoxed()
  return useBoxShadows
end

local userLevel = 100
local userName = ""

function wm.setUserLevel(level)
  userLevel = level
end

function wm.getUserLevel()
  return userLevel
end

function wm.getUsername()
  return userName
end

function wm.setUsername(name)
  userName = name
end

-- general functions

function clearScreen()
    gpu.setBackground(Color.ScreenBackground)
    gpu.setForeground(Color.ScreenForeground)
    gpu.fill(1, 2, ScreenWidth, ScreenHeight - 2, " ")
end

function drawScreen()
  gpu.setBackground(Color.TopLineBackground)
  gpu.setForeground(Color.TopLineForeground)
  gpu.fill(1, 1, ScreenWidth, 1, " ")
  gpu.setBackground(Color.BottomLineBackground)
  gpu.setForeground(Color.BottomLineForeground)
  gpu.fill(1, ScreenHeight, ScreenWidth, 1, " ")
end


-- gui elements
local Element = {}
Element.__index = Element

function Element:New(id, x, y, w, h, text, callback)
  element = setmetatable({
    id = id or "unknown",					-- id for identification of type, eg. label, button
    x = x or 1,
    y = y or 1,
    w = w or 1,
    h = h or 1,
    text = text,
    alignment = "left",
    autoWordWrap = false,
    protected = false,						-- use for inputs to set asterix as letter (password input)
    background = nil,
    foreground = nil,
    callback = callback or nil,					-- callback that's called when element is clicked
    drawCallback = nil,						-- callback for draw function
    handleCallback = nil,					-- callback for handling the element
    activeBackground = nil,  					-- colors for clicked
    activeForeground = nil, 
    isActive = false,
    max = 0,
    min = 0,
    value = 0,
    steps = 1,
    state = false,						-- can be used for checkboxes
    data = {},							-- used for element groups, like radio bottons
    selected = 1,						-- for selected elements in groups
    first = 1,
    last = 1,
    type = 1,							-- if there are differend types of the element, like lines (small or double)
    ignoreMouseBlock = false,					-- if set to true, element will ignore the mouse block function
    userData1 = {},
    userData2 = {},						-- extra space for user created elements
    userData3 = {},
  },Element)
  return element
end

local function correctPos(win, self)
  local x = self.x + win.x
  local y = self.y + win.y
  local w = self.w - 1
  local h = self.h
  
  while x + w > win.x + win.w - 1 do		-- element is too long
    w = w - 1
  end
  if w < 0 then
    w = 0
  end
  while y + h > win.y + win.h do		-- element is too long
    h = h - 1
  end
  if h < 0 then
    h = 0
  end
  return x, y, w, h
end


function checkElementTouch(x, y, b, win, self)
    for j = 1, #win.elements do
      if win.elements[j].isActive == true then
	return
      end
    end
  local sx, sy, sw, sh = correctPos(win, self)
  if x >= sx and x <= sx + sw  and x < win.x + win.w - 1 then
    if y >= sy and y <= sy + sh - 1 then
      if self.handleCallback then
	  if self.handleCallback(win, self, x, y, b) == false then	-- first the handle callback for further actions
	    return 							-- we get out, if the handle callback gives a false back. no user callback then
	  end
      end
      if self.callback then
	if blockMouse == false or self.ignoreMouseBlock == true then
	  self.callback(self, win)					-- second the user callback
	end
      end
    end
  end
end





-- for the window list menu
local windowListMenu = {}

-- Window stuff
local Window = {}
Window.__index = Window

local WindowList = {}


local function redrawAllWindows()
  for i = 1, #WindowList do
    if WindowList[i].lowered == false then-- don't display lowered windows
      WindowList[i]:draw()
    end
  end
end

local function resortWindows()
  for i = 1, #WindowList do
    WindowList[i].id  = i			-- resort the id values
  end
end

function Window:New(x, y, w, h, text)
  window = setmetatable({
  x = x,
  y = y + 1,		-- start under the top line
  w = w,
  h = h,
  text = text,
  id = #WindowList + 1,
  lowered = true,
  buffer = {},
  buffer2 = {},
  moving = false,
  elements = {},
  disableButtons = false,
  sticky = false,
  hide = false,
  onCloseCallback = nil,
  onLowerCallback = nil,
  onTop = false,
  refesh = true,
  }, Window)
  table.insert(WindowList, window)
  return window
end

function Window:saveBackground()
  self.buffer = {}			-- clear the buffer
  -- for the active window we save the whole background, if it is not moving, or lowered
--[[
  if self.id == #WindowList and self.moving == false and self.lowered  == false then
    for i = 1, self. w do
      self.buffer[i] = {}
      for j = 1, self.h + 1 do
	local c, fg, bg = gpu.get(self.x + i - 1, self.y + j - 1)
	self.buffer[i][j] = {["c"] = c, ["fg"] = fg, ["bg"] = bg}
      end
    end
  elseif self.id == #WindowList then
]]--
    for x = self.x, self.x + self.w do
      local c, fg, bg = gpu.get(x, self.y)
      table.insert(self.buffer, {c, fg, bg})	-- insert the character and colors into the buffer
    end
--  end
end

function Window:restoreBackground()
  -- for the active window we restore the whole background, if it is not moving or lowered
--[[
  if self.id == #WindowList and self.moving == false and self.lowered  == false then
    local oldBG = -1
    local oldFG = -1
    for i = 1, self.w do
      for j = 1, self.h + 1 do
	if oldBG ~= self.buffer[i][j].bg then
	  gpu.setBackground(self.buffer[i][j].bg)
	  oldBG = self.buffer[i][j].bg
	end
	if oldFG ~= self.buffer[i][j].fg then
	  gpu.setForeground(self.buffer[i][j].fg)
	  oldFG = self.buffer[i][j].fg
	end
	gpu.set(self.x + i - 1, self.y + j - 1, self.buffer[i][j].c)
      end
    end
  elseif self.id == #WindowList then
]]--
    local oldFG, oldBG
    for x, value in pairs(self.buffer) do
      local bg = value[3]
      local fg = value[2]
      if oldBG ~= bg then
	gpu.setBackground(bg)
	oldBG = bg
      end
      if oldFG ~= fg then
	gpu.setForeground(fg)
	oldFG = fg
      end
      gpu.set(self.x + x -1, self.y, value[1])
    end
--  end
end

function Window:draw()
  -- check size of window depending an screen an correct the position if outside
  if self.y < 2 then				-- no window on top line of screen
    self.y = 2
  end
  if self.x < 1 then
    self.x = 1
  end
  if self.x + self.w > ScreenWidth then
    self.x = ScreenWidth - self.w 
  end
  if useWindowShadows == true then
    if self.y + self.h > ScreenHeight - 2 then
      self.y = ScreenHeight - 2 - self.h		-- we need the bottom line of screen for window manager 
    end
  else
    if self.y + self.h > ScreenHeight - 1 then
      self.y = ScreenHeight - 1 - self.h		-- we need the bottom line of screen for window manager 
    end
  end
  -- save the background of the top line for moving
  self:saveBackground()
  -- color of top line depends if window is on top or in background
  if self.id == #WindowList then
    gpu.setForeground(Color.WindowActiveFrameForeground)
    gpu.setBackground(Color.WindowActiveFrameBackground)
  else
    gpu.setForeground(Color.WindowInactiveFrameForeground)
    gpu.setBackground(Color.WindowInactiveFrameBackground)
  end
  -- display the top line of the window
  gpu.fill(self.x, self.y, self.w, 1, " ")
  if string.len(self.text) <= self.w - 3 then
    gpu.set(self.x + math.floor((self.w/2) - (string.len(self.text)/2)), self.y, self.text)
  else
    gpu.set(self.x +1, self.y, string.sub(self.text,1, self.w - 3))
  end
  if self.sticky == false then
    gpu.set(self.x, self.y, "#")
  end
  if self.disableButtons == false then
    gpu.set(self.x + self.w - 2, self.y, "_X")
  end
  if self.moving == false then
    -- fill the window main body
    gpu.setBackground(Color.WindowBackground)
    gpu.setForeground(Color.Frame)
    gpu.fill(self.x, self.y + 1, self.w, self.h, " ")
    -- paint the frame
    gpu.fill(self.x, self.y + 1, 1, self.h - 1, unicode.char(windowFrame[2]))
    gpu.fill(self.x + self.w - 1, self.y + 1, 1, self.h - 1, unicode.char(windowFrame[2]))
    gpu.fill(self.x + 1, self.y + self.h, self.w - 2, 1, unicode.char(windowFrame[1]))
    gpu.set(self.x, self.y + self.h, unicode.char(windowFrame[5]))
    gpu.set(self.x + self.w - 1, self.y + self.h, unicode.char(windowFrame[6]))
    if useWindowShadows == true then
      gpu.setForeground(Color.Shadow)
      gpu.setBackground(Color.Shadow)
      gpu.fill(self.x + 1, self.y + self.h + 1, self.w - 1, 1, " ")
      gpu.fill(self.x + self.w, self.y + 1, 1, self.h + 1, " ")
      if useBoxShadows == true then
	_, _, Background, _ = gpu.get(self.x + self.w, self.y)
	gpu.setBackground(Background)
	gpu.set(self.x + self.w, self.y, unicode.char(0x25E3))
	_, _, Background, _ = gpu.get(self.x, self.y + self.h + 1)
	gpu.setBackground(Background)
	gpu.set(self.x, self.y + self.h + 1, unicode.char(0x25E5))
      end
      
    end
    -- redraw all elements in window
    for i = 1, #self.elements do
      self.elements[i].drawCallback(self, self.elements[i])		-- each element has his own callback for drawing it
    end
  end
end

-- checks if window is touched and raise it, if it is not the top one
function Window:onTouch(x, y, b)
  if self.lowered == true then 
    return false
  end

  for key, value in pairs(self.elements) do
    if x >= self.x and x <= self.x + self.w - 1 and self.moving == false then
      if y >= self.y and y <= self.y + self.h then
	if self.id < #WindowList then
	  if blockMouse == false then
	    wm.raiseWindow(self)
	  end
	end
	checkElementTouch(x, y, b, self, value)
      end
    end
  end

  if blockMouse == true then
    return true
  end
  -- check if one of the window buttons is clicked (lower or close)
  if x == self.x + self.w - 1 and y == self.y and self.moving == false and self.disableButtons == false then			-- close button
      wm.closeWindow(self)
      return true
  elseif x == self.x + self.w - 2 and y == self.y and self.moving == false and self.disableButtons == false then		-- lower button
      wm.lowerWindow(self)
      return true
  elseif x == self.x and y == self.y and self.sticky == false then			-- then movement button
    self.moving = not self.moving							-- switch movemnt mode of window
    wm.raiseWindow(self)
    return true
  end
  
  if x >= self.x and x <= self.x + self.w - 1 and self.moving == false then
    if y >= self.y and y <= self.y + self.h then
      if self.id < #WindowList then
	-- window is lower, then the top one. raise it top level
	wm.raiseWindow(self)
	return true
      else
  	return true
      end
    end
  end
  
  
  return false
end

function Window:move(x, y)
  self.x = x
  self.y = y
end

-- top and bottom stuff
local symbolList = {}
local Symbol = {}
Symbol.__index = Symbol

function Symbol:New(x, y, icon, program, level, w)
  symbol = setmetatable({
    x = x,
    y = y,
    level = level or 0,
    icon = icon or "?",
    w = w or 1,
    program = assert(loadfile(program)) or nil,
    runningState = false,
  },Symbol)
  table.insert(symbolList, symbol)
  if symbolList[#symbolList].program and symbolList[#symbolList].runningState == false then
    symbolList[#symbolList].program(#symbolList, "load", 0, symbolList[#symbolList].icon)
  end
end

local function drawSymbols()
  gpu.setBackground(Color.BottomLineBackground)
  gpu.setForeground(Color.BottomLineForeground)
  for i = 1, #symbolList do
    gpu.set(symbolList[i].x, symbolList[i].y, symbolList[i].icon)
  end
end

function symbolTouchCheck(x, y, b)
  if blockMouse == true then
    return
  end
  for i = 1, #symbolList do
    if x <= symbolList[i].x + symbolList[i].w - 1 and x >= symbolList[i].x and y == symbolList[i].y then
	if symbolList[i].program and symbolList[i].runningState == false then
	  if userLevel >= symbolList[i].level then
	    symbolList[i].program(i, "execute", math.floor(b), symbolList[i].icon)
	  end
	end
    end
  end
end

function wm.newSymbol(icon, program, level)
  local w = string.len(icon)
  if w < 1 then
    w = 1
  end
  for i = 1, #symbolList do
    w = w + symbolList[i].w
  end
  local x = ScreenWidth - w + 1
  local y = ScreenHeight
  l = string.len(icon)
  if l < 1 then
    l = 1
  end
  ret = Symbol:New(x, y, icon, program, level, l)
  drawSymbols()
  return ret
end

function wm.setSymbolSize(id, size)
  local w = size
  for i = 1, #symbolList do
    if i ~= id then
      w = w + symbolList[i].w
    end
  end
  symbolList[id].w = size
  symbolList[id].x = ScreenWidth - w + 1
  drawSymbols()
end

function wm.setIcon(id, icon)
  symbolList[id].icon = icon
  drawSymbols()
end

function wm.setSymbolProgram(self, program)
  self.program = assert(loadfile(program))
end

function wm.drawSymbol(id, c)
  gpu.setBackground(Color.BottomLineBackground)
  if c then
    gpu.setForeground(c)
  else
    gpu.setForeground(Color.BottomLineForeground)
  end
  gpu.set(symbolList[id].x, symbolList[id].y, symbolList[id].icon)
end

function wm.getSymbolPos(id)
  return symbolList[id].x, symbolList[id].y
end

function wm.setRunningState(num, state)
  symbolList[num].runningState = state
end

-- menu stuff
local Menu = {}
Menu.__index = Menu

local MenuList = {}
local menuIsActive = 0

function Menu:New(x, y, w, text, callback)
  menu = setmetatable({
    id = #MenuList + 1,
    x = x,
    y = y,
    w = w,
    text = text,
    entries = {},
    selected = 1,
    callback = callback,
    useFrame = false,
    buffer = {}
  }, Menu)
  for i = 1, w + 2 do
    menu.buffer[i] = {}
    for j = 1, 20 do
      menu.buffer[i][j] = { ["bg"] = 0, ["fg"] = 0, ["ch"] = " " }
    end
  end
  table.insert(MenuList, menu)			-- just for loop over all menus
  return menu
end

function menuSaveBackground(self)
  local w = self.w
  local h = #self.entries
  if self.useFrame == true then
    h = h + 2
    -- needed if menu list is empty
    if h == 2 then
      return
    end
  end
  if h == 0 then
    return
  end
  for i = 1, w do
    for j = 1, h do
      local ch, fg, bg = gpu.get(self.x + i - 1, self.y + j - 1)
      self.buffer[i][j] = { ["bg"] = bg, ["fg"] = fg, ["ch"] = ch }
    end
  end
end

function restoreMenuBackground(self)
  local oldBG, oldFG
  local w = self.w
  local h = #self.entries
  if self.useFrame == true then
    h = h + 2
    -- needed if menu list is empty
    if h == 2 then
      return
    end
  end
  if h == 0 then
    return
  end
  for i = 1, w do
    for j = 1, h do
      if oldBG ~= self.buffer[i][j].bg then
	gpu.setBackground(self.buffer[i][j].bg)
	oldBG = self.buffer[i][j].bg
      end
      if oldFG ~= self.buffer[i][j].fg then
	oldFG = self.buffer[i][j].fg
      end
      gpu.set(self.x + i - 1, self.y + j - 1, self.buffer[i][j].ch)
    end
  end
end

function Menu:draw()
  if #self.entries == 0 then
    return
  end
  if self.x <= 1 then
    self.x = 1
  end
  if self.x + self.w > ScreenWidth then
    self.x = ScreenWidth - self.w
  end
  if self.y < 2 then
    self.y = 2
  end
  if self.useFrame == true then
    if self.y + #self.entries + 2 > ScreenHeight  then
      self.y = ScreenHeight - #self.entries - 2
    end
  else
    if self.y + #self.entries > ScreenHeight  then
      self.y = ScreenHeight - #self.entries 
    end
  end
  menuSaveBackground(self)
  for i = 1, #self.entries do
    if i == self.selected then
      gpu.setBackground(Color.MenuSelectedBackground)
      gpu.setForeground(Color.MenuSelectedForeground)
    else
      gpu.setBackground(Color.MenuBackground)
      gpu.setForeground(Color.MenuForeground)
    end
    if self.useFrame == true then
      gpu.fill(self.x + 1, self.y + i, self.w - 2, 1, " ")
      gpu.set(self.x + 1, self.y + i, string.sub(self.entries[i], 1, self.w - 2))
      -- start frame
      gpu.setBackground(Color.MenuBackground)
      gpu.setForeground(Color.MenuForeground)
      gpu.set(self.x, self.y + i, unicode.char(menuFrame[2]))
      gpu.set(self.x + self.w - 1, self.y + i, unicode.char(menuFrame[2]))
      gpu.set(self.x, self.y, unicode.char(menuFrame[3]))
      gpu.set(self.x + self.w - 1, self.y, unicode.char(menuFrame[4]))
      gpu.set(self.x, self.y + #self.entries + 1, unicode.char(menuFrame[5]))
      gpu.set(self.x + self.w - 1, self.y + #self.entries + 1, unicode.char(menuFrame[6]))
    else
      gpu.fill(self.x , self.y + i - 1, self.w, 1, " ")
      gpu.set(self.x, self.y + i - 1, string.sub(self.entries[i], 1, self.w - 1))
    end
  end
  if self.useFrame == true then
    gpu.fill(self.x + 1, self.y, self.w - 2, 1, unicode.char(menuFrame[1]))
    gpu.fill(self.x + 1, self.y + #self.entries + 1, self.w - 2, 1, unicode.char(menuFrame[1]))
    gpu.set(self.x + math.floor(self.w/2) - math.floor(string.len(self.text)/2), self.y, self.text)
  end
end

function Menu:onTouch(x, y, b)
  if blockMouse == true then
    return
  end
  if b == 0 then						-- menus will only accept left mouse button
    -- touch is inside menu
    if x >= self.x and x <= self.x + self.w - 1 then
      if y >= self.y and y <= self.y + #self.entries then
-- FIXME: Need to be redone, because sometimes the wrong window is selected if menu is shown over a window.
	--Then the window under the menu will become the active one
	if self.useFrame == true then
	  self.selected = y - self.y
--	  restoreMenuBackground(self)
	  self:draw()
	  os.sleep(0.1)						-- give user a chance to see the click :-)
--	  restoreMenuBackground(self)
	  self.callback(y - self.y)
	else
	  self.selected = y - self.y + 1
--	  restoreMenuBackground(self)
	  self:draw()
	  os.sleep(0.1)						-- give user a chance to see the click :-)
--	  restoreMenuBackground(self)
	  self.callback(y - self.y + 1)
	end
      end
    else
--      restoreMenuBackground(self)
    end
  else
--    restoreMenuBackground(self)
  end
    -- at last deactivate menu and get back to window handling
    menuIsActive = 0
    clearScreen()
    redrawAllWindows()
end


-- screen event handling
function screenTouchCheck(x, y, b)
  if blockMouse == false then
    if y > 1 and y < ScreenHeight then					-- ignore touch on top or bottom line
      if b == 1 then							-- right mouse button opens window list
	wm.clearMenu(windowListMenu)
	wm.menuSetPosition(windowListMenu, x, y)
	for i = 1, #WindowList do
	  if WindowList[i].hide == false then				-- hide windows will not shown in window list
	    if WindowList[i].lowered == true then
	      wm.insertMenu(windowListMenu, "-" .. WindowList[i].text)
	    else
	      wm.insertMenu(windowListMenu, " " .. WindowList[i].text)
	    end
	  end
	end
	wm.drawMenu(windowListMenu)
      end
    end
  end
end

local systemMenu = {}
local systemMenuState = false
local systemMenuEnabled = true
local systemMenuPos = 1

local systemMenuList = {}
local SystemMenuElement = {}
SystemMenuElement.__index = SystemMenuElement

local function drawSystemMenu()
  if systemMenuEnabled == true then
    if systemMenuState == false then
      gpu.setBackground(Color.systemMenuBackground)
      gpu.setForeground(Color.systemMenuForeground)
    elseif systemMenuState == true then
      gpu.setBackground(Color.systemMenuActiveBackground)
      gpu.setForeground(Color.systemMenuActiveForeground)
    end
    gpu.set(systemMenuPos, 1, "[system]")
  end
end


function SystemMenuElement:New(name, path, param, level, Type)
  sm = setmetatable ({
    name = name,
    path = path,
    level = level or 0,
    isActive = false,
    Type = Type or 0,
    param = param or nil,
  },SystemMenuElement)
  wm.insertMenu(systemMenu, name)
  table.insert(systemMenuList, sm)
  wm.menuSetPosition(systemMenu, systemMenuPos - 10, 1)
  drawSystemMenu()
  return sm
end

function systemmenuTouchCheck(x, y, b)
  if blockMouse == true then
    return
  end
  if y == 1 and x >= systemMenuPos and x <= systemMenuPos + 7 then			-- menu clicked
    systemMenuState = not systemMenuState
    drawSystemMenu()
    if systemMenuState == true then
      wm.drawMenu(systemMenu)
    end
  end
end

function wm.addSystemMenu(name, path, param, level, Type)
  SystemMenuElement:New(name, path, param, level, Type)
end

local function systemMenuCallback(entry)
  systemMenuState = false
  drawSystemMenu()
  if systemMenuList[entry].isActive == false then
    systemMenuList[entry].isActive = true
    if userLevel >= systemMenuList[entry].level then
      if systemMenuList[entry].Type == 0 then
	wm.startProgram(systemMenuList[entry].path, entry)(systemMenuList[entry].param)
      elseif systemMenuList[entry].Type == 1 then
	systemMenuList[entry].path(systemMenuList[entry].param)
      end
    end
  end
end

function wm.enableSytemMenu(state)
  systemMenuEnabled = state
end

function wm.setSystemMenuPos(pos)
  if pos == "left" then
    systemMenuPos = 1
  elseif pos == "right" then
    systemMenuPos = ScreenWidth - 8
  end
end

local startMenu = {}
local startMenuState = false
local startMenuEnabled = true

local startMenuList = {}
local StartMenuElement = {}
StartMenuElement.__index = StartMenuElement

local function drawStartMenu()
  if startMenuEnabled == true then
    if startMenuState == false then
      gpu.setBackground(Color.startMenuBackground)
      gpu.setForeground(Color.startMenuForeground)
    elseif startMenuState == true then
      gpu.setBackground(Color.startMenuActiveBackground)
      gpu.setForeground(Color.startMenuActiveForeground)
    end
    gpu.set(2, ScreenHeight, "[start]")
  end
end


function StartMenuElement:New(name, path, param, level, Type)
  sm = setmetatable ({
    name = name,
    path = path,
    level = level or 0,
    isActive = false,
    Type = Type or 0,
    param = param or nil,
  },StartMenuElement)
  wm.insertMenu(startMenu, name)
  table.insert(startMenuList, sm)
  wm.menuSetPosition(startMenu, 2, ScreenHeight - 2 - #startMenuList)
  drawStartMenu()
  return sm
end

function startmenuTouchCheck(x, y, b)
  if blockMouse == true then
    return
  end
  if y == ScreenHeight and x >= 1 and x <= 7 then			-- start clicked
    startMenuState = not startMenuState
    drawStartMenu()
    if startMenuState == true then
      wm.drawMenu(startMenu)
    end
  end
end

function wm.addStartMenu(name, path, param, level, Type)
  StartMenuElement:New(name, path, param, level, Type)
end

local function startMenuCallback(entry)
  startMenuState = false
  drawStartMenu()
  if startMenuList[entry].isActive == false then
    startMenuList[entry].isActive = true
    if userLevel >= startMenuList[entry].level then
      if startMenuList[entry].Type == 0 then
	wm.startProgram(startMenuList[entry].path, entry)(startMenuList[entry].param)
      elseif startMenuList[entry].Type == 1 then
	startMenuList[entry].path(startMenuList[entry].param)
      end
    end
  end
end

function wm.shutdown(reboot)
  computer.shutdown(reboot)
end

function wm.exitProgram(id)
  startMenuList[id].isActive = false
end

function wm.enableStartMenu(state)
  startMenuEnabled = state
end

function wm.clearStartMenu()
  startMenuList = {}
  wm.clearMenu(startMenu)
end

-- event listeners

-- the touch event handler it self
local function TouchEventListener(_, _, x, y, b)
  if menuIsActive == 0 then						-- if a menu is running, no window management
    local wasWindowAction = false
    -- needs to be backwards, because top window is allways last in list
    for i = #WindowList, 1, -1 do
      -- window touch returns true, if window is on top
      if WindowList[i]:onTouch(x, y, b) == true then
	wasWindowAction = true						-- needed for on screen clicks, if click was inside any window
	break
      end
    end
    if wasWindowAction == false then				   	-- the click was somewhere on the screen, outside a window
    if systemMenuState == true then
      restoreMenuBackground(systemMenu)
      systemMenuState = false
      drawSystemMenu()
    end
    if startMenuState == true then
      restoreMenuBackground(startMenu)
      startMenuState = false
      drawStartMenu()
    end
      screenTouchCheck(x, y, b)
    end
  elseif menuIsActive > 0 then
    -- handle menu touch
    if systemMenuState == true then
      restoreMenuBackground(systemMenu)
      systemMenuState = false
      drawSystemMenu()
    end
    if startMenuState == true then
      restoreMenuBackground(startMenu)
      startMenuState = false
      drawStartMenu()
    end
    MenuList[menuIsActive]:onTouch(x, y, b)
  end
    -- bottom line check
  if y == ScreenHeight then
    if systemMenuState == true then
      restoreMenuBackground(systemMenu)
      systemMenuState = false
      drawSystemMenu()
    end
    if x > 10 then
      symbolTouchCheck(x, y, b)
    elseif startMenuEnabled == true then
      startmenuTouchCheck(x, y, b)
    end
  elseif y == 1 then
    if startMenuState == true then
      restoreMenuBackground(startMenu)
      startMenuState = false
      drawStartMenu()
    end
    systemmenuTouchCheck(x, y, b)
  end
end

local function DragEventListener(_, _, x, y, b)
  if blockMouse == false then
    if WindowList[#WindowList].moving == true then
      WindowList[#WindowList]:restoreBackground()
      WindowList[#WindowList]:move(x, y)
      WindowList[#WindowList]:draw()
--      clearScreen()
--      AllWindows()
    end
  end
end

local function DropEventListener(_, _, x, y, b)
  if blockMouse == false then
    WindowList[#WindowList].moving = false
    WindowList[#WindowList]:draw()
  end
end


local DriverList = {}
local Driver = {}
Driver.__index = Driver

function Driver:New(name, description, copyright, version)
  driver = setmetatable({
    id = #DriverList + 1,
    name = name,
    description = description or "",
    copyright = copyright or "",
    version = version or "0.0"
  },Driver)
  table.insert(DriverList, driver)
  return driver
end

dotPosition = ScreenWidth

function wm.registerDriver(name, description, copyright, version)
  Driver:New(name, description, copyright, version)
  dotPosition = dotPosition - 1
  return dotPosition 
end

function wm.getDriverList()
  return DriverList
end

local function autoUpdateTimerCallback()
  MultiThread()
end


-- General functions
function wm.getActiveWindow()
  return WindowList[#WindowList]
end

function wm.blockMouse(state)
  blockMouse = state
end

function windowMenuListCallback(entry)
  wm.raiseWindow(WindowList[entry])
end

local timerEventTimer

function wm.startProgram(path, id)
  local program = loadfile(path)(id)
  local th = wm.threadCreate(program)
end

-- must be called once before using the gui
function wm.startGui()
  gpu.setBackground(color.black)
  gpu.setForeground(color.white)
  gpu.fill(1, 1, ScreenWidth, ScreenHeight, " ")
  gpu.set(1,1,"Starting windowmanager")
  clearScreen()
  drawScreen()
  
  -- build up the empty menu for the window list menu
  windowListMenu = wm.newMenu(1, 1, 20, "Window list", windowMenuListCallback)		-- x and y will be changed later
  if startMenuEnabled == true then
    startMenu = wm.newMenu(1, ScreenHeight, 20, "", startMenuCallback)
    wm.menuUseFrame(startMenu, true)
  end
  if systemMenuEnabled == true then
    systemMenu = wm.newMenu(1, 1, 20, "", systemMenuCallback)
    wm.menuUseFrame(systemMenu, true)
  end
  wm.menuUseFrame(windowListMenu, true)
  
  redrawAllWindows()
  
  
  event.listen("touch", TouchEventListener)
  event.listen("drag", DragEventListener)
  event.listen("drop", DropEventListener)
  autoUpdateTimer = event.timer(0.1, autoUpdateTimerCallback, math.huge)
  threadInit()

end

function wm.exitGui()
  gpu.setBackground(color.black)
  gpu.setForeground(color.white)
  gpu.fill(1, 1, ScreenWidth, ScreenHeight, " ")
  gpu.set(1, 1, "Stopping event listeners ")
  event.ignore("touch", TouchEventListener)
  event.ignore("drag", DragEventListener)
  event.ignore("drop", DropEventListener)
  event.cancel(autoUpdateTimer)
  gpu.set(26, 1, "ok")
  local d = 12
  gpu.set(1,2, "Cleaning up")
  for i = #WindowList, 1, -1 do
    table.remove(WindowList, i)
    gpu.set(d, 2, ".")
    d = d + 1
  end
  for i = #symbolList, 1, -1 do
    if symbolList[i].program then
      symbolList[i].program(i, "unload", 0, symbolList[i].icon)
      symbolList[i].program = nil
    end
    table.remove(symbolList, i)
    gpu.set(d, 2, ".")
    d = d + 1
  end
  gpu.set(d, 2, "ok")
  gpu.set(1,3, "Gui stopped")
  gpu.set(1,4, "You better reboot now :-)")
  os.exit()
end

function wm.setTopText(text)
  gpu.setBackground(Color.TopLineBackground)
  gpu.setForeground(Color.TopLineForeground)
  gpu.fill(1, 1, ScreenWidth, 1, " ")
  gpu.set(math.floor(ScreenWidth/2) - math.floor(string.len(text)/2), 1, text)
end


function wm.getColors()
  return Color
end

function wm.getVersion()
  return versionMajor, versionMinor, versionState
end

function wm.getWindowFrame()
  return windowFrame
end

function wm.setWindowFrame(num)
  if num == 1 then
    windowFrame = frame.Small
  elseif num == 2 then
    windowFrame = frame.Double
  elseif num == 3 then
    windowFrame = frame.Bold
  elseif num == 4 then
    windowFrame = frame.Flat
  end
end

function wm.getShadow()
  return useWindowShadows
end

function wm.setShadow(state)
  useWindowShadows = state
end

function wm.getMenuFrame()
  return menuFrame
end

function wm.setMenuFrame(num)
  if num == 1 then
    menuFrame = frame.Small
  elseif num == 2 then
    menuFrame = frame.Double
  elseif num == 3 then
    menuFrame = frame.Bold
  elseif num == 4 then
    menuFrame = frame.Flat
  end
end


-- Window functions

function wm.getViewport(self)
  return self.x, self.y + 1, self.w - 2, self.h - 1
end

function wm.newWindow(x, y, w, h, text)
  return Window:New(x, y, w, h, text)
end

-- set a window to top over all other windows
function wm.raiseWindow(self)
  self.lowered = false
  table.remove(WindowList, self.id)		-- remove the window from table
  table.insert(WindowList, self)		-- insert window as last in table
  resortWindows()
  for i = #WindowList - 1, 1, -1 do		-- take movement of all windows
    WindowList[i].moving = false
  end
  self.onTop = true
  clearScreen()
  redrawAllWindows()
end

function wm.closeWindow(self)
--  self:restoreBackground()
  if self.onCloseCallback then
    if self.onCloseCallback(self) == false then
      return
    end
  end
  table.remove(WindowList, self.id)
  self = nil
  resortWindows()
  clearScreen()
  redrawAllWindows()
end

function wm.lowerWindow(self)
--  self:restoreBackground()
  if self.onLowerCallback then
    if self.onLowerCallback(self) == false then
      return
    end
  end
  self.lowered = true
  for i = #WindowList, 1, -1 do			-- raise the next available window from end of list
    if WindowList[i].lowered == false then
      wm.raiseWindow(WindowList[i])
      break
    end
  end

  clearScreen()
  redrawAllWindows()
end

function wm.disableWindowButtons(self, state)
  self.disableButtons = state
end

function wm.setWindowSticky(self, state)
  self.sticky = state
end

function wm.hideWindow(self, state)
  self.hide = state
end

function wm.setOnCloseCallback(self, callback)
  self.onCloseCallback = callback
end

function wm.setOnLowerCallback(self, callback)
  self.onLowerCallback = callback
end

function wm.getWindowInfo(self)
  if self.lowered == false then
    return self.x, self.y, self.w, self.h, self.text, #self.elements
  elseif self.lowered == true then
    return 0, 0, 0, 0, self.text, #self.elements
  end
end


function wm.redraw()
    clearScreen()
    redrawAllWindows()
end

-- gui elements
function wm.addElement(self, element)
  table.insert(self.elements, element)
end

function wm.newElement(id, x, y, w, h, text, callback)
  return Element:New(id, x, y, w, h, text, callback)
end





-- Menu functions
function wm.newMenu(x, y, w, text, callback)
  return Menu:New(x, y, w, text, callback)
end

function wm.insertMenu(self, entry)
  table.insert(self.entries, entry)
end

function wm.removeMenu(self, entry)
  table.remove(self.entries, entry)
end

function wm.clearMenu(self)
  self.entries = {}
end

function wm.setMenuCallback(self, callback)
  self.callback = callback
end

function wm.drawMenu(self)
  if menuIsActive ~= self.id and menuIsActive > 0 then
    restoreMenuBackground(MenuList[menuIsActive])
  end
  menuIsActive = self.id
  self.selected = 1
  self:draw()
end

function wm.menuSetPosition(self, x, y)
  self.x = x
  self.y = y
end

function wm.menuUseFrame(self, state)
  self.useFrame = state
end


return wm
