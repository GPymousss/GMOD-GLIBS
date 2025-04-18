function gQueryCreateTable(tableName, columns, callback)
	local function parseColumnDefinition(name, definition)
		if type(definition) == "string" then
			local parts = {}
			for part in definition:gmatch("%S+") do
				table.insert(parts, part:upper())
			end
			local baseType = parts[1]
			local constraints = {}

			for i = 2, #parts do
				table.insert(constraints, parts[i])
			end

			return baseType, table.concat(constraints, " ")
		end
		return definition.type, ""
	end

	if GPYMOUSSS.SQL.usingSQLite then
		local columnDefs = {}
		for name, definition in pairs(columns) do
			local baseType, constraints = parseColumnDefinition(name, definition)
			local sqliteType = string.lower(baseType)

			if string.find(sqliteType, "int") then
				sqliteType = "INTEGER"
			elseif string.find(sqliteType, "varchar") or string.find(sqliteType, "text") then
				sqliteType = "TEXT"
			end

			if constraints ~= "" then
				table.insert(columnDefs, string.format("%s %s %s", name, sqliteType, constraints))
			else
				table.insert(columnDefs, string.format("%s %s", name, sqliteType))
			end
		end

		local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(columnDefs, ", "))
		local result = sql.Query(query)

		if callback then callback(result) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local columnDefs = {}
	for name, definition in pairs(columns) do
		local baseType, constraints = parseColumnDefinition(name, definition)
		if constraints ~= "" then
			table.insert(columnDefs, string.format("%s %s %s", name, baseType, constraints))
		else
			table.insert(columnDefs, string.format("%s %s", name, baseType))
		end
	end

	local q = GPYMOUSSS.SQL.db:query(string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(columnDefs, ", ")))
	gHandleQuery(q, callback)
end