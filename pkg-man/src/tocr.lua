local shell = require("shell")
local fs    = require("filesystem")
local int   = require("internet")

local args, ops = shell.parse(...)
local function tblstring(table)
	local result = ""
	for i, item in ipairs(table) do
		for j, thing in ipairs(item) do
			result = result .. tostring(thing) .. "\t"
		end
		result = result .. "\n"
	end
	return result
end


local help = [[
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
	local result, response = int.request(url, nil, {["user-agent"]="TOCR/OpenComputers"})
	if result then
		local result, reason = pcall(function()
		for chunk in response do
			if not f then
				f, reason = io.open(file, "w")
			end
			f:write(chunk)
		end
	end)
	f:close()
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
		install_from_internet("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/"..package.."/"..package.."_pkg.tc", "/usr/pkg/" .. package .. "_pkg.tc")
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
		local depend_sources = {}
		local depend_packages = {}
		for line in string.gmatch(data, "[^\r\n]+") do
			if line:match("DEPEND:") then
				table.insert(dependencies, line:match("DEPEND:(.+)$"))
			elseif line:match("DEPEND-source:") then
				table.insert(depend_sources, line:match("DEPEND-source:(.+)$"))
			elseif line:match("DEPEND-package:") then
				table.insert(depend_packages, line:match("DEPEND-package:(.+)$"))
			end
		end
		if dependencies ~= nil and #dependencies > 0 then
			for _, dependency in ipairs(dependencies) do -- reminder: formatted DEPEND:<file> (where the file is in the package folder)
				install_from_internet("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/"..package.."/"..dependency, "/usr/lib/" .. dependency:sub(8)) --trim src/lib/ from the dependency name
			end
		end
		if depend_sources ~= nil and #depend_sources > 0 then
			for _, source in ipairs(depend_sources) do
				local filename = source:match("[^/]+$")
				if filename then
					install_from_internet(source, "/usr/lib/" .. filename)
				end
			end
		end
		-- collapse package table
		local deppacks = ""
		for _, line in ipairs(depend_packages) do
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
			local filename = data:match("PROGRAM-source:(.+)$"):match("[^/]+$")
			if filename then
				install_from_internet(data:match("PROGRAM-source:(.+)$"), "/usr/bin/" .. filename)
			end
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
	local a = io.read()
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
if ops.l or ops.list then
	local handle = int.open("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/")
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
	local compat = io.read()
	print("Copying config files... (3/6)")
	if compat:lower() == "y" then
		fs.copy("/usr/lib/gn-t1compat.tc", "/sys/.config/general.tc")
	else
		fs.copy("/usr/lib/general.tc", "/sys/.config/general.tc")
	end
	fs.copy("/usr/lib/version.tc", "/sys/.config/version.tc")
	print("Copying libraries... (4/6)")
	local libraries = {"conlib.lua", "centertext.lua", "theros.lua", "fsutil.lua"}
	for _, library in ipairs(libraries) do
		print("> " .. library)
		fs.copy("/usr/lib/" .. library, "/lib/" .. library)
	end
	print("Copying apps... (5/6)")
	local apps = {"installer.lua", "program_installer.lua", "file_manager.lua", "manual.lua"}
	for _, app in ipairs(apps) do
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
--installedlist:write(tblstring(packages))
--installedlist:close()
