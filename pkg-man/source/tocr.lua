local shell = require("shell")
local fs    = require("filesystem")

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
tocr -u, --upgrade              -- upgrades all installed packages
tocr -l, --list                 -- list all repository packages
tocr -a, --all                  -- list all installed packages
tocr -b, --build                -- build a TherOS system from theros-core and theros-apps

Internet card required to install/update/list repository.
Local packages may become a thing later on.
]]

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
	if io.read() == "n" then return end 
	print("Installing...")
	io.write("Checking for dependencies...")
	for _, package in ipairs(args) do
		shell.execute("wget -f -q https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/" .. package .. "/dependencies.tc /tmp/dependencies.tc")
	end
	print("[DONE]")
	io.write("Reading...")
	dependf = io.open("/tmp/dependencies.tc")
	depends = dependf:read("*a")
	dependf:close()
	if depends ~= nil or depends ~= "" then
		for line in string.gmatch(depends, "[^\r\n]+") do
			print(line)
			shell.execute("wget -f -q " .. line .. " /usr/lib/" .. line:match("^.+/(.+)$"))
		end
	else
		print("No dependencies.")
	end
	newpacks = {}
	for i, package in ipairs(args) do
		shell.execute("wget -f -q https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/" .. package .. "/package.tc /usr/pkg/" .. package .. "_pkg.tc")
		table.insert(newpacks, package .. "_pkg.tc")
		if not fs.exists("/usr/pkg/" .. package .. "_pkg.tc") then
			print("Package " .. package .. " not found.")
		end
	end
	local packagefile
	io.write("Beginning installation...")
	for i, package in ipairs(newpacks) do
		file = io.open("/usr/pkg/" .. package)
		if file then
			packagefile = file:read("*a")
		else
			print("Where is the package file?")
			return
		end
		file:close()
		for line in string.gmatch(packagefile, "[^\r\n]+") do
			io.write("Installing " .. line .. "...")
			local name = line:match("^.+/(.+)$")
			shell.execute("wget -f -q " .. line .. " /usr/bin/" .. name)
			if fs.exists("/usr/bin/" .. name) then
				print("[DONE]")
				for _, item in ipairs(newpacks) do
					table.insert(packages, item)
				end 
			else
				print("Package failed to install.")
			end
		end
	end
end
if ops.a or ops.all then
	print("Installed packages: ")
	for file in fs.list("/usr/pkg/") do
		print(file)
	end
end
if ops.l or ops.list then
	shell.execute("wget -f -q https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/repo_list.tc /tmp/repo_list.tc")
	file = io.open("/tmp/repo_list.tc")
	print(file:read("*a"))
	file:close()
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
		fs.copy("/usr/lib/gn_t1compat.tc", "/sys/.config/general.tc")
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
end
installedlist:write(tblstring(packages))
installedlist:close()