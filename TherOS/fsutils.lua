-- filesystem utils

local fs = require("filesystem")
local fsutil = {}
function fsutil.copydir(dir, dest)
  local files = fs.list(dir)
  fs.makeDirectory(dest)
  for file in files do
    fs.copy(dir .. file, dest .. file)
  end
end

function fsutil.movedir(dir, dest)
  fsutil.copydir(dir, dest)
  fsutil.removedir(dir)
end
return fsutil