local shell = require("shell")
local fs    = require("filesystem")
local int   = require("internet")

local args, ops = shell.parse(...)
local function tblstring(table)
	result = ""
	for i, item in ipairs(table) do
		for j, thing in ipairs(item) do
			result = result .. tostring(thing) .. "\t"
		end
		result = result .. "\n"
	end
end
installedlist = io.open("/etc/packlist.tc", "w")
packages = {}
packlist = installedlist:read("*a")
if not packlist == "" or not packlist == nil then
	for _, package in ipairs(string.gmatch(packlist, "[^\r\n]+")) do
		table.insert(packages, package)
	end
end

help = [[
TherOS Community Repository (TOCR) Package Manager
Usage:
tocr -i, --install (package(s)) -- Installs the specified packages
tocr -r, --remove (package(s))  -- removes the specified packages from the system
tocr -s, --search (package)     -- searches for a package in the repository
tocr -u, --upgrade              -- upgrades all installed packages
tocr -l, --list                 -- list all repository packages
tocr -a, --all                  -- list all installed packages
tocr -h, --help                 -- displays this help message


Internet card required to install/update/list repository.
]]
--[[
package.tc layout:
VERSION:<version>
NAME:<package name>  the name of the package, decides what the package file is named when downloaded (example: tnal would produce a package file named tnal_pkg.tc)
DESC:<description>  a short description of the package

PROGRAM:<file>  the program the package puts in /usr/bin
PROGRAM-source:<url> alternatively, you can give a url instead of hosting it in the repo
DEPEND / DEPEND-source  same as PROGRAM, but these files install to /usr/lib
]]
local function install_from_internet(url, file)
	local handle = int.open(url)
	local data = handle:read("*a")
	handle:close()
	file = io.open(file, "w")
	file:write(data)
	file:close()
end
if ops.h or ops.help or not next(ops) then
	print(help)
end
if ops.i or ops.install then
	fs.makeDirectory("/usr/bin")
	fs.makeDirectory("/usr/lib")
	fs.makeDirectory("/usr/pkg")
	print("You are installing the following packages: ")
	for _, package in ipairs(args) do
		print(package)
	end
	io.write("Do you want to continue? [Y/n]")
	if io.read():lower() ~= "y" then print("Operation cancelled.") return end
	for _, package in ipairs(args) do
		print("Downloading " .. package .. "...")
		io.write("Fetching package.tc for "..package.."...")
		local handle = int.open("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/"..package.."/package.tc") -- fetch the package file
		local data = handle:read("*a") -- read
		handle:close()
		file = io.open("/usr/pkg/" .. package .. "_pkg.tc", "w") -- push the package file contents to a local file
		file:write(data)
		file:close()
		if fs.exists("/usr/pkg/" .. package .. "_pkg.tc") then
			print("[DONE]")
		else
			print("\npackage.tc could not be fetched. Please make sure the package exists in the repository.")
			return
		end
		-- we still have the package.tc in the data variable, so let's use that
		local version = data:match("VERSION:(.+)$")
		local name = data:match("NAME:(.+)$")
		local desc = data:match("DESC:(.+)$")
		-- now we read the dependencies and install them
		io.write("Downloading dependencies...")
		local dependencies = {}
		local depend-sources = {}
		local depend-packages = {}
		for line in string.gmatch(data, "[^\r\n]+") do
			if line:match("DEPEND:") then
				table.insert(dependencies, line:match("DEPEND:(.+)$"))
			elseif line:match("DEPEND-source:") then
				table.insert(sources, line:match("DEPEND-source:(.+)$"))
			elseif line:match("DEPEND-package:") then
				table.insert(depend-packages, line:match("DEPEND-package:(.+)$"))
			end
		end
		if dependencies ~= nil or #dependencies ~= 0 then
			for i, dependency in ipairs(dependencies) do -- reminder: formatted DEPEND:<file> (where the file is in the package folder)
				install_from_internet("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/"..package.."/"..dependency, "/usr/lib/" .. dependency:sub(8)) --trim src/lib/ from the dependency name
			end
		end
		if sources ~= nil or #sources ~= 0 then
			for i, source in ipairs(depend-sources) do
				install_from_internet(source, "/usr/lib/" .. ) -- todo: match the file name in the source url
			end
		end
		-- collapse package table
		deppacks = ""
		for i, line in ipairs(depend-packages) do
			deppacks = deppacks .. " " .. line
		end
		if deppacks ~= "" then
			shell.execute("tocr -i" .. deppacks) -- install dependency packages
		end
	end
	for _, package in ipairs(args) do
		io.write("Installing " .. package .. "...")
		if data:match("PROGRAM:(.+)$") then
			install_from_internet("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/"..package.."/"..data:match("PROGRAM:(.+)$"), "/usr/bin/" .. data:match("PROGRAM:(.+)$")) -- match filename after last slash
		end
		if data:match("PROGRAM-source:(.+)$") then
			install_from_internet(data:match("PROGRAM-source:(.+)$"), "/usr/bin/" .. data:match("PROGRAM-source:(.+)/(.-)$"):match("[^/]+$")) -- match filename after last slash		
		end
		print("[DONE]")
	end
end
if ops.r or ops.remove then
	print("The following packages will be removed: ")
	for _, arg in ipairs(args) do
		print(arg)
	end
	io.write("Do you want to continue? [y/N]")
	a = io.read()
	if a:lower() ~= "y" then print("cancelled") return end
	for _, package in ipairs(args) do
		file = io.open("/usr/pkg/" .. package .. "_pkg.tc", "r")
		contents = file:read("*a")
		file:close()
		for line in string.gmatch(contents, "[^\r\n]+") do
			local name = line:match("^.+/(.+)$")
			io.write("Removing " .. name)
			fs.remove("/usr/bin/" .. name)
			if not fs.exists("/usr/bin/" .. name) then
				print("[DONE]")
				fs.remove("/usr/pkg/" .. package .. "_pkg.tc")
			else
				print("[FAILED]")
			end
		end
	end
end
if ops.b or ops.build then
	print("Preparing to build TherOS...")
	print("Looking for theros-core and theros-apps packages. (1/6)")
	if not fs.exists("/usr/pkg/theros-core_pkg.tc") then
		print("Not found theros-core_pkg.tc")
		shell.execute("tocr -i theros-core")
	end
	if not fs.exists("/usr/pkg/theros-apps_pkg.tc") then
		print("Not found theros-apps_pkg.tc")
		shell.execute("tocr -i theros-apps")
	end

	print("Creating directories... (2/6)")
	print("> /sys/apps...")
	fs.makeDirectory("/sys/apps/")
	print("> /sys/.config...")
	fs.makeDirectory("/sys/.config/")
	print("> /sys/env...")
	fs.makeDirectory("/sys/env/")
	print("> /sys/util...")
	fs.makeDirectory("/sys/util/")
	io.write("Tier 1/2 compatibility? [y/n]")
	compat = io.read()
	print("Copying config files... (3/6)")
	if compat:lower() == "y" then
		fs.copy("/usr/lib/gn-t1compat.tc", "/sys/.config/general.tc")
	else
		fs.copy("/usr/lib/general.tc", "/sys/.config/general.tc")
	end
	fs.copy("/usr/lib/version.tc", "/sys/.config/version.tc")
	print("Copying libraries... (4/6)")
	libraries = {"conlib.lua", "centertext.lua", "theros.lua", "fsutil.lua"}
	for i, library in ipairs(libraries) do
		print("> " .. library)
		fs.copy("/usr/lib/" .. library, "/lib/" .. library)
	end
	print("Copying apps... (5/6)")
	apps = {"installer.lua", "program_installer.lua", "file_manager.lua", "manual.lua"}
	for i, app in ipairs(apps) do
		print("> " .. app)
		fs.copy("/usr/bin/" .. app, "/sys/apps/" .. app)
	end
	print("Copying env, therterm, boot... (6/6)")
	fs.copy("/usr/bin/main.lua", "/sys/env/main.lua")
	fs.copy("/usr/bin/therterm.lua", "/sys/util/therterm.lua")
	fs.copy("/usr/bin/94_therboot.lua", "/boot/94_therboot.lua")
	io.write("Done. Reboot? [Y/n]")
	local yn = io.read()
	if yn:lower() ~= "n" then
		print("Rebooting...") 
		require("computer").shutdown(true)
	end
end
if ops.u or ops.upgrade then
	print("Preparing system upgrade...")
	print("[ERROR] FUNCTION NOT COMPLETED YET")
	return
end
installedlist:write(tblstring(packages))
installedlist:close()
