function gNetSendToClient(name, data, player, callback)
	if not name or type(name) ~= "string" then return false end
	if not data or type(data) ~= "table" then return false end
	if not player or not IsValid(player) then return false end

	net.Start(name)

	net.WriteUInt(table.Count(data), 16)

	for k, v in pairs(data) do
		local valueType = type(v)

		net.WriteString(k)
		net.WriteString(valueType)

		if valueType == "string" then
			net.WriteString(v)
		elseif valueType == "number" then
			if math.floor(v) == v then
				net.WriteBool(true)
				net.WriteInt(v, 32)
			else
				net.WriteBool(false)
				net.WriteFloat(v)
			end
		elseif valueType == "boolean" then
			net.WriteBool(v)
		elseif valueType == "Entity" or valueType == "Player" then
			net.WriteEntity(v)
		elseif valueType == "Vector" then
			net.WriteVector(v)
		elseif valueType == "Angle" then
			net.WriteAngle(v)
		elseif valueType == "Color" then
			net.WriteColor(v)
		elseif valueType == "table" then
			local isVector = v.x ~= nil and v.y ~= nil and v.z ~= nil
			local isAngle = v.p ~= nil and v.y ~= nil and v.r ~= nil
			local isColor = v.r ~= nil and v.g ~= nil and v.b ~= nil

			if isVector then
				net.WriteBool(true)
				net.WriteString("vector")
				net.WriteVector(Vector(v.x, v.y, v.z))
			elseif isAngle then
				net.WriteBool(true)
				net.WriteString("angle")
				net.WriteAngle(Angle(v.p, v.y, v.r))
			elseif isColor then
				net.WriteBool(true)
				net.WriteString("color")
				net.WriteColor(Color(v.r, v.g, v.b, v.a or 255))
			else
				net.WriteBool(false)
				net.WriteString(util.TableToJSON(v))
			end
		else
			net.WriteString(tostring(v))
		end
	end

	net.Send(player)

	if callback then callback() end
	return true
end