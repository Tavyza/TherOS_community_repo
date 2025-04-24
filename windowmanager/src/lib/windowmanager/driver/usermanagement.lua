local component = require("component")
local gpu = component.gpu
local computer = require("computer")
local modem = component.modem
local wm = require("windowmanager/libs/wm")
local gui = require("windowmanager/libs/guiElements")
local crypt = require("windowmanager/libs/crypt")

local user = {}
local version = "1.0"




-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end


local activeUser = ""
local username = ""
local password = ""
local level = 0

local userPasswordTable = {}

function writePasswd()
  local file = io.open("/etc/windowmanager/passwd","w")
  for i = 1, #userPasswordTable do
    file:write(userPasswordTable[i].user .. ":" .. tonumber(userPasswordTable[i].level) .. ":" .. userPasswordTable[i].password)
  end
  file:close()
end

function cryptPassword(password)
  local k = crypt.string2key(password)
  return crypt.crypt(password,k)
end

function checkPassword(pass, key)
  local k = crypt.string2key(key)
  local p = crypt.crypt(pass, k, true)
  if p == key then
    return true
  end
  return false
end

local function readPasswd()
  userPasswordTable = {}
  local file = "/etc/windowmanager/passwd"
  local lines = lines_from(file)
  
  for key,value in pairs(lines) do
    
    local pos = string.find(value,":")
    local tmpTable ={}

    local us = string.sub(value, 1, pos - 1)
    
    local tmpstr = string.sub(value, pos + 1)
    pos = string.find(tmpstr, ":")
    
    local level = tonumber(string.sub(tmpstr, 1, pos - 1))
    local pw = string.sub(tmpstr, pos + 1)

    tmpTable.user = us
    tmpTable.password = pw
    tmpTable.level = level
  
    table.insert(userPasswordTable, tmpTable)
  end
end

function user.addUser(username, password, level)
  for i = 1, #userPasswordTable do
    if userPasswordTable[i].user == username then
      return false, "user exists"
    end
  end
  computer.removeUser(username)					-- just in case
  r, t = computer.addUser(username)
  if r == true then
    local tmpTable = {}
    tmpTable.user = username
    tmpTable.level = level
    tmpTable.password = cryptPassword(password)
    table.insert(userPasswordTable, tmpTable)
    writePasswd()
    return true
  else
    return r, t
  end
end

function user.remove(username)
  readPasswd()
  for i = 1, #userPasswordTable do
    if userPasswordTable[i].user == username then
      num = i
      break
    end
  end
  if computer.removeUser(username) == true then
    table.remove(userPasswordTable, num)
    writePasswd()
  end
end

function user.changePassword(username, oldPassword, password)
  readPasswd()
  local num = 0
  for i = 1, #userPasswordTable do
    if userPasswordTable[i].user == username then
      if checkPassword(userPasswordTable[i].password, oldPassword) == true then
	num = i
	break
      end
    end
  end
  if num > 0 then
    local tmpTable = {}
    tmpTable.level = userPasswordTable[num].level
    table.remove(userPasswordTable, num)
    tmpTable.user = username
    tmpTable.password = cryptPassword(password)
    table.insert(userPasswordTable, tmpTable)
    writePasswd()
    return true
  end
  return false
end

function user.setLevel(username, level)
  readPasswd()
  local num = 0
  for i = 1, #userPasswordTable do
    if username == userPasswordTable[i].user then
      num = i
      break
    end
  end
  if num > 0 then
    local tmpTable = {}
    tmpTable.password = userPasswordTable[num].password
    table.remove(userPasswordTable, num)
    tmpTable.user = username
    tmpTable.level = level
    table.insert(userPasswordTable, tmpTable)
    writePasswd()
    return true
  end
  return false
end


function user.getLevel(username)
  readPasswd()
  for i = 1, #userPasswordTable do
    return userPasswordTable[i].level
  end
  return -1
end

local function checkUser(username)
  readPasswd()
  for i = 1, #userPasswordTable do
    if username == userPasswordTable[i].user then
      return true
    end
  end
  return false
end

local ScreenWidth, ScreenHeight = gpu.getResolution()


local function loginCallback(self, win)
  if checkUser(username) == true then
    local p, num
    for i = 1, #userPasswordTable do
      if userPasswordTable[i].user == username then
	p = userPasswordTable[i].password
	num = i
	break
      end
    end
    if checkPassword(p, password) == true then
      wm.setUserLevel(tonumber(userPasswordTable[num].level))
      activeUser = username
      wm.setUsername(username)
      gui.setElementText(nameInput, "")
      gui.setElementText(passwordInput, "")
      wm.closeWindow(window)
      wm.blockMouse(false) 
    end
  end
end

function user.getActiveUser()
  return activeUser
end

function user.getUserList()
  readPasswd()
  local tmpTable = {}
  for i = 1, #userPasswordTable do
    local tmp = {}
    tmp.user = userPasswordTable[i].user
    tmp.level =userPasswordTable[i].level
    table.insert(tmpTable, tmp)
  end
  return tmpTable
end
  
local function inputNameCallback(self, win)
  username = gui.getElementText(self)
end

local function inputPasswordCallback(self, win)
  password = gui.getElementText(self)
end

function user.login()
  wm.blockMouse(true)
  
  readPasswd()
  
  local windowWidth = 40
  local windowHeight = 7
  
  local window = wm.newWindow(math.floor(ScreenWidth/2) - math.floor(windowWidth/2), math.floor(ScreenHeight/2) - math.floor(windowHeight/2), windowWidth, windowHeight, "Login")
  wm.disableWindowButtons(window, true)
  wm.setWindowSticky(window, true)

  wm.addElement(window, gui.newLabel(2, 2, 11, 1, "Username :"))
  wm.addElement(window, gui.newLabel(2, 4, 11, 1, "Password :"))
  
  nameInput = gui.newInput(13, 2, 25, "", inputNameCallback)
  passwordInput = gui.newInput(13, 4, 25, "", inputPasswordCallback)
  wm.addElement(window, nameInput)
  gui.setElementProtected(passwordInput, true)
  wm.addElement(window, passwordInput)
  
  
  wm.addElement(window, gui.newLine( 1, 5, windowWidth -2))

  local CloseButton = gui.newButton(math.floor(windowWidth/2) - 3, windowHeight - 1, 5, 1, "login", loginCallback)
  wm.addElement(window, CloseButton)

  wm.raiseWindow(window)
  gui.setElementIgnoreMouseBlock(nameInput, true)
  gui.setElementIgnoreMouseBlock(passwordInput, true)
  gui.setElementIgnoreMouseBlock(CloseButton, true)
  -- wm.blockMouse(false)			nicht vergessen :-)
end

function user.logout()
  wm.setUserLevel(0)
  activeUser = ""
  wm.setUsername("")
  username = ""
  password = ""
  level = 0
  wm.raiseWindow(window)
  wm.blockMouse(true)
end



function user.start()
  wm.registerDriver("user manager", "Handles all user managements, rights and passwords", "S.Kempa", version)
end

function user.stop()
end

return user

