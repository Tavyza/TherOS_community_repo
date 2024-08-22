-- TherOS text centering library
local gpu = require("component").gpu
local conf = require("conlib")

local w, h = gpu.getResolution()
local _, txtclr, _, _, _, _, _, _ = conf.general()
centertext = {}
function centertext(y, text, color)
  if text ~= nil then
    color = color or txtclr
    gpu.setForeground(color)
    gpu.set((w/2)-(#text/2), y, text)
  else
    print("nil value")
  end
end
return centertext