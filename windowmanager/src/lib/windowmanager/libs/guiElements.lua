--FIXME: Frames need a new draw function. problems with dimensions
--FIXME: 



local component = require("component")
local gpu = component.gpu
local event = require("event")
local unicode = require("unicode")
local filesystem = require("filesystem")
local wm = require("windowmanager/libs/wm")

local term = require("term")
local shell = require("shell")
local text = require("text")
local sh = require("sh")


local guiElements = {}

local lastElement = {
["id"] = "none",
["text"] = "no text",
["x"] = 0,
["y"] = 0,
["w"] = 0,
["h"] = 0,
}
-- frames
local Frame = {
  -- horizontal, vertical, left-top, right-top, left-bottom, right-bottom
  ["Double"] = {0x2550, 0x2551, 0x2554, 0x2557, 0x255A, 0x255D},
  ["Small"] = {0x2500, 0x2502, 0x250C, 0x2510, 0x2514, 0x2518},
  ["Bold"] = {0x2501, 0x2503, 0x0250F, 0x2513, 0x2517, 0x251B}
}


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

-- element colors
local Color = {}
Color.LabelBackground = color.gray
Color.LabelForeground = color.black
Color.ButtonBackground = color.blue
Color.ButtonForeground = color.white
Color.ButtonActiveBackground = color.green
Color.ButtonActiveForeground = color.white
Color.LineBackground = color.gray
Color.LineForeground = color.black
Color.FrameBackground = color.gray
Color.FrameForeground = color.black
Color.HSliderBackground = color.black
Color.HSliderForeground = color.white
Color.HSliderActiveBackground = color.black
Color.HSliderActiveForeground = color.green
Color.VSliderBackground = color.black
Color.VSliderForeground = color.white
Color.VSliderActiveBackground = color.black
Color.VSliderActiveForeground = color.green
Color.HBarBackground = color.black
Color.HBarForeground = color.green
Color.CheckboxBackground = color.gray
Color.CheckboxForeground = color.black
Color.InputBackground = color.black
Color.InputForeground = color.white
Color.InputActiveBackground = color.blue
Color.InputActiveForeground = color.white
Color.ListBackground = color.blue
Color.ListForeground = color.white
Color.ListActiveBackground = color.green
Color.ListActiveForeground = color.white
Color.RadioBackground = color.gray
Color.RadioForeground = color.black
Color.DrawBufferBackground = color.gray
Color.DrawBufferForeground = color.black
Color.TerminalBackground = color.black
Color.TerminalForeground = color.white

-- local functions
local function getPosAlign(win, self)
  if self.alignment == "left" then
    return win.x + self.x
  elseif self.alignment == "center" then
    return win.x + self.x + math.floor(self.w/2) - math.floor(string.len(string.sub(self.text, 1, self.w))/2)
  elseif self.alignment == "right" then
    return win.x + self.x + self.w - string.len(string.sub(self.text, 1, self.w))
  end
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

function correctPos(win, self)
  local x = self.x + win.x
  local y = self.y + win.y 
  local w = self.w 
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

function updateLastElement(self)
  lastElement.id = self.id
  lastElement.text = self.text
  lastElement.x =self.x
  lastElement.y =self.y
  lastElement.w =self.w
  lastElement.h =self.h
end

local history = {}

local terminalTimer = nil
shell.prime()

function terminalCallback(win, self)
    if terminalTimer then
      event.cancel(terminalTimer)
    end
      local foreground = gpu.setForeground(0xFF0000)
      term.write(sh.expand(os.getenv("PS1") or "$ "))
      gpu.setForeground(foreground)
      term.setCursorBlink(true)
      local ok, command
      ok, command = pcall(term.read, history, nil, sh.hintHandler)
      if not command then
        io.write("exit\n") -- pipe closed
        wm.closeWindow(win)
      end

      command = text.trim(command)

      if command == "exit" then
        wm.closeWindow(win)
      elseif command ~= "" then
	local result, reason
        result, reason = sh.execute(_ENV, command)
        if term.getCursor() > 1 then
          print()
        end
        if not result then
          io.stderr:write((reason and tostring(reason) or "unknown error") .. "\n")
	end
      end
	if ok == true  then
	  if wm.getActiveWindow() == win then
	    terminalTimer = event.timer(0, function()terminalCallback(win,self) end)
	  end
	end
end

function drawTerminal(win, self)
  local x, y, w, h = correctPos(win, self)
  gpu.setBackground(Color.TerminalBackground)
  gpu.setForeground(Color.TerminalForeground)
  gpu.fill(x, y, w, h, " ")
  
  local x, y, w, h = correctPos(win, self)

  term.setViewport(w, h, x - 1, y - 1, 1, 1)

  if self.firstCall == true then
    if not term.isAvailable() then event.pull("term_available") end
    loadfile(shell.resolve("source","lua"))("/etc/profile")
      if not term.isAvailable() then -- don't clear unless we lost the term
	while not term.isAvailable() do
	  event.pull("term_available")
	end
	term.clear()
      end
      self.firstCall = false
      local gpu = term.gpu()
      if wm.getActiveWindow() == win then
	terminalCallback(win, self)
--	terminalTimer = event.timer(0, terminalCallback)
      end
    end
end

-- draw callbacks
function drawBuffer(win, self)
  local x, y, w, h = correctPos(win, self)
  local xv = self.userData1.xv
  local yv = self.userData1.yv
  local oldXV = self.userData2.oldXV
  local oldYV = self.userData2.oldYV
  if oldXV < xv then
    gpu.copy(x + 1, y, self.w - 1, self.h, - 1, 0)  
    oldBG = - 1
    oldFG = - 1
    for i = 1, self.h do
	bg = self.data[xv + self.w][i + yv].bg
	if bg ~= oldBG then
	  gpu.setBackground(bg)
	  oldBG = bg
	end
	fg = self.data[xv + self.w][i + yv].fg
	if fg ~= oldFG then
	  gpu.setForeground(fg)
	  oldFG = fg
	end
	gpu.set(x + self.w - 1, y + i - 1, self.data[xv + self.w][i + yv].character)
    end
    self.userData2.oldXV = xv
  elseif oldYV < yv then
    gpu.copy(x, y + 1, self.w, self.h - 1, 0, - 1)  
    oldBG = - 1
    oldFG = - 1
    for i = 1, self.w do
	bg = self.data[xv + i][self.h + yv].bg
	if bg ~= oldBG then
	  gpu.setBackground(bg)
	  oldBG = bg
	end
	fg = self.data[xv + i][self.h + yv].fg
	if fg ~= oldFG then
	  gpu.setForeground(fg)
	  oldFG = fg
	end
	gpu.set(x + i - 1, y + self.h - 1, self.data[xv + i][self.h + yv].character)
    end
    self.userData2.oldYV = yv
  elseif oldXV > xv then
    oldBG = - 1
    oldFG = - 1
    gpu.copy(x, y, self.w - 1, self.h, 1, 0)
    for i = 1, self.h do
	bg = self.data[xv + 1][i + yv].bg
	if bg ~= oldBG then
	  gpu.setBackground(bg)
	  oldBG = bg
	end
	fg = self.data[xv + 1][i + yv].fg
	if fg ~= oldFG then
	  gpu.setForeground(fg)
	  oldFG = fg
	end
	gpu.set(x, y + i - 1, self.data[xv + 1][i + yv].character)
    end
    self.userData2.oldXV = xv
  elseif oldYV > yv then
    local oldBG = -1
    local oldFG = -1
    gpu.copy(x, y, self.w, self.h - 1, 0, 1)  
    for i = 1, self.w do
	bg = self.data[xv + i][yv].bg
	if bg ~= oldBG then
	  gpu.setBackground(bg)
	  oldBG = bg
	end
	fg = self.data[xv + i][yv].fg
	if fg ~= oldFG then
	  gpu.setForeground(fg)
	  oldFG = fg
	end
	gpu.set(x + i - 1, y, self.data[xv + i][yv].character)
    end
    self.userData2.oldYV = yv
  else  
    local oldBG = -1
    local oldFG = -1
    for i = 1, self.w do
      for j = 1, self.h do
	bg = self.data[i + xv][j + yv].bg
	if bg ~= oldBG then
	  gpu.setBackground(bg)
	  oldBG = bg
	end
	fg = self.data[i + xv][j + yv].fg
	if fg ~= oldFG then
	  gpu.setForeground(fg)
	  oldFG = fg
	end
	gpu.set(x + i - 1, y + j - 1, self.data[i + xv][j + yv].character)
      end
    end
    self.userData2.oldYV = yv
    self.userData2.oldXV = xv
  end
end

function guiElements.setBufferViewport(self, x, y)
  self.userData2.oldXV = self.userData1.xv
  self.userData2.oldYV = self.userData1.yv
  self.userData1.xv = x
  self.userData1.yv = y
end

function guiElements.bufferSetBackground(self, bg)
  self.background = bg
end

function guiElements.bufferSetForeground(self, fg)
  self.foreground = fg
end

function guiElements.bufferSet(self, x, y, c)
  self.data[x][y] = {["bg"] = self.background, ["fg"] = self.foreground, ["character"] = c}
end

function guiElements.bufferFill(self, x, y, w, h, c)
  for i = x, x + w - 1 do
    for j = y, y + h - 1 do
      guiElements.bufferSet(self, i, j, c)
    end
  end
end



function drawRadio(win, self)
  self.h = #self.data 
  local x, y, w, h = correctPos(win, self)
  
  for i = 1, #self.data do
    gpu.setBackground(self.background)
    gpu.setForeground(self.foreground)
    local text = ""
      if self.alignment == "left" then
	if i == self.selected then
	  text = self.data[i] .. " (X)"
	else
	  text = self.data[i] .. " ( )"
	end
      elseif self.alignment == "right" then
	if i == self.selected then
	  text = "(X) " .. self.data[i]
	else
	  text = "( ) " .. self.data[i]
	end
      end
      local sl = (x + string.len(text))
      if sl > x + w then
	sl = x + w - sl - 1
      end
    if y + i - 1 < win.y + win.h then
      if x <= win.x + win.w - 2 then
	gpu.fill(x, y + i - 1, w, 1, " ")
	gpu.set(x, y + i - 1, string.sub(text, 1, sl))
      end
    end
  end
end



function drawList(win, self)
  local x, y, w, h = correctPos(win, self)
  gpu.setBackground(self.background)
  gpu.setForeground(self.foreground)
  gpu.fill(x, y, w, h, " ")
  for i = self.selected, #self.data do
    if i - self.selected <= h  - 1 then
      if i == self.selected then
	gpu.setBackground(self.activeBackground)
	gpu.setForeground(self.activeForeground)
      else
	gpu.setBackground(self.background)
	gpu.setForeground(self.foreground)
      end
      gpu.fill(x, y + i - self.selected, w, 1, " ")
      if h >= 1 then
	text = self.data[i]
	local sl = (x + string.len(text))
	if sl > x + w then
	  sl = x + w - sl - 1
	end
	if x <= win.x + win.w - 2 then
	  gpu.set(x, y + i - self.selected, string.sub(text, 1, sl))
	end
      end
    end
  end
end

function drawInput(win, self)
  local x, y, w, h = correctPos(win, self)
  if self.isActive == true then
    gpu.setBackground(self.activeBackground)
    gpu.setForeground(self.activeForeground)
  else
    gpu.setBackground(self.background)
    gpu.setForeground(self.foreground)
  end
  gpu.fill(x, y, w, h, " ")
  local tmpText = self.text
  if self.protected == true then
    tmpText = ""
    for i = 1, string.len(self.text) do
      tmpText = tmpText .. "*"
    end
  end
  if h >= 1 then
   local sl = (x + string.len(tmpText))
   if sl > x + w then
    sl = x + w - sl - 1
   end
   if x <= win.x + win.w - 2 then
    gpu.set(x, y, string.sub(tmpText, 1, sl))
   end
  end
end

function drawCheckbox(win, self)
  local x, y, w, h = correctPos(win, self)
  gpu.setBackground(self.background)
  gpu.setForeground(self.foreground)
  gpu.fill(x, y, w, h, " ")
  local text = ""
  if self.alignment == "left" then
    if self.state == true then
      text = self.text .. " [X]"
    elseif self.state == false then
      text = self.text .. " [ ]"
    end
  elseif self.alignment == "right" then
    if self.state == true then
      text = "[X] " .. self.text
    elseif self.state == false then
      text = "[ ] " .. self.text
    end
  end
    if h >= 1 then
      local sl = (x + string.len(text))
      if sl > x + w then
	sl = x + w - sl - 1
      end
      if x <= win.x + win.w - 2 then
	gpu.set(x, y, string.sub(text, 1, sl))
      end
    end
end

function drawVSlider(win, self)
  gpu.setBackground(self.background)
  gpu.setForeground(self.foreground)
  local x, y, w, h = correctPos(win, self)
  gpu.fill(x, y + 1, w, h - 1, " ")
  if y < win.y + win.h then
    if x < win.x + win.w - 1 then
      gpu.set(x, y, unicode.char(0x21E7))
    end
  end
  if y + self.h - 1 < win.y + win.h then
    if x < win.x + win.w - 1 then
      gpu.set(x, y + self.h - 1, unicode.char(0x21E9))
    end
  end
  local proz = math.floor(100 / (self.max - self.min) * (self.value - self.min))
  if proz > 100 then
    proz = 100
  end
  local pos = math.floor((self.h - 3) / 100 * proz) 
  if y + pos + 1 < win.y + win.h then
    if x < win.x + win.w - 1 then
      gpu.setBackground(self.foreground)
      gpu.set(x, y + pos + 1, " ")
    end
  end
end

function drawHSlider(win, self)
  gpu.setBackground(self.background)
  gpu.setForeground(self.foreground)
  local x, y, w, h = correctPos(win, self)
  gpu.fill(x + 1, y, w - 1, h, " ")
  if y < win.y + win.h then
    if x < win.x + win.w - 1 then
      gpu.set(x, y, unicode.char(0x21E6))
    end
    if x + self.w < win.x + win.w then
      gpu.set(x + self.w - 1, y, unicode.char(0x21E8))
    end
    local proz = math.floor(100 / (self.max - self.min) * (self.value - self.min))
    if proz > 100 then
      proz = 100
    end
    local pos = math.floor((self.w - 3) / 100 * proz) + 1
    if x + pos < win.x + win.w - 1 then
      gpu.setBackground(self.foreground)
      gpu.fill(x + pos, y, 1, h , " ")
    end
  end
end

function drawHBar(win, self)
  gpu.setBackground(self.background)
  gpu.setForeground(self.foreground)
  local x, y, w, h = correctPos(win, self)
  gpu.fill(x + 1, y, w - 1, h, " ")
  if y < win.y + win.h then
    local proz = math.floor(100 / (self.max - self.min) * (self.value - self.min))
    if proz > 100 then
      proz = 100
    end
    local pos = math.floor(self.w / 100 * proz) 
    gpu.setBackground(self.foreground)
    if x + pos < win.x + win.w - 1 then
      gpu.fill(x, y, pos, 1, " ")
    else
      gpu.fill(x, y, win.x + win.w - 1 - x, 1, " ")
    end
  end
end

function drawFrame(win, self)
  gpu.setBackground(self.background)
  gpu.setForeground(self.foreground)
  local x, y, w, h = correctPos(win, self)
  local tmpFrame = {}
  if self.type == 1 then
    tmpFrame = Frame.Small
  elseif self.type == 2 then
    tmpFrame = Frame.Double
  elseif self.type == 3 then
    tmpFrame = Frame.Bold
  end
    if y < win.y + win.h  then
      gpu.fill(x + 1, y, w - 1, 1, unicode.char(tmpFrame[1]))	-- top
    end
    if y + h < win.y + win.h then
      gpu.fill(x + 1, y + h, w - 1, 1, unicode.char(tmpFrame[1]))	-- bottom
    end
    if y < win.y + win.h and x < win.x + win.w - 1 then
      gpu.set(x, y, unicode.char(tmpFrame[3]))			-- left-top
    end
    if y + h < win.y + win.h and x < win.x + win.w - 1 then
      gpu.set(x, y + h, unicode.char(tmpFrame[5]))			-- left-bottom
    end
    if x < win.x + win.w - 1 then
      gpu.fill(x, y + 1, 1, h - 1, unicode.char(tmpFrame[2]))	-- left
    end

    if y < win.y + win.h and x + self.w < win.x + win.w then
      gpu.set(x + w - 1, y, unicode.char(tmpFrame[4]))			-- right-top
    end
    if y + h < win.y + win.h and x + self.w < win.x + win.w then
      gpu.set(x + w - 1, y + h, unicode.char(tmpFrame[6]))		-- right-bottom
    end
    if x + self.w < win.x + win.w then
      gpu.fill(x + w - 1, y + 1, 1, h - 1, unicode.char(tmpFrame[2]))	-- right
    end
end

function drawLine(win, self)
  gpu.setBackground(self.background)
  gpu.setForeground(self.foreground)
  local x, y, w, h = correctPos(win, self)
  if self.type == 1 then
    gpu.fill(x, y, w, h, unicode.char(0x2500))
  elseif self.type == 2 then
    gpu.fill(x, y, w, h, unicode.char(0x2550))
  elseif self.type == 3 then
    gpu.fill(x, y, w, h, unicode.char(0x2501))
  elseif self.type == 4 then
    gpu.fill(x, y, w, h, ".")
  elseif self.type == 5 then
    gpu.fill(x, y, w, h, "-")
  elseif self.type == 6 then
    gpu.fill(x, y, w, h, "=")
  elseif self.type == 7 then
    gpu.fill(x, y, w, h, " ")
  elseif self.type == 8 then
    gpu.fill(x, y, w, h, ".")
    for i = 4, w, 5 do
      if i + x < win.x + win.w - 1 then
	gpu.set(i + x, y, ":")
      end
    end
  end
end


function drawLabel(win, self)
  local x, y, w, h = correctPos(win, self)
  if self.isActive == true then
    gpu.setBackground(self.activeBackground)
    gpu.setForeground(self.activeForeground)
    self.isActive = false
  else
    gpu.setBackground(self.background)
    gpu.setForeground(self.foreground)
    self.isActive = false
  end
  gpu.fill(x, y, w, h, " ")
  local tPos = getPosAlign(win, self)
  if self.autoWordWrap == true then
    local text = wrap(self.text, self.w)
    for i = 1, #text do
      if h >= 1 and i <= h then
	local sl = (tPos + string.len(text[i]))
	if sl > x + w then
	  sl = x + w - sl - 1
	end
	if tPos <= win.x + win.w - 2 then
	  gpu.set(tPos, y + i - 1, string.sub(text[i], 1, sl))
	end
      end
    end
  else
    if h >= 1 then
      local sl = (tPos + string.len(self.text))
      if sl > x + w then
	sl = x + w - sl - 1
      end
      if tPos <= win.x + win.w - 2 then
	gpu.set(tPos, y, string.sub(self.text, 1, sl))
      end
    end
  end
end


-- handle callbacks
function generalCallback(win, self, x, y, b)
  updateLastElement(self)
end

function handleTerminal(win, self, x, y, b)
end

function handleList(win, self, x, y, b)
  updateLastElement(self)
  local sx, sy, sw, sh = correctPos(win, self)
  if b == 0 then
    self.selected = self.selected + y - sy
  end
  drawList(win, self)
end

function handleRadio(win, self, x, y, b)
  updateLastElement(self)
  local sx, sy, sw, sh = correctPos(win, self)
  if b == 0 then
    if self.alignment == "left" then
      if x == sx + string.len(self.data[y - sy + 1]) + 2 then
	self.selected = y - sy + 1
      end
    elseif self.alignment == "right" then
      if x == sx + 1 then
	self.selected = y - sy + 1
      end
    end
  end
  drawRadio(win, self)
end

function handleInput(win, self, x, y, b)
  updateLastElement(self)
  local sx, sy, sw, sh = correctPos(win, self)
  if b == 0 then
    if self.isActive == false then
      self.isActive = true
      drawInput(win, self)
      local inputText = self.text
      local cursorState = false
      while self.isActive == true do
	local tmpText = inputText
	if self.protected == true then
	  tmpText = ""
	  for i = 1, string.len(inputText) do
	    tmpText = tmpText .. "*"
	  end
	end
	gpu.setBackground(self.activeBackground)
	gpu.setForeground(self.activeForeground)
	gpu.fill(sx, sy, sw, 1, " ")
	if string.len(tmpText) + 1 > sw then
	  tmpText = string.sub(tmpText, string.len(tmpText) - sw + 2, string.len(tmpText))
	end
	if cursorState == true then
	  cursorState = false
	  tmpText = tmpText .. unicode.char(0x2582)
	else
	  cursorState = true
	end
	gpu.set(sx, sy, tmpText)
	local ev, _, ch, num = event.pullMultiple(0.1, "key_down", "touch")
	if ev == "key_down" then
	  if ch == 13 then				-- return
	    self.text = inputText
	    self.isActive = false
	    if win == wm.getActiveWindow() then
	      drawInput(win, self)
	    end
	  elseif ch == 8 then				-- backspace
	    inputText = string.sub(inputText, 1, string.len(inputText) - 1)
	  elseif ch > 31  and ch < 128 then				-- all other characters
	    inputText = inputText .. string.char(ch)
	  end
	elseif ev == "touch" then
	  if ch < sx or ch > sx + sw - 1 or num < sy or num > sy then
	    self.text = inputText
	    self.isActive = false
	    if win == wm.getActiveWindow() then
	      drawInput(win, self)
	    end
	  end
	end
      end
    end
    self.isActive = false
  end
  if b == 1 then
    return false
  end
--	    gpu.set(1,25, self.callback)
--	if self.callback then
--	  self.callback(self, win)				-- we need to call the callback, or user has no callback after text editing
--	end
  return true
end

function handleCheckbox(win, self, x, y, b)
  updateLastElement(self)
  local sx, sy, sw, sh = correctPos(win, self)
  if b == 0 then
    if x == sx + 1 and y == sy and self.alignment == "right" then
      self.state = not self.state
      drawCheckbox(win, self)
    elseif x == sx + string.len(self.text) + 2 and y == sy and self.alignment == "left" then
      self.state = not self.state
      drawCheckbox(win, self)
    end
  end
  if b == 1 then
    return false
  end
  return true
end

    
function handleButton(win, self, x, y, b)
  updateLastElement(self)
  if b == 0 then
  -- just let the user know, that the button was pressed
    self.isActive = true
    drawLabel(win, self)
    os.sleep(0.1)
    self.isActive = false
    drawLabel(win, self)
  end
  if b == 1 then
    return false
  end
  return true
end

function handleVSlider(win, self, x, y, b)
  updateLastElement(self)
  local sx, sy, sw, sh = correctPos(win, self)
  if b == 0 then
    if x == sx and y == sy then
	gpu.setBackground(self.activeBackground)
	gpu.setForeground(self.activeForeground)
	gpu.set(sx, sy, unicode.char(0x21E7))
	os.sleep(0.1)
	gpu.setBackground(self.background)
	gpu.setForeground(self.foreground)
	gpu.set(sx, sy, unicode.char(0x21E7))
	self.value = self.value - self.steps
	if self.value < self.min then
	  self.value = self.min
	end
	drawVSlider(win, self)
    end
    if x == sx and y == sy + self.h -1  then
	gpu.setBackground(self.activeBackground)
	gpu.setForeground(self.activeForeground)
	gpu.set(sx, sy + self.h - 1, unicode.char(0x21E9))
	os.sleep(0.1)
	gpu.setBackground(self.background)
	gpu.setForeground(self.foreground)
	gpu.set(sx, sy + self.h - 1, unicode.char(0x21E9))
	self.value = self.value + self.steps
	if self.value > self.max then
	  self.value = self.max
	end
	drawVSlider(win, self)
    end
  end
  if b == 1 then
    return false
  end
  return true
end


function handleHSlider(win, self, x, y, b)
  updateLastElement(self)
  local sx, sy, sw, sh = correctPos(win, self)
  if b == 0 then
    if x == sx and y == sy then				-- left arrow pressed
	gpu.setBackground(self.activeBackground)
	gpu.setForeground(self.activeForeground)
	gpu.set(sx, sy, unicode.char(0x21E6))
	os.sleep(0.1)
	gpu.setBackground(self.background)
	gpu.setForeground(self.foreground)
	gpu.set(sx, sy, unicode.char(0x21E6))
	self.value = self.value - self.steps
	if self.value < self.min then
	  self.value = self.min
	end
	drawHSlider(win, self)
    end
    if x == sx + self.w - 1 and y == sy then			-- right arrow pressed
	gpu.setBackground(self.activeBackground)
	gpu.setForeground(self.activeForeground)
	gpu.set(sx + self.w - 1, sy, unicode.char(0x21E8))
	os.sleep(0.1)
	gpu.setBackground(self.background)
	gpu.setForeground(self.foreground)
	gpu.set(sx + self.w - 1, sy, unicode.char(0x21E8))
	self.value = self.value + self.steps
	if self.value > self.max then
	  self.value = self.max
	end
	drawHSlider(win, self)
    end
  end
  if b == 1 then
    return false
  end
  return true
end

-- contructors
function guiElements.newTerminal(x, y, w, h)
  self = wm.newElement("terminal", x, y, w, h)
  self.drawCallback = drawTerminal
  self.background = Color.TerminalBackground
  self.foreground = Color.TerminalForeground
  self.handleCallback = handleTerminal
  return self
end

function guiElements.newDrawBuffer(x, y, w, h)
  self = wm.newElement("drawbuffer", x, y, w, h)
  self.drawCallback = drawBuffer
  self.background = Color.DrawBufferBackground
  self.foreground = Color.DrawBufferForeground
  self.handleCallback = generalCallback
  self.userData1.xv = 0
  self.userData1.yv = 0
  self.userData2.oldXV = 0
  self.userData2.oldYV = 0
  self.data = {}
  for i = 1, 160 do
    self.data[i] = {}
    for j = 1, 50 do
      self.data[i][j] = {["bg"] = Color.DrawBufferBackground, ["fg"] = Color.DrawBufferForeground, ["character"] = "."}
    end
  end
  return self
end

function guiElements.newRadioGroup(x, y, w, callback)
  self = wm.newElement("radio", x, y, w, 1, nil, callback)
  self.drawCallback = drawRadio
  self.background = Color.RadioBackground
  self.foreground = Color.RadioForeground
  self.handleCallback = handleRadio
  return self
end

function guiElements.newList(x, y, w, h, text, callback)
  self = wm.newElement("list", x, y, w, h, text, callback)
  self.drawCallback = drawList
  self.background = Color.ListBackground
  self.foreground = Color.ListForeground
  self.activeBackground = Color.ListActiveBackground
  self.activeForeground = Color.ListActiveForeground
  self.handleCallback = handleList
  return self
end

function guiElements.newInput(x, y, w, text, callback)
  self = wm.newElement("input", x, y, w, 1, text, callback)
  self.drawCallback = drawInput
  self.background = Color.InputBackground
  self.foreground = Color.InputForeground
  self.activeBackground = Color.InputActiveBackground
  self.activeForeground = Color.InputActiveForeground
  self.handleCallback = handleInput
  return self
end

function guiElements.newCheckbox(x, y, text, callback)
  self = wm.newElement("checkbox", x, y, string.len(text) + 4, 1, text, callback)
  self.drawCallback = drawCheckbox
  self.background = Color.CheckboxBackground
  self.foreground = Color.CheckboxForeground
  self.handleCallback = handleCheckbox
  return self
end

function guiElements.newHBar(x, y, w, h)
  self = wm.newElement("hbar", x, y, w, h)
  self.drawCallback = drawHBar
  self.background = Color.HBarBackground
  self.foreground = Color.HBarForeground
  self.handleCallback = generalCallback
  return self
end

function guiElements.newVSlider(x, y, h, callback)
  self = wm.newElement("vslider", x, y, 1, h, "", callback)
  self.drawCallback = drawVSlider
  self.background = Color.VSliderBackground
  self.foreground = Color.VSliderForeground
  self.activeBackground = Color.VSliderActiveBackground
  self.activeForeground = Color.VSliderActiveForeground
  self.handleCallback = handleVSlider
  return self
end

function guiElements.newHSlider(x, y, w, callback)
  self = wm.newElement("hslider", x, y, w, 1, "", callback)
  self.drawCallback = drawHSlider
  self.background = Color.HSliderBackground
  self.foreground = Color.HSliderForeground
  self.activeBackground = Color.HSliderActiveBackground
  self.activeForeground = Color.HSliderActiveForeground
  self.handleCallback = handleHSlider
  return self
end

function guiElements.newFrame(x, y, w, h)
  self = wm.newElement("frame", x, y, w, h - 1)		--FIXME: NO! FUCK IT! Size correction in draw function is more complicated, then this
  self.drawCallback = drawFrame
  self.background = Color.FrameBackground
  self.foreground = Color.FrameForeground
  self.handleCallback = generalCallback
  return self
end

function guiElements.newLine(x, y, w)
  self = wm.newElement("line", x, y, w)
  self.drawCallback = drawLine
  self.background = Color.LabelBackground
  self.foreground = Color.LabelForeground
  self.handleCallback = generalCallback
  return self
end

function guiElements.newLabel(x, y, w, h, text)
  self = wm.newElement("label", x, y, w, h, text)
  self.drawCallback = drawLabel
  self.background = Color.LabelBackground
  self.foreground = Color.LabelForeground
  self.alignment = "left"
  self.handleCallback = generalCallback
  return self
end

function guiElements.newButton(x, y, w, h, text, callback)
  self = wm.newElement("button", x, y, w, h, text, callback)
  self.drawCallback = drawLabel
  self.background = Color.ButtonBackground
  self.foreground = Color.ButtonForeground
  self.activeBackground = Color.ButtonActiveBackground
  self.activeForeground = Color.ButtonActiveForeground
  self.alignment = "center"
  self.handleCallback = handleButton
  return self
end


function guiElements.drawElement(win, self)
  if win.moving == false then
    self.drawCallback(win, self)
  end
end

function guiElements.setElementBackground(self, background)
  self.background = background
end

function guiElements.setElementForeground(self, foreground)
  self.foreground = foreground
end

function guiElements.setElementActiveBackground(self, background)
  self.activeBackground = background
end

function guiElements.setElementActiveForeground(self, foreground)
  self.activeForeground = foreground
end

function guiElements.setElementX(self, x)
  self.x = x
end

function guiElements.setElementY(self, y)
  self.y = y
end

function guiElements.setElementW(self, w)
  self.w = w
end

function guiElements.setElementH(self, h)
  self.h = h
end

function guiElements.setElementText(self, text)
  self.text = text
end

function guiElements.setElementCallback(self, callback)
  self.callback = callback
end

function guiElements.setElementHandleCallback(self, callback)
  self.handleCallback = callback
end

function guiElements.setElementDrawCallback(self, callback)
  self.drawCallback = callback
end

function guiElements.setElementAlignment(self, alignment)
  self.alignment = alignment
end

function guiElements.setElementType(self, type)
  self.type = type
end

function guiElements.newElement(id, x, y, w, h, text)
  return wm.newElement(id, x, y, w, h, text)
end

function guiElements.setElementMax(self, max)
  self.max = max
end

function guiElements.setElementMin(self, min)
  self.min = min
end

function guiElements.setElementValue(self, value)
  self.value = value
end

function guiElements.setElementState(self, state)
  self.state = state
end

function guiElements.setElementSteps(self, steps)
  self.steps = steps
end

function guiElements.setElementAutoWordWrap(self, state)
  self.autoWordWrap = state
end

function guiElements.insertElementData(self, data)
  table.insert(self.data, data)
  self.last = self.last + 1
end

function guiElements.removeElementData(self, num)
  table.remove(self.data, num)
  self.last = self.last - 1
end

function guiElements.changeElementData(self, num, data)
  self.data[num] = data
end

function guiElements.clearElementData(self)
  self.data = {}
  self.last = 1
  self.selected = 1
  self.first = 1
end


function guiElements.getElementBackground(self)
  return self.background
end

function guiElements.getElementForeground(self)
  return self.foreground 
end

function guiElements.getElementActiveBackground(self)
  return self.activeBackground
end

function guiElements.getElementActiveForeground(self)
  return self.activeForeground
end

function guiElements.getElementX(self)
  return self.x
end

function guiElements.getElementY(self)
  return self.y
end

function guiElements.getElementW(self)
  return self.w
end

function guiElements.getElementH(self, h)
  return self.h 
end

function guiElements.getElementText(self)
  return self.text
end

function guiElements.getElementAlignment(self)
  return self.alignment
end

function guiElements.getElementMax(self)
  return self.max
end

function guiElements.getElementMin(self)
  return self.min
end

function guiElements.getElementValue(self)
  return self.value
end

function guiElements.getElementState(self)
  return self.state
end

function guiElements.getElementAutoWordWrap(self)
  return self.autoWordWrap
end

function guiElements.getElementType(self)
  return self.type
end

function guiElements.getLastElement()
  return lastElement
end

function guiElements.setElementIgnoreMouseBlock(self, state)
  self.ignoreMouseBlock = state
end

function guiElements.setElementUserData1(self, data)
  self.userData1 = data
end

function guiElements.setElementUserData2(self, data)
  self.userData2 = data
end

function guiElements.setElementUserData3(self, data)
  self.userData3 = data
end

function guiElements.getElementUserData1(self)
  return self.userData1
end

function guiElements.getElementUserData2(self)
  return self.userData2
end

function guiElements.getElementUserData3(self)
  return self.userData3
end

function guiElements.setElementProtected(self, state)
  self.protected = state
end

function guiElements.getElementProtected(self)
  return self.protected
end

function guiElements.setElementSelected(self, state)
  self.selected = state
end

function guiElements.getElementSelected(self)
  return self.selected
end

function guiElements.getColors()
  return Color
end



local function getFiles(path)
  path = filesystem.canonical(path)
  local ft = {}
  local dt = {}
  for file in filesystem.list(path) do
    if string.sub(file, string.len(file)) == "/" then
      table.insert(dt, file)
    else
      table.insert(ft, file)
    end
  end
  table.sort(ft)
  table.sort(dt)

  local fs = {}
  for k,v in pairs(dt) do
    table.insert(fs,v)
  end
  for k,v in pairs(ft) do
    table.insert(fs,v)
  end
  if path == "/" then
    return fs, nil
  else
    return fs, true
  end
end

local ScreenWidth, screenHeight = gpu.getResolution()

local files, List, Slider, window, selected, running, Path, filenameInput

local function reloadFileList(path)
  files = getFiles(path)
  guiElements.clearElementData(List)
  for i = 1, #files do
    guiElements.insertElementData(List, files[i])
  end
    
  selected = 1
  guiElements.setElementMax(Slider, #files)
  guiElements.setElementValue(Slider, 1)
  guiElements.setElementText(pathLabel, filesystem.canonical(path))
  guiElements.drawElement(window, Slider)
  guiElements.drawElement(window, List)
  guiElements.drawElement(window, pathLabel)
end

local function goBackCallback(self, win)
  if Path ~= "/" then
    Path = string.sub(Path, 1, #Path - Path:reverse():find("/") )		-- go one path back
    reloadFileList(Path)
  end
end

local function listCallback(self, win)
  selected = guiElements.getElementSelected(self)
  newPath = filesystem.canonical(Path .. "/" .. string.sub(files[selected], 1, string.len(files[selected])))
  if filesystem.isDirectory(newPath) then
    Path = newPath
    reloadFileList(Path)
  else
    local FileName = filesystem.name(newPath)
    if FileName == nil then
      FileName = ""
    end
    guiElements.setElementText(filenameInput, FileName)
    guiElements.drawElement(window, filenameInput)
  end
end

function guiElements.fileSelect(param)
  if param == nil then
    param = "Select file"
  end
  local windowWidth = 40
  local windowHeight = 21
  local running = true
  local canceled = false

  window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(screenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight, param)
  wm.disableWindowButtons(window, true)
  wm.hideWindow(window, hideWindowFromList)

  pathLabel = guiElements.newLabel(2, 1, 38, 1, "")
  wm.addElement(window, pathLabel)
  
  wm.addElement(window, guiElements.newLine(1, 2, 38))

  List = guiElements.newList(2, 3, 35, 14, "", listCallback)
  guiElements.clearElementData(List)
  wm.addElement(window, List)
  guiElements.setElementBackground(List, 0xFFFFFF)
  guiElements.setElementActiveBackground(List, 0x202020)
  guiElements.setElementForeground(List, 0x000000)
  guiElements.setElementActiveForeground(List, 0xFFFFFF)

  
  Slider = guiElements.newVSlider(37, 3, 14, function() selected = guiElements.getElementValue(Slider) guiElements.setElementSelected(List, selected) guiElements.drawElement(window, List) end)
  guiElements.setElementMin(Slider, 1)
  guiElements.setElementValue(Slider, 1)
  wm.addElement(window, Slider)
  
  wm.addElement(window, guiElements.newLine(1, 17, 38))
  
  wm.addElement(window, guiElements.newLabel(2, 18, 10, 1, "Filename "))
  filenameInput = guiElements.newInput(11, 18, 27, "")
  wm.addElement(window, filenameInput)
  
  wm.addElement(window, guiElements.newLine(1, 19, 38))

  local upButton = guiElements.newButton(2, windowHeight - 1, 4, 1, "up", goBackCallback)
  wm.addElement(window, upButton)

  local cancelButton = guiElements.newButton(20, windowHeight - 1, 7, 1, "cancel", function()wm.closeWindow(window) canceled = true running = false end)
  wm.addElement(window, cancelButton)

  local selectButton = guiElements.newButton(30, windowHeight - 1, 7, 1, "select", function()wm.closeWindow(window) canceled = false running = false end)
  wm.addElement(window, selectButton)

  reloadFileList("/")
  Path = "/"
  
  wm.raiseWindow(window)
  
  while running == true do
    os.sleep(0.00001)
  end
  if canceled == false then
    return true, filesystem.canonical(Path .. "/" .. guiElements.getElementText(filenameInput))
  else
    return false
  end
end

function guiElements.checkComponent(comp)
  local errorWindowWidth = 40
  local errorWindowHeight = 6
  if component.isAvailable(comp) == false then
  gpu.set(1,2, comp)
    errorWindow = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(errorWindowWidth/2), math.floor(screenHeight/2) - math.floor(errorWindowHeight/2), errorWindowWidth, errorWindowHeight, "Component missing")
    wm.disableWindowButtons(errorWindow, true)
    wm.setWindowSticky(errorWindow, true)
    
    local t = "No " .. comp .. " found"
    local errorLabel = guiElements.newLabel(2, 2, errorWindowWidth - 4, 1, t)
    guiElements.setElementForeground(errorLabel, 0xFF0000)
    guiElements.setElementAlignment(errorLabel, "center")
    wm.addElement(errorWindow, errorLabel)

    local closeButton = guiElements.newButton(math.floor(errorWindowWidth/2) - 4, errorWindowHeight - 1, 7, 1, "close", function() wm.closeWindow(errorWindow) end)
    wm.addElement(errorWindow, closeButton)

    wm.raiseWindow(errorWindow)
    
    return false
  end
  return true
end

return guiElements