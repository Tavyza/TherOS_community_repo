-- todo: read TherOS config files
-- typically formatted variable:value
-- value can be a string, number, or bool

local tcread = {}

function tcread.getvalue(filepath, var)
  if require("filesystem").exists(filepath) ~= true then
    print("Error reading " .. filepath .. ": No such file or directory")
    return nil
  end

  local f = io.open(filepath, "r")
  if not f then
    print("Error opening " .. filepath)
    return nil
  end

  for line in f:lines() do
    local key, value = line:match("^([^:]+)%s*:%s*(.+)$")
    if key and key == var then
      f:close()
      return value
    end
  end

  f:close()
  return nil
end

return tcread
