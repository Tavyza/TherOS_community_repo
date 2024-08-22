local fs = require("filesystem")
local t = require("term")
local gpu = require("component").gpu
local e = require("event")
local kb = require("keyboard")
local shell = require("shell")
local ct = require("centertext")
local th = require("theros")
local fsu = require("fsutils")
local bkgclr, txtclr, _, _, fmdclr, fmfclr, _, trmdir, editor = require("conlib").general()

local w, h = gpu.getResolution()
::inthebeginning::
gpu.setBackground(bkgclr)

local currentDir = "/" -- sets to root dir at first, might change later

local function listFiles(currentDir)
  local files = {"../"}
  for file in fs.list(currentDir) do
    table.insert(files, file)
  end
  table.sort(files)
  return files
end
startline = 3
scrollpos = 0
_, _, _, scroll = e.pull("scroll") -- pulls scroll event

local function displayFiles(files, currentDir) -- function to print out all files in the working directory
  t.clear()
  header = "File manager 1.1 -- " .. currentDir
  maxlines = h - startline - 1
  start = scrollpos + 1
  dend = math.min(scrollpos + maxlines, #files)

  for i = start, dend do -- this just goes through the table
    local file = files[i]
    local fullPath = fs.concat(currentDir, file)
    if fs.isDirectory(fullPath) then
      color = fmdclr
    else
      color = fmfclr
    end
    ct(3 + (i - start), file, color) -- well this just... prints the files
  end
end

local function getpath(currentDir, file)
  if file == "../" then
    return fs.path(currentDir)
  else
    return fs.concat(currentDir, file)
  end
end

local function close()
  ct(h - 1, "Exit")
end
require("computer").pushSignal("scroll", 1)
while true do -- loop to keep the program running
  local files = listFiles(currentDir)
  displayFiles(files, currentDir)
  close()
  th.dwindow(1, 1, w, h, "File manager 1.1 -- " .. currentDir)
  local ev, _, _, y, direction = e.pull()
  if ev == "scroll" then
    if direction == 1 and scrollpos > 0 then
      scrollpos = scrollpos - 1
    elseif direction == -1 and scrollpos < #files - (h - startline - 1) then
      scrollpos = scrollpos + 1
    end
  elseif ev == "touch" then 
    if y == h - 1 then
      break
    end
    local choice = y + (scrollpos - 2)
    if choice >= 1 and choice <= #files then
      local selectedFile = getpath(currentDir, files[choice])
      print(selectedFile) -- outputting selected file so you know what you clicked
      if fs.isDirectory(selectedFile) then
        if kb.isKeyDown(0x2A) then -- shift key
          local options = {"Open", "Copy", "Move/Rename", "Delete"}
          local startLine = h / 2 - (#options / 2)
          for i, option in ipairs(options) do
            ct(startLine + (i - 1) * 2, option)
          end

          local _, _, _, yOption = e.pull("touch")
          yOption = yOption + 1
          local optionChoice = math.floor((yOption - startLine) / 2) + 1

          if optionChoice == 1 then
            currentDir = selectedFile
          elseif optionChoice == 2 then
            local input = th.popup("Copy", "input", "Enter copy destination")
          fsu.copydir(selectedFile, input)
          elseif optionChoice == 3 then
            local input = th.popup("MOVE", "input", "Type new name/location: ")
            fsu.movedir(selectedFile, input)
          elseif optionChoice == 4 then
            local confm = th.popup("Delete directory (y/N)", "input", "Are you sure you want to delete " .. selectedFile .. "? This action cannot be reversed!")
            if confm == "y" then
              local ok, err = fs.remove(selectedFile)
              if not ok then
                th.popup("ERROR", "err", "Error removing directory: " .. err)
              end
            end
          end
        else
          currentDir = selectedFile
        end
      else
        local options = {"Run", "Edit", "Copy", "Move/Rename", "Delete"}
        local startLine = h / 2 - (#options / 2)
        for i, option in ipairs(options) do
          ct(startLine + (i - 1) * 2, option)
        end

        local _, _, _, yOption = e.pull("touch")
        yOption = yOption + 1
        local optionChoice = math.floor((yOption - startLine) / 2) + 1

        if optionChoice == 1 then -- run
          local good, err = th.run(selectedFile)
          if not good and err then
            th.popup("ERROR", "err", err)
          end
        elseif optionChoice == 2 then -- edit
          local ok, err = shell.execute(editor .. " " .. selectedFile)
          if not ok then
            th.popup("ERROR", "err", "Error editing file: " .. err)
          end
        elseif optionChoice == 3 then -- copy
          local input = th.popup("Copy", "input", "Enter copy destination")
          local ok, err = fs.copy(selectedFile, input)
          local err = "Error message could not load! You probably tried to copy to a directory that doesn't exist."
          if not ok then
            th.popup("ERROR", "err", "Error renaming file: " .. err)
          end
        elseif optionChoice == 4 then -- move
          local input = th.popup("MOVE", "input", "Type new name/location: ")
          local ok, err = fs.rename(selectedFile, input)
          if not ok then
            th.popup("ERROR", "err", "Error renaming file: " .. err)
          end
        elseif optionChoice == 5 then -- delete
          local input = th.popup("Delete file (y/N)", "input", "Are you sure you want to delete " .. selectedFile .. "? This action cannot be reversed!")
          if input == "y" then
            local ok, err = fs.remove(selectedFile)
            if not ok then
              th.popup("ERROR", "err", "Error removing file: " .. err)
            end
          else
            ct((h / 2) + 5, "Error deleting " .. selectedFile .. ": Deletion cancelled", 0xFF0000)
            no = io.read()
          end
        end
      end
    else
      local options = {"New File", "New Directory"}
      local startLine = h / 2 - (#options * 2)
      for i, option in ipairs(options) do
        ct(startLine + (i - 1) * 2, option)
      end

      local _, _, _, yOption = e.pull("touch")
      local optionChoice = math.floor((yOption - startLine) / 2) + 1

      if optionChoice == 1 then -- new file
        local newfile = th.popup("New file", "input", "Name of new file: ")
        local file, err = fs.open(fs.concat(currentDir, newfile), "w")
        if not file then
          th.popup("ERROR", "err", "Error making file: " .. err)
        end
        file:close()
      elseif optionChoice == 2 then -- new dir
        local newdir = th.popup("New directory", "input", "New directory name: ")
        local ok, err = fs.makeDirectory(fs.concat(currentDir, newdir))
        if not ok then
          th.popup("ERROR", "err", "Error making dir: " .. err)
        end
      end
    end
  end
end
