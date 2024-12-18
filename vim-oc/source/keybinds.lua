
local keybinds = {}
keybinds.normal = {}

keybinds.normal["i"] = "insertMode"
keybinds.normal[":"] = "commandMode"
keybinds.normal["a"] = "append"

keybinds.normal["h"] = "left"
keybinds.normal["j"] = "down"
keybinds.normal["k"] = "up"
keybinds.normal["l"] = "right"

keybinds.normal["left"] = "left"
keybinds.normal["down"] = "down"
keybinds.normal["up"] = "up"
keybinds.normal["right"] = "right"

keybinds.normal["x"] = "delChar"
keybinds.normal["X"] = "delCharBack"

keybinds.normal["dd"] = "delLine"

keybinds.normal["H"] = "moveHigh"
keybinds.normal["M"] = "moveMiddle"
keybinds.normal["L"] = "moveLow"


keybinds.normal["gg"] = "moveToStart"
keybinds.normal["G"] = "moveToEnd"


keybinds.normal["^e"] = "scrollDown"
keybinds.normal["^y"] = "scrollUp"

return keybinds
