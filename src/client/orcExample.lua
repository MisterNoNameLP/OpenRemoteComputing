--add libs folder to package.path
package.path = package.path .. ";./libs/?.lua" 

--load OpenRemoteComputing library
local orc = require("libs/orc") 

--client conf
local port = 10 
local timeout = 3

--get a table of all avaiale remote computers
local avaiableComputers = orc.get(port, timeout)

--connect to the first avaiable remote computer
local remoteComputer, err = nil, "No remote computer found"
for name, computer in pairs(avaiableComputers) do
	print("Connect to computer: " .. name)
	remoteComputer, err = orc.new(computer) 
	break
end

--close program if no connection was esteblished
if not remoteComputer then
	print("Could not connect to remote computer")
	print("ERR: " .. tostring(err))
	os.exit(1)
end

--print an empty line
print()

--load the UsefulThings library into the remoteComputer
remoteComputer:executeFile("libs/UT.lua", "UT") 

--execute a script utilizing the UsefulTings libreary loaded earlier
remoteComputer:execute([[
--require UsefulTings library loaded earlier
local ut = require("UT")

--create a example table
local myTable = {
	"Hello, i am a table entry.", 
	"As well as me!",
	meToo = "And me!",
}

--print a message
print("Hello world, I am a remote computer!")

--print myTable using the tostring function from the UsefulThings library
print(ut.tostring(myTable))

]], "SCRIPT_NAME")


--wait until the remoteComputer is done executing all scripts
while remoteComputer:status() ~= "IDLE" and remoteComputer:status() ~= "DEAD" do
	os.sleep(.1)
end

--print all logs relevant for using the library and close the stream afterwards
print("### Remote computer log ###")
	
print("DEBUG:-----------------------------------------------\n" .. remoteComputer:getDebugLog(), "\n")
print("USER:-------------------------------------------------\n" .. remoteComputer:getLog(), "\n")

print("Close stream")
remoteComputer:close()