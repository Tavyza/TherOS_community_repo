local fs = require('filesystem')
local term = require('term')
local shell = require("shell")
local keyboard = require('keyboard')
local keybinds = require('keybinds')

local gpu = term.gpu()
local args, options = shell.parse(...)

--------------------------------------------------------------------------------

local modes = {NORMAL=0, INSERT=1, COMMAND=2}

local mode = modes.NORMAL

local buffer = {}

local cursorX, cursorY = 1, 1 -- where on screen is the cursor
local actualX, actualY = 1, 1 -- where in buffer is the cursor
local scrollX, scrollY = 0, 0

local motion = 1 -- how many times to repeat an action

local keybind = ""
local command = ""

local currentFilename = ""

local _, _, w, h = term.getGlobalArea() -- get width and height of the terminal
h = h - 1 -- leave space for bottom bar

local readonly = false -- is the file being edited read only (ro filesystem or no permission)
local changed = false -- is the file was changed since load

local running = true

local ctrl, shift, alt = false, false, false -- is the control keys are pressed

--------------------------------------------------------------------------------

function string.insert(str1, str2, pos)
    return str1:sub(1,pos)..str2..str1:sub(pos+1)
end

--------------------------------------------------------------------------------

local function redrawLine(line)
    local y = line-scrollY
    local len = #buffer[line]
    gpu.set(1, y, buffer[line])
    gpu.fill(len+1, y, w-len, 1, ' ')
end

local function redrawAll()
    local lines = #buffer
    for y=1+scrollY,math.min(lines,h+scrollY) do
        redrawLine(y)
    end
    local last = lines-scrollY
    if last < h then
        gpu.fill(1, last+1, 1, h-last, '~')
        gpu.fill(2, last+1, w-1, h-last, ' ')
    end
end

--------------------------------------------------------------------------------

local function setStatus(status)
    gpu.set(1,h+1, status)
    local x = #status
    gpu.fill(x+1, h+1, w-x, 1, ' ')
end

local function setStatusError(err)
    local bg, fg = gpu.getBackground(), gpu.getForeground()
    gpu.setBackground(0xff0000)
    gpu.setForeground(0xffffff)

    setStatus(err)

    gpu.setBackground(bg) -- put back what was there before
    gpu.setForeground(fg)
end

local function updateStatusPos()
    gpu.fill(w-7, h+1, 7, 1, ' ')
    gpu.set(w-7, h+1, actualY .. ',' .. actualX)
end

local function updateStatusKeybind()
    gpu.fill(w-14, h+1, 7, 1, ' ')
    gpu.set(w-14, h+1, keybind)
end

--------------------------------------------------------------------------------

local function setActualCursor(newActualX, newActualY, ignoreChecks, append)
    if ignoreChecks then
        actualX, actualY = newActualX, newActualY
    else
        if newActualY > #buffer then
            newActualY = #buffer
        end
        if newActualY < 1 then
            newActualY = 1
        end
        actualY = newActualY

        if newActualX > #buffer[actualY] then
            if append then
                newActualX = #buffer[actualY]+1
            else
                newActualX = #buffer[actualY]
            end
        end
        if newActualX < 1 then
            newActualX = 1
        end

        actualX = newActualX
    end

    cursorX = actualX-scrollX
    cursorY = actualY-scrollY

    if cursorY < 1 then
        cursorY = 1
        scrollY = scrollY-1
        redrawAll()
    end
    if cursorY > h then
        cursorY = h
        scrollY = scrollY+1
        redrawAll()
    end

    term.setCursor(cursorX, cursorY)
    updateStatusPos()
end

local function moveActualCursor(x, y, append)
    setActualCursor(actualX+x, actualY+y, false, append)
end

local function setScreenCursor(newCursorX, newCursorY)
    local newActualY = newCursorY + scrollY
    local newActualX = newCursorX + scrollX

    if newActualY > #buffer then
        newActualY = #buffer
    end
    actualY = newActualY

    if newActualX > #buffer[actualY] then
        newActualX = #buffer[actualY]
    end
    actualX = newActualX

    cursorX = actualX-scrollX
    cursorY = actualY-scrollY

    term.setCursor(cursorX, cursorY)
    updateStatusPos()
end

--------------------------------------------------------------------------------

local function onClipboard(value) -- TODO: implement function

end

local function readFromFile(filename)
    local f = io.open(filename)
    if f then
        for line in f:lines() do
            table.insert(buffer, line)
        end
        f:close()

    end
    setActualCursor(1, 1, true)
end

local function writeToFile(filename)
    local f = io.open(filename, "w")
    for _,line in ipairs(buffer) do
        f:write(line .. "\n")
    end
    f:close()
end

--------------------------------------------------------------------------------

local functions = {
    normalMode = function()
        mode = modes.NORMAL
        setStatus("--NORMAL--")
        term.setCursor(cursorX, cursorY)
    end,
    insertMode = function()
        mode = modes.INSERT
        setStatus("--INSERT--")
    end,
    commandMode = function()
        mode = modes.COMMAND
        command = ""
        setStatus(":")
        term.setCursor(2, h+1)
    end,

    append = function()
        mode = modes.INSERT
        setStatus("--INSERT--")
        setActualCursor(actualX + 1, actualY, true)
    end,

    left = function()
        moveActualCursor(-1,0)
    end,
    down = function()
        moveActualCursor(0,1)
    end,
    up = function()
        moveActualCursor(0,-1)
    end,
    right = function()
        moveActualCursor(1,0)
    end,

    delChar = function()
        local line = buffer[actualY]
        buffer[actualY] = line:sub(1, actualX-1) .. line:sub(actualX+1, #line)
        changed = true
        redrawLine(actualY)
        if actualX > #buffer[actualY] then
            moveActualCursor(-1, 0)
        end
    end,
    delCharBack = function()
        if actualX == 1 then return end
        local line = buffer[actualY]
        buffer[actualY] = line:sub(1, actualX-2) .. line:sub(actualX, #line)
        changed = true
        redrawLine(actualY)
        moveActualCursor(-1, 0)
    end,

    scrollDown = function() -- (content moves up)
        if scrollY < #buffer-1 then
            --gpu.copy(1, 2, w, h-1, 0, -1)
            --gpu.set(1, h, '~')
            --gpu.fill(2, h, w, 1, ' ')
            scrollY = scrollY + 1
            setActualCursor(actualX, actualY + 1, false)
            redrawAll()
        end
    end,
    scrollUp = function() -- (content moves down)
        if scrollY > 0 then
            scrollY = scrollY - 1
            setActualCursor(actualX, actualY - 1, false)
            --gpu.copy(1, 1, w, h-1, 0, 1)
            --redrawLine(actualY-scrollY) -- first line on screen
            redrawAll()
        end
    end,

    moveToStart = function()
        setActualCursor(actualX, 1, false)
        --scrollX = 0
        scrollY = 0
        redrawAll()
    end,
    moveToEnd = function()
        scrollY = #buffer - h
        if scrollY < 0 then
            scrollY = 0
        end
        setActualCursor(actualX, #buffer, false)
        redrawAll()
    end,
    moveHigh = function()
        setScreenCursor(cursorX, 1)
    end,
    moveMiddle = function()
        setScreenCursor(cursorX, math.floor(h/2))
    end,
    moveLow = function()
        setScreenCursor(cursorX, h)
    end,
}

--------------------------------------------------------------------------------

local function onKeyNormal(char, code)
    local key = keyboard.keys[code]

    if keyboard.keys[code] == 'tab' then
        keybind = ""
        updateStatusKeybind()
        return
    end

    if ctrl then
        keybind = keybind .. "^"
    end
    if alt then
        keybind = keybind .. "<alt>"
    end

    local ch = string.char(char)

    -- TODO: not really working correctly (shift + numbers)
    if not keyboard.isControl(char) then
        keybind = keybind .. ch
    else
        keybind = keybind .. key
    end


    local fn
    fn = functions[keybinds.normal[keybind]]
    if fn then
        fn()
        keybind = ""
    end
    updateStatusKeybind()
end

local function onKeyInsert(char, code)

    if not keyboard.isControl(char) then
        buffer[actualY] = string.insert(buffer[actualY], string.char(char), actualX-1)
        changed = true
        moveActualCursor(1, 0, true)
        redrawLine(actualY)
    else
        if keyboard.keys[code] == 'tab' then
            functions.normalMode()
            if actualX > #buffer[actualY] then
                moveActualCursor(-1, 0)
            end
        elseif keyboard.keys[code] == 'enter' then
            local beforeCursor = string.sub(buffer[actualY], 0, actualX-1)
            local afterCursor = string.sub(buffer[actualY], actualX, #buffer[actualY])

            buffer[actualY] = beforeCursor
            table.insert(buffer, actualY+1, afterCursor)

            gpu.copy(1, cursorY+1, w, h-cursorY-1, 0, 1) -- move text down to make space for the new line
            gpu.fill(1, cursorY+1, w, 1, ' ')

            redrawLine(actualY)
            redrawLine(actualY+1)

            setActualCursor(0, actualY+1, false)
        elseif keyboard.keys[code] == 'back' then
            functions.delCharBack()
            --local line = buffer[actualY]
            --buffer[actualY] = line:sub(1, actualX-2) .. line:sub(actualX, #line)
            --redrawLine(actualY)
        end
    end

end

local function onKeyCommand(char, code)

    -- exit command mode
    if keyboard.keys[code] == 'tab' then
        functions.normalMode()
        return
    end

    -- execute command
    if keyboard.keys[code] == 'enter' then

        -- quit
        if command:sub(1,1) == 'q' then
            if changed then
                if command:sub(2,2) == '!' then
                    running = false
                    return
                else
                    command = ""
                    functions.normalMode()
                    setStatusError("No write since last change (add ! to override)")
                    return
                end
            else
                running = false
            end

        -- write
        elseif command:sub(1,1) == 'w' then
            -- TODO: different filename as param
            if readonly then
                setStatusError("File is read only")
            else
                writeToFile(currentFilename)
                changed = false

                if command:sub(2,2) == 'q' then
                    running = false
                    return
                end
            end

    -- edit a different file
        elseif command:sub(1,1) == 'e' then
        end

        command = ""
        functions.normalMode()
        return
    end

    -- append typed char to command
    if not keyboard.isControl(char) then
        command = command .. string.char(char)
    else
        if keyboard.keys[code] == 'back' then
            command = command:sub(1, -2)
        end
    end
    setStatus(":" .. command)
    term.setCursor(#command+2, h+1)
end

local function onKeyDown(char, code)
    --print('Key down: ' .. string.char(char) .. "," .. keyboard.keys[code])
    if keyboard.keys[code] == 'lcontrol' then
        ctrl = true
    elseif keyboard.keys[code] == 'lshift' then
        shift = true
    elseif keyboard.keys[code] == 'lmenu' then
        alt = true

    elseif mode == modes.NORMAL then
        onKeyNormal(char, code)
    elseif mode == modes.INSERT then
        onKeyInsert(char, code)
    elseif mode == modes.COMMAND then
        onKeyCommand(char, code)
    end
end

local function onKeyUp(char, code)
    if keyboard.keys[code] == 'lcontrol' then
        ctrl = false
    elseif keyboard.keys[code] == 'lshift' then
        shift = false
    elseif keyboard.keys[code] == 'lmenu' then
        alt = false
    end
end

--------------------------------------------------------------------------------

term.clear()
term.setCursorBlink(true)


-- if a filename was passed in as argument
if #args == 1 then
    currentFilename = shell.resolve(args[1])
    local file_parentpath = fs.path(currentFilename)

    if fs.exists(file_parentpath) and not fs.isDirectory(file_parentpath) then
        io.stderr:write(string.format("Not a directory: %s\n", file_parentpath))
        return 1
    end

    readonly = options.r or fs.get(currentFilename) == nil or fs.get(currentFilename).isReadOnly()

    if fs.isDirectory(currentFilename) then
        io.stderr:write("file is a directory\n")
        return 1
    elseif not fs.exists(currentFilename) and readonly then
        io.stderr:write("file system is read only\n")
        return 1
    end

    if not fs.exists(currentFilename) then
        table.insert(buffer, "")
        setStatus(string.format([["%s" [New File] ]], currentFilename))
    else
        readFromFile(currentFilename)

        if readonly then
            setStatus(string.format([["%s" [readonly] %dL]], currentFilename, #buffer))
        else
            setStatus(string.format([["%s" %dL]], currentFilename, #buffer))
        end
    end
else
    -- if no filename was passed as argument, add an empty line to buffer
    table.insert(buffer, "")
    setStatus(" [New File] ")
end

redrawAll()
setActualCursor(1,1,true)

--------------------------------------------------------------------------------

while running do
  local event, address, arg1, arg2, _ = term.pull()
  if address == term.keyboard() or address == term.screen() then
    if event == "key_down" then
      onKeyDown(arg1, arg2)
    elseif event == "key_up" then
      onKeyUp(arg1, arg2)
    elseif event == "clipboard" and not readonly then
      onClipboard(arg1)
    end
  end
end

--------------------------------------------------------------------------------

term.clear()
term.setCursorBlink(true)
