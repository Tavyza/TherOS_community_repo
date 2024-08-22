-- config for TherOS
config = {}
configfile = io.read("/sys/.config/general.tc", "r")
fullfile = configfile:read("*a")

config.bkgclr = tonumber(fullfile:match("Bck-clr:%s*(.+)"))

config.txtclr = tonumber(fullfile:match("Txt-clr:%s*(.+)"))

-- 
config.usoclr = tonumber(fullfile:match("Usl-clr:%s*(.+)"))

-- selected option color (for apps that support it)
config.sloclr = tonumber(fullfile:match("Sel-clr:%s*(.+)"))

-- file manager dir color
config.fmdclr = tonumber(fullfile:match("Fmd-clr:%s*(.+)"))

-- file manager file color
config.fmfclr = tonumber(fullfile:match("Fmf-clr:%s*(.+)"))

-- apps directory (ABSOLUTE PATH ONLY)
config.appdir = fullfile:match("App-dir:%s*(.+)")

-- terminal location (ABSOLUTE PATH ONLY)
config.trmdir = fullfile:match("Trm-dir:%s*(.+)")

-- default editor (ABSOLUTE PATH ONLY)
config.editor = fullfile:match("Edt-dir:%s*(.+)")

function config.general()
  return config.bkgclr, config.txtclr, config.usoclr, config.sloclr, config.fmdclr, config.fmfclr, config.appdir, config.trmdir, config.editor
end
-- versions for various system utilities, basically in what version they were updated last
config.sysver = fullfile:match("System:%s*(.+)")
config.inver = fullfile:match("Instll:%s*(.+)") -- installer version
config.fmver = fullfile:match("Filemn:%s*(.+)") -- file manager version
config.ctlibver = fullfile:match("Ctxlib:%s*(.+)") -- center text library version
config.configver = fullfile:match("Config:%s*(.+)")
config.theroslibver = fullfile:match("ThOlib:%s*(.+)")
config.termver = fullfile:match("Termin:%s*(.+)")

function config.version()
  return config.sysver, config.inver, config.fmver, config.ctlibver, config.configver, config.theroslibver, config.termver
end

return config