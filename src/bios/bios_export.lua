local version = "v0.4.3"

--===== conf =====--
local port = 10
local hostname = "TEST"

local pncp = "ORC_PBCP" --public network communication prefix. have to be the same as for the ORC object.
local ncp = "ORC_BCP" --network communication prefix. have to be the same as for the ORC object.
local dncp = "ORC_BDCP" --debug network communication prefix. have to be the same as for the ORC object.

local idleTime = 1 --the time the BIOS idels brfore cheking for a new script to execute.
local timeoutTime = 10 --the time the BIOS waits brfore timeouting the current stream if no script is executed.
local attachNameToHostname = true --if true it attaches the robots/drones name to the hostname.
local attachComputerAddressToHostname = true --if true it attaches the computers name to the hostname.

local dev = true
local gui = true

--===== BIOS =====--
local controlStream = {}
local debugStream = {}
local timeoutTimestamp = 0
local execScript = false

--===== vars to short the minified version =====--
local comp = computer
local componentShort = component
local pullSignal = comp.pullSignal
local random = math.random
local uptime = comp.uptime
local tostring = _G.tostring

--===== local functions =====--
local function getComponent(c)
	local comp = componentShort.list(c)()
	if comp ~= nil then
		return componentShort.proxy(comp)
	end
end

--===== microtel =====--
net={}do
local M,P,L,O,C,Y={},{},{},{},comp,table.unpack
net.port,net.hn,net.route,net.hook,U=4096,C.address():sub(1,8),true,{},C.uptime
for a in componentShort.list("modem")do
M[a]=componentShort.proxy(a)M[a].open(net.port)end
local function J()local B=""for i=1,16 do
B=B..string.char(random(32,126))end
return B
end
local function G(B,E,T,from,F,D)if O[T] then
M[O[T][1]].send(O[T][2],net.port,B,E,T,from,F,D)else
for k,v in pairs(M)do
v.broadcast(net.port,B,E,T,from,F,D)end
end
end
local function I(B,E,T,F,D)L[B]=U()G(B,E,T,net.hn,F,D)end
function net.send(T,F,D,E,B)E,B=E or 1,B or J()P[B]={E,T,F,D,0}I(B,E,T,F,D)end
local function N(B)for k,v in pairs(L)do
if k==B then
return false
end
end
return true
end
local X=pullSignal
function C.pullSignal(t)local Z={X(t)}for k,v in pairs(net.hook)do
pcall(v,Y(Z))end
for k,v in pairs(L)do
if U()>v+30then
L[k]=nil
end
end
for k,v in pairs(O)do
if U()>v[3]+30then
O[k]=nil
end
end
if Z[1]=="modem_message"and (Z[4]==net.port or Z[4]==0)and N(Z[6])then
O[Z[9]]={Z[2],Z[3],U()}if Z[8]==net.hn then
if Z[7]~=2then
C.pushSignal("net_msg",Z[9],Z[10],Z[11])if Z[7]==1then
I(J(),2,Z[9],Z[10],Z[6])end
else
P[Z[11]]=nil
end
elseif net.route and N(Z[6])then
G(Z[6],Z[7],Z[8],Z[9],Z[10],Z[11])end
L[Z[6]]=U()end
for k,v in pairs(P)do
if U()>v[5] then
I(k,Y(v))v[5]=U()+30
end
end
return Y(Z)end
end
net.mtu=4096
function net.lsend(T,P,L)local D={}for i=1,L:len(),net.mtu do
D[#D+1]=L:sub(1,net.mtu)L=L:sub(net.mtu+1)end
for k,v in ipairs(D)do
net.send(T,P,v)end
end
function net.socket(A,P,S)local C,rb={},""C.s,C.b,C.P,C.A="o","",tonumber(P),A
function C.r(s,l)rb=s.b:sub(1,l)s.b=s.b:sub(l+1)return rb
end
function C.w(s,D)net.lsend(s.A,s.P,D)end
function C.c(s)net.send(C.A,C.P,S);C.s="c"end
function h(E,F,P,D)if F==C.A and P==C.P then
if D==S then
net.hook[S]=nil
C.s="c"return
end
C.b=C.b..D
end
end
net.hook[S]=h
return C
end

pullSignal = comp.pullSignal --update local version

--adding timeout to net.listen
function net.listen(V)local F,P,D
	timeoutTimestamp = uptime()
	repeat _,F,P,D=pullSignal(0.5) 
		if uptime() - timeoutTimestamp > timeoutTime then return {} end
	until P==V and D=="openstream"
		local nP,S=random(2^15,2^16),tostring(random(-2^16,2^16))net.send(F,P,tostring(nP))net.send(F,nP,S)return net.socket(F,nP,S)
end

--===== init =====--
local m = getComponent("modem")
local drone = getComponent("drone")
local robot = getComponent("robot")

net.hn = hostname
m.open(port) 

pncp = pncp .. "::"
ncp = ncp .. "::"
dncp = dncp .. "::"

--setting up network hostname
if attachNameToHostname then
	if drone ~= nil then
		net.hn = net.hn .. "_" .. drone.name()
	elseif robot ~= nil then
		net.hn = net.hn .. "_" .. robot.name()
	end
end

if attachComputerAddressToHostname then
	net.hn = net.hn .. "_" .. comp.address()
end

--===== debug =====--
local gpu, resX, resY

local function ts(...)
	return tostring(...)
end

local function send(msg)
	controlStream:w(ncp .. "\n" .. ts(msg) .. "\n")
end

local print = function(msg) end --debug message

if dev then
	local orgPrint = print

	print = function(msg)
		msg = ts(msg)
		if drone ~= nil then
			drone.setStatusText(msg .. "          \n" .. string.sub(msg .. "          ", 11))
		end
		msg = ts(msg)
		orgPrint(msg)
		if controlStream.s == "o" then
			controlStream:w(dncp .. "\n" .. msg .. "\n")
		end
	end 
end

local function beep(...)
	comp.beep(...)
end

--===== mian while =====--
print("BIOS " .. version)
print("CP: " .. ncp)
print("DCP: " .. dncp)
print("Name: " .. net.hn)
while true do
	local scriptString = ""
	
	timeoutTimestamp = uptime()
	while not execScript do
		if controlStream.s ~= "o" then --if stream ~= open	
			scriptString = ""
			::init::
			beep(1000)
			print("Wait for  stream")
			
			while controlStream.s ~= "o" do
				local _, _, address, _, _, prefix, msg = pullSignal()

				--print(p[6])
				--print("M: " .. address .. ", " .. tostring(prefix) .. ", " .. tostring(msg))
				
				if prefix == pncp and msg == "get" then
					print("GET")
					m.send(address, port, pncp, "get", net.hn, version)
				elseif prefix == ncp and msg == "connect" then
					m.send(address, port, ncp, "connect", net.hn, true)
					controlStream = net.listen(port)
					if controlStream.s ~= "o" then
						print("Failed")
						beep(800, .5)
						goto init
					else
						status = 1
					end
				end
			end
			print("Connected")
			timeoutTimestamp = uptime()
		end

		package = controlStream:r(#controlStream.b)
		if package ~= "" then
			scriptString = scriptString .. package --string.sub(data, 0, unicode.len(ncp))

			if string.sub(scriptString, -unicode.len(ncp)) == ncp then --if last part of package string is the ncp the script is fully transfared.
				scriptString = string.sub(scriptString, 0, -unicode.len(ncp) -1)
				execScript = true
			end
			timeoutTimestamp = uptime()
		end

		if uptime() - timeoutTimestamp > timeoutTime then
			print("Timeout")
			send("DEAD")
			controlStream:c()
		elseif not execScript then
			pullSignal(idleTime)
		end
	end

	do
		print("Load")
		send("LOAD")

		local loadedScript, err = load(scriptString)
		scriptString = ""
		if loadedScript ~= nil then
			print("Execute")
			send("EXEC")

			local suc, err = xpcall(loadedScript, debug.traceback, net, controlStream, port)
			--loadedScript(controlStream)

			print("Exec suc: " .. tostring(suc))
			send(tostring(suc))
			if suc ~= true then
				print(tostring(err))
				send("ERR: " .. tostring(err))
				beep(600)
				beep(600)
				beep(800, .5)
			end
		else
			print("Load err: " .. err)
			send(err)
			beep(600)
			beep(800, .5)
		end
		execScript = false
	end
end
