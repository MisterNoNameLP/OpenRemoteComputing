local std = {version = "v0.1d"}

function std.sleep(t)
    local startTime = computer.uptime()
    while computer.uptime() - startTime < t do
        computer.pullSignal(t - (computer.uptime() - startTime))
    end
end

function std.getComponent(c)
    local comp = component.list(c)()
	if comp ~= nil then
		return component.proxy(comp)
	end
end

--[[Ripped out of MisterNoNameLPs Usefull Things libary v0.8.6.
    
    Converts a table or an other variable type to a readable stirng.
	This is a modified "Universal tostring" routine from "lua-users.org".
	Original source code: <http://lua-users.org/wiki/TableSerialization>
]]
function std.tostring(var, lineBreak, indent, done, internalRun) 
	if internalRun == false or internalRun == nil then
		if type(var) == "table" then
			std.tostring(var, lineBreak, indent, done, true)
		else
			return tostring(var)
		end
	end
	
	done = done or {}
	indent = indent or 2
	local lbString
	if lineBreak or lineBreak == nil then
		lbString = "\n"
		lineBreak = true
	else
		lbString = " "
	end
	if type(var) == "table" then
		local sb = {}
		if not internalRun then
			table.insert(sb, "{" .. lbString)
		end
		for key, value in pairs (var) do
			if lineBreak then
				table.insert(sb, string.rep (" ", indent)) -- indent it
			end
			if type (value) == "table" and not done [value] then
				done [value] = true
				if type(key) == "string" then
					key = "'" .. key .. "'"
				end
				if lineBreak then
					table.insert(sb, "[" .. tostring(key) .. "] = {" .. lbString);
				else
					table.insert(sb, "[" .. tostring(key) .. "] = {");
				end
				table.insert(sb, std.tostring(value, lineBreak, indent + 2, done, true))
				if lineBreak then
					table.insert(sb, string.rep (" ", indent)) -- indent it
					table.insert(sb, "}," .. lbString);
				else
					table.insert(sb, "},");
				end
			elseif "number" == type(key) then
				table.insert(sb, string.format("[%s] = ", tostring(key)))
				if type(value) ~= "boolean" and type(value) ~= "number" then
					table.insert(sb, string.format("\"%s\"," .. lbString, tostring(value)))
				else
					table.insert(sb, string.format("%s," .. lbString, tostring(value)))
				end
			else
				if sb[#sb] == "}," then
					table.insert(sb, " ")
				end
				if type(key) == "string" then
					key = "'" .. key .. "'"
				end
				if type(value) ~= "boolean" and type(value) ~= "number" then
					table.insert(sb, string.format("%s = \"%s\"," .. lbString, "[" .. tostring (key) .. "]", tostring(value)))
				else
					table.insert(sb, string.format("%s = %s," .. lbString, "[" .. tostring (key) .. "]", tostring(value)))
				end
			end
		end
		if not internalRun then
			if sb[#sb] == "}," then
				table.insert(sb, " }")
			else
				table.insert(sb, "}")
			end
		end
		return table.concat(sb)
	else
		return var .. lbString
	end
end

return std