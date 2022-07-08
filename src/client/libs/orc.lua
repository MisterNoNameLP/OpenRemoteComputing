local orc = {
	version = "v0.3.3d",
	RC = {}, --RemoteComputer
	
	conf = { --default config
		timeout = 10,

		prefix = {
			public = "ORC_PBCP",
			biosControl = "ORC_BCP", --network communication prefix (simple network BIOS)
			biosDebug = "ORC_BDCP", --debug network communication prefix (simple network BIOS debugging)

			loaderControl = "ORC_LCP", --high level network communication prefix (loader script)
			loaderDebug = "ORC_LDCP", --high level debug network communication prefix (loader script)

			userDebug = "ORC_UCP", --user lvevel network communication prefix
		},
	},
	dev = {
		remoteScript = "libs/orcLoader.lua",
		stdLib = "libs/orcStdLib.lua",
	},
}

local minitel = require("minitel")
local computer = require("computer")
local unicode = require("unicode")
local event = require("event")
local modem = require("component").modem
local ut = require("UT")

--===== local functions =====--
local function getScript()
	local script = ""
	
	if orc.dev.remoteScript ~= nil then
		--[[local file = io.open(orc.dev.remoteScript, "r")
		script = file:read("*a")
		file:close()
		]]
		return ut.readFile(orc.dev.remoteScript)
	else
		script = [[
			computer.beep()
			computer.beep(600)
			computer.beep()
		]]
	end
	
	return script
end

--===== basic functions =====--
function orc.get(port, timeout, pncp)
	pncp = pncp or orc.conf.prefix.public .. "::"
	timeout = timeout or orc.conf.timeout
	local ptime = computer.uptime()
	local remoteComputers = {}
	
	if type(port) ~= "number" then
		error("No valid port given", 2)
	end
	
	modem.open(port)
	
	modem.broadcast(port, pncp, "get")
	
	while computer.uptime() - ptime < timeout do
		local _, _, address, _, _, prefix, reason, hostname, biosVersion = event.pull(timeout - (computer.uptime() - ptime), "modem_message")
		if prefix == pncp and reason == "get" then
			remoteComputers[hostname] = {address = address, port = port, hostname = hostname, biosVersion = biosVersion}
		end
	end
	
	return remoteComputers
end

function orc.getVersion()
	return orc.version
end

--===== remote computer =====--
function orc.RC.new(rc, conf)
	local self = setmetatable({}, {__index = orc.RC}) 
	conf = conf or {}
	
	self.remoteComputer = rc

	self.stream = {}

	self.prefix = {}

	self.biosStatus = ""
	self.loaderStatus = ""
	self.currentCommunicationPrefix = self.prefix.biosControl --the last communication prefix sended in the stream. used to assign new msgs to the proper log journey.
	
	self.log = {} --table containing all different logs.

	self.executionsQueued = 0

	--=== init ===--
	--create own prefix table
	if type(conf.prefix) ~= "table" then
		conf.prefix = {}
	end

	for purpose, prefix in pairs(orc.conf.prefix) do
		if conf.prefix[purpose] ~= nil then
			self.prefix[purpose] = conf.prefix[purpose] .. "::"
		else
			self.prefix[purpose] = prefix .. "::"
		end
	end
	
	--establish control stream
	modem.open(rc.port)
	modem.send(rc.address, rc.port, self.prefix.biosControl, "connect")
	do
		local ptime = computer.uptime()
		local timeout = ut.parseArgs(conf.timeout, orc.conf.timeout)
		local unrelatedSignals = {}

		while computer.uptime() - ptime < timeout do
			local signal = {event.pull(timeout - (computer.uptime() - ptime), "modem_message")}
			local address, prefix, reason, hostname = signal[3], signal[6], signal[7], signal[8]
			
			if address == rc.address and prefix == self.prefix.biosControl and reason == "connect" then
				self.stream = minitel.open(rc.hostname, rc.port)
				break
			else
				table.insert(unrelatedSignals, signal)
			end
		end

		--repush all unrelatet signals by generating source code to convert signal table to seperate parameters.
		for _, s in ipairs(unrelatedSignals) do
			local code = "require('event').push("
			for i, p in ipairs(s) do
				if type(p) == "table" then
					code = code .. ut.tostring(p, false)
				elseif type(p) == "string" then
					code = code .. "'" .. p .. "'"
				else
					code = code .. tostring(p)
				end
				code = code .. ", "
			end
			code = string.sub(code, 0, unicode.len(code) -2)
			code = code .. ")"
			load(code)()
		end
	end
	
	if type(self.stream) ~= "table" or self.stream.state ~= "open" then
		return false, "Cant open stream to remote computer"
	end
	
	self.stream:write(getScript() .. self.prefix.biosControl)

	--generate log table
	for name, prefix in pairs(self.prefix) do
		self.log[prefix] = {}
		self.log[prefix].readed = {}
		self.log[prefix].unreaded = {}
	end
	
	return self
end

function orc.RC:update()
	local line = self.stream:read()

	while line ~= nil do
		--print("LINE: ", line)
		if self.log[line] ~= nil then
			self.currentCommunicationPrefix = line
		else
			table.insert(self.log[self.currentCommunicationPrefix].unreaded, line)

			if self.currentCommunicationPrefix == self.prefix.biosControl then
				self.biosStatus = line
			elseif self.currentCommunicationPrefix == self.prefix.loaderControl then
				self.loaderStatus = line
				if line == "DONE" then
					self.executionsQueued = self.executionsQueued -1
				end
			end

			if self.stream.state ~= "open" then
				self.biosStatus = "DEAD"
				self.loaderStatus = "DEAD"
			end
		end

		line = self.stream:read()
	end
end

function orc.RC:parseLogTable(logtable)
	local returnString = ""
	local firstRun = true
	self:update()
	for _, msg in ipairs(logtable.unreaded) do
		table.insert(logtable.readed, msg)

		if not firstRun then --not using string.sub here to save performance.
			returnString = returnString .. "\n"
		end
		firstRun = false

		returnString = returnString .. msg
	end
	logtable.unreaded = {}
	return returnString
end

function orc.RC:execute(script, name)
	self.stream:write(self.prefix.loaderControl .. "EXEC;" .. tostring(name) .. "\n" .. script .. "\n" .. self.prefix.loaderControl)
	self.executionsQueued = self.executionsQueued +1
end
function orc.RC:executeFile(path, name)
	local script = assert(ut.readFile(path), "Script not found: " .. tostring(path))
	self:execute(script, name)
end
function orc.RC:loadStdLib()
	self:executeFile(orc.dev.stdLib, "std")
end

function orc.RC:dumpLogTable()
	self:update()
	return ut.tostring(self.log)
end

function orc.RC:getBiosSysLog() --BIOS internal system log
	self:update()
	return self:parseLogTable(self.log[self.prefix.biosControl])
end
function orc.RC:getBiosDebugLog() --BIOS debugging log
	self:update()
	return self:parseLogTable(self.log[self.prefix.biosDebug])
end
function orc.RC:getSysLog() --loader internal system log
	self:update()
	return self:parseLogTable(self.log[self.prefix.loaderControl])
end
function orc.RC:getDebugLog() --loader debug log
	self:update()
	return self:parseLogTable(self.log[self.prefix.loaderDebug])
end
function orc.RC:getLog() --user script log
	self:update()
	return self:parseLogTable(self.log[self.prefix.userDebug])
end

function orc.RC:getBiosStatus()
	self:update()
	return self.biosStatus
end
function orc.RC:status(realStatus)
	self:update()

	if realStatus then
		return self.loaderStatus
	elseif self.executionsQueued > 0 then
		return "EXEC_QUEUED"
	end

	return self.loaderStatus
end

function orc.RC:getBiosVersion()
	return self.remoteComputer.biosVersion
end

function orc.RC:getHostname()
	return self.remoteComputer.hostname
end

function orc.RC:close()
	self.stream:close()
end

function orc.RC:test()
	print(self.testVar)
end

--===== functions aliases =====--
orc.new = orc.RC.new

return orc