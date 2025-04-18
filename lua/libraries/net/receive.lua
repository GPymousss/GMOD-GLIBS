function gNetReceive(name, callback)
	if not name or type(name) ~= "string" then return false end
	if not callback or type(callback) ~= "function" then return false end

	net.Receive(name, function(len, ply)
		local count = net.ReadUInt(16)
		local data = {}

		for i = 1, count do
			local key = net.ReadString()
			local valueType = net.ReadString()
			local value

			if valueType == "string" then
				value = net.ReadString()
			elseif valueType == "number" then
				local isInteger = net.ReadBool()
				if isInteger then
					value = net.ReadInt(32)
				else
					value = net.ReadFloat()
				end
			elseif valueType == "boolean" then
				value = net.ReadBool()
			elseif valueType == "Entity" or valueType == "Player" then
				value = net.ReadEntity()
			elseif valueType == "Vector" then
				value = net.ReadVector()
			elseif valueType == "Angle" then
				value = net.ReadAngle()
			elseif valueType == "Color" then
				value = net.ReadColor()
			elseif valueType == "table" then
				local isSpecialType = net.ReadBool()
				if isSpecialType then
					local specialType = net.ReadString()
					if specialType == "vector" then
						value = net.ReadVector()
					elseif specialType == "angle" then
						value = net.ReadAngle()
					elseif specialType == "color" then
						value = net.ReadColor()
					end
				else
					local jsonStr = net.ReadString()
					value = util.JSONToTable(jsonStr) or {}
				end
			else
				value = net.ReadString()
			end

			data[key] = value
		end

		callback(data, ply)
	end)

	return true
end