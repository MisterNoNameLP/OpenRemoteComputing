--[[
    OpenRemoteComputers remoce script. 
    This script is executet by any remote computer by default.
    It sets the eviroment for user script to work in.
]]

local version = "v0.2.5"

--===== process args =====--
_arg = {...}
local microtel, controlStream, port = _arg[1], _arg[2], _arg[3]

local conf = {
    dev = true,
    gui = true,
    droneDisplay = true,

    timeoutTime = 20,

    prefix = {
        control = "ORC_LCP",
        debug = "ORC_LDCP",
        user = "ORC_UCP",
    }
}

--===== local vars =====--
local loaderIsRunning = true
local userScriptIsFullyTransfered = false
local userScriptIsRunning = false

local scriptString = nil --string of script currently getting trasfered
local scriptMetadata = {}
local scriptData = {}

local controlPrefixLength, debugPrefixLength
local timeoutTimestamp = computer.uptime()

--===== local functions =====--
local function generateString(...)
    local string = ""
    for _, s in ipairs{...} do
        if #string > 0 then
            string = string .. "  "
        end
        string = string .. tostring(s)
    end
    if not userScriptIsRunning then
        msg = "[LOADER]: " .. tostring(msg)
    end
    return string
end

local function localPrint(...)
    local prefix

    if not conf.dev then return end

    if userScriptIsRunning then
        prefix = conf.prefix.user .. "\n"
    else
        prefix = conf.prefix.debug .. "\n"
    end

    controlStream:w(prefix .. generateString(...) .. "\n")
end

local function send(msg)
    controlStream:w(conf.prefix.control .. "\n" .. msg .. "\n")
end

local function getComponent(c)
	local comp = component.list(c)()
	if comp ~= nil then
		return component.proxy(comp)
	end
end

local function sleep(t)
    local startTime = computer.uptime()
    while computer.uptime() - startTime < t do
        computer.pullSignal(t - (computer.uptime() - startTime))
    end
end

--===== global functions =====--
_G.print = localPrint

_G.require = function(v)
    assert(scriptData[v], "Cant require '" .. tostring(v) .. "'. No script data loaded.")
    return scriptData[v]
end

--===== init =====--
send("INIT")

if conf.dev and conf.gui and getComponent("gpu").maxDepth() ~= nil then --check if screen is present
	local orgPrint = print
	gpu = getComponent("gpu")
	resX, resY = gpu.getResolution()
	print = function(...)
		msg = generateString(...)
        orgPrint(msg)
		gpu.copy(1, 1, resX, resY, 0, -1)
		gpu.set(1, resY, msg .. string.rep(" ", resX))
	end
end

--prepare prefixes
for i, p in pairs(conf.prefix) do 
    conf.prefix[i] = p .. "::"
end
controlPrefixLength = unicode.len(conf.prefix.control)
debugPrefixLength = unicode.len(conf.prefix.debug)

print("Init") --have to get printet later as the INIT send.


--===== main while =====--
send("IDLE")
while loaderIsRunning and controlStream.s == "o" do
    local package = controlStream:r(#controlStream.b)

    --timeout check
	if computer.uptime() - timeoutTimestamp > conf.timeoutTime then
		print("Timeout")
        send("TIMEOUT")
        break
	else
		computer.pullSignal(conf.timeoutTime - (computer.uptime() - timeoutTimestamp))
	end

    --loadl script data
    if package ~= "" then
        local metadataString
        if string.find(package, conf.prefix.control) == 1 and scriptString == nil then --decode metadata
            metadataString = string.sub(string.gmatch(package, "[^\n]+")(), controlPrefixLength +1)

            for md in string.gmatch(metadataString, "[^;]+") do
                table.insert(scriptMetadata, md)
            end

            if scriptMetadata[1] == "EXEC" then
                if scriptMetadata[2] ~= nil then
                    scriptData[scriptMetadata[2]] = {}
                    scriptString = ""
                end
                package = string.sub(package, unicode.len(metadataString) + controlPrefixLength +2)
            end
            send("TRANSFER")
            print("Recieve script: " .. tostring(scriptMetadata[2]))
        end
        if scriptString ~= nil then
            if string.sub(package, -controlPrefixLength) == conf.prefix.control then
                package = string.sub(package, 0, -controlPrefixLength -1)
                userScriptIsFullyTransfered = true
            end
            scriptString = scriptString .. package
        end
        --cleanup
        package = nil
        timeoutTimestamp = computer.uptime()
    end

    if userScriptIsFullyTransfered then
        send("LOAD")
        print("Load script: " .. tostring(scriptMetadata[2]))

        local loadedScript, err = load(scriptString)
        scriptString = nil

        if loadedScript ~= nil then
            send("EXEC")
            print("Execute script: " .. tostring(scriptMetadata[2]))

            userScriptIsRunning = true
            local suc, returnValue = xpcall(loadedScript, debug.traceback, {microtel = microtel, controlStream = controlStream, port = port})
            userScriptIsRunning = false

            print("Execution success: " .. tostring(suc))
            send(tostring(suc))
            if suc and scriptMetadata[2] ~= nil then
                scriptData[scriptMetadata[2]] = returnValue
            else
                print(tostring(returnValue))
                send(tostring(returnValue))
            end
        else
            print("[ERR]: Cant load script: " .. err)
        end

        --cleanup
        send("DONE")
        userScriptIsFullyTransfered = false
        scriptMetadata = {}
        send("IDLE")
        timeoutTimestamp = computer.uptime()
    end
end

send("DEAD")
print("Stop")
controlStream:c()

--getComponent("drone").setStatusText("TEST")

--sleep(6)