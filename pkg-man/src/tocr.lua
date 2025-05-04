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

local function install_from_internet(url, file)
  if not int then
    print("Internet component not available.")
    return
  end

  -- make sure we can open the file first
  local f, reason = io.open(file, "a")
  if not f then
    print("Error opening file for writing: " .. reason)
    return
  end
  f:close()
  f = nil

  -- start the download
  local ok, response = pcall(int.request, url, nil, {["user-agent"] = "TOCR/OpenComputers"})
  if not ok then
    print("HTTP request failed: " .. tostring(response))
    return
  end

  local success, err = pcall(function()
    for chunk in response do
      if not f then
        local f2, r2 = io.open(file, "wb")
        assert(f2, "Failed opening file for writing: " .. tostring(r2))
        f = f2
      end
      f:write(chunk)
    end
  end)

  if not success then
    print("Error during download: " .. tostring(err))
    if f then f:close() end
    fs.remove(file)
    return
  end

  if f then
    f:close()
  end
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
	if io.read():lower() == "n" then print("Operation cancelled.") return end
	for _, package in ipairs(args) do
		print("Downloading " .. package .. "...")
		io.write("Fetching package.tc for "..package.."...")
		install_from_internet("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/"..package.."/package.tc", "/usr/pkg/" .. package .. "_pkg.tc")
		if fs.exists("/usr/pkg/" .. package .. "_pkg.tc") then
			print("[DONE]")
		else
			print("\npackage.tc could not be fetched. Please make sure the package exists in the repository.")
			return
		end
		local file = io.open("/usr/pkg/" .. package .. "_pkg.tc", "r")
		data = file:read("*a")
		file:close()
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
			for _, dependency in ipairs(dependencies) do
			  local rel_path = dependency:match("^src/.+/(.+)$") or dependency:sub(8) -- fallback
			  local dir = rel_path:match("(.+)/[^/]+$")
			  if dir then
			    local full_path = "/usr/lib/" .. dir
			    local current = ""
			    for part in full_path:gmatch("[^/]+") do
			      current = current .. "/" .. part
			      if not fs.exists(current) then
			        fs.makeDirectory(current)
			      end
			    end
			  end

			  install_from_internet(
			    "https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/" .. package .. "/" .. dependency,
			    "/usr/lib/" .. rel_path
			  )
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
			install_from_internet("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/"..package.."/"..data:match("PROGRAM:(.+)$"), "/usr/bin/" .. data:match("PROGRAM:(.+)$"):sub(4))
		end
		for line in data:gmatch("[^\r\n]+") do
		  local src = line:match("PROGRAM%-source:(.+)")
		  if src then
		    local filename = src:match("[^/]+$")
		    if filename then
		      install_from_internet(src, "/usr/bin/" .. filename)
		    else
		      print("Failed to identify filename from source: " .. src)
		    end
		  end
		end

		print("[DONE]")
	end
end
if ops.r or ops.remove then
	-- list what we’re about to remove
	io.write("The following packages will be removed: ")
	for _, pkg in ipairs(args) do
	  io.write(pkg, " ")
	end
	io.write("\nDo you want to continue? [y/N] ")
	if io.read():lower() ~= "y" then
	  print("Operation cancelled.")
	  return
	end
  
	for _, pkg in ipairs(args) do
	  local pkgfile = "/usr/pkg/" .. pkg .. "_pkg.tc"
	  local f, err = io.open(pkgfile, "r")
	  if not f then
		print("Cannot open " .. pkgfile .. ": " .. tostring(err))
		goto continue_pkg
	  end
  
	  local data = f:read("*a")
	  f:close()
  
	  -- Extract PROGRAM and PROGRAM-source (if any)
	  local prog_path      = data:match("PROGRAM:(.+)$")
	  local prog_src_path  = data:match("PROGRAM%-source:(.+)$")
  
	  -- Helper to strip directories
	  local function basename(path)
		return path:match("([^/]+)$")
	  end
  
	  -- Remove the main binary
	  if prog_path then
		local bin = basename(prog_path)
		io.write("Removing binary: " .. bin .. " ... ")
		fs.remove("/usr/bin/" .. bin)
		if not fs.exists("/usr/bin/" .. bin) then
		  print("[DONE]")
		else
		  print("[FAILED]")
		end
	  end
  
	  -- Remove any source file
	  if prog_src_path then
		local src = basename(prog_src_path)
		io.write("Removing source: " .. src .. " ... ")
		fs.remove("/usr/bin/" .. src)
		if not fs.exists("/usr/bin/" .. src) then
		  print("[DONE]")
		else
		  print("[FAILED]")
		end
	  end
  
	  -- Finally remove the package descriptor
	  io.write("Cleaning up package file ... ")
	  fs.remove(pkgfile)
	  if not fs.exists(pkgfile) then
		print("[DONE]")
	  else
		print("[FAILED]")
	  end
  
	  ::continue_pkg::
	end
  end  
if ops.l or ops.list then
	install_from_internet("https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/refs/heads/main/repo_list.txt", "/tmp/repo_list.txt")
	local file = io.open("/tmp/repo_list.txt")
	print(file:read("*a"))
	file:close()
	fs.remove("/tmp/repo_list.txt")
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
if ops.a or ops.all then
  print("Listing all installed packages:")
  for file in fs.list("/usr/pkg") do
    print(file)
  end
end
local function parse_version(version)
  local parts = {}
  for part in version:gmatch("[^.]+") do
    table.insert(parts, tonumber(part) or 0)
  end
  while #parts < 3 do
    table.insert(parts, 0)
  end
  return parts
end


local function is_version_newer(local_ver, remote_ver)
  local lv = parse_version(local_ver)
  local rv = parse_version(remote_ver)
  local len = math.max(#lv, #rv)
  for i = 1, len do
    local l = lv[i] or 0
    local r = rv[i] or 0
    if r > l then return true end
    if r < l then return false end
  end
  return false
end

if ops.u or ops.upgrade then
  print("Preparing all packages upgrade...")

  for file in fs.list("/usr/pkg") do
    local pkgname = file:match("^(.-)_pkg%.tc$")
    if pkgname then
      local local_path = "/usr/pkg/" .. file
      local f = io.open(local_path, "r")
      local local_data = f:read("*a")
      f:close()

      local local_version = local_data:match("VERSION:(.+)$")

      local remote_temp = "/tmp/latest_package.tc"
      install_from_internet(
        "https://raw.githubusercontent.com/Tavyza/TherOS_community_repo/main/" .. pkgname .. "/package.tc",
        remote_temp
      )

      if not fs.exists(remote_temp) then
        print("Could not fetch latest info for: " .. pkgname)
        goto continue
      end

      local rf = io.open(remote_temp, "r")
      local remote_data = rf:read("*a")
      rf:close()
      fs.remove(remote_temp)

      local remote_version = remote_data:match("VERSION:(.+)$")

      if not remote_version then
        print("No VERSION in remote package for " .. pkgname .. ", skipping.")
        goto continue
      end

      if not local_version or is_version_newer(local_version, remote_version) then
        print("Upgrading " .. pkgname .. " from " .. (local_version or "unknown") .. " to " .. remote_version .. "...")
        shell.execute("tocr -i " .. pkgname)
      else
        -- Optional: check if dependencies are still present
        print(pkgname .. " is up to date, checking dependencies...")
        for line in remote_data:gmatch("[^\r\n]+") do
          local dep = line:match("DEPEND:(.+)$")
          if dep and not fs.exists("/usr/lib/" .. dep:sub(8)) then
            print("Missing dependency: " .. dep)
            shell.execute("tocr -i " .. pkgname)
            break
          end
        end
      end

      ::continue::
    end
  end

  return
end

--installedlist:write(tblstring(packages))
--installedlist:close()
