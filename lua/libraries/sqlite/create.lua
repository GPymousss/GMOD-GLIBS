function gSQLiteCreateTable(tableName, columns, callback)
	local valid, error = gSQLiteValidateName(tableName)
	if not valid then
		local errorMsg = "Invalid table name: " .. error
		gSQLDebugPrint("SQLite", "Creating table failed - validation", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not columns or type(columns) ~= "table" or table.Count(columns) == 0 then
		local errorMsg = "Columns must be a non-empty table"
		gSQLDebugPrint("SQLite", "Creating table failed - no columns", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local columnDefs = {}
	for name, definition in pairs(columns) do
		local nameValid, nameError = gSQLiteValidateName(name)
		if not nameValid then
			local errorMsg = "Invalid column name '" .. tostring(name) .. "': " .. nameError
			gSQLDebugPrint("SQLite", "Creating table failed - invalid column", {
				status = "error",
				error = errorMsg,
				data = { table = tableName, column = name }
			})
			if callback then callback(false, errorMsg) end
			return
		end

		local baseType, constraints = gSQLiteParseColumnDefinition(name, definition)
		local sqliteType = gSQLiteConvertType(baseType)

		if constraints ~= "" then
			table.insert(columnDefs, string.format("%s %s %s", name, sqliteType, constraints))
		else
			table.insert(columnDefs, string.format("%s %s", name, sqliteType))
		end
	end

	local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(columnDefs, ", "))
	local result, error = gSQLiteExecuteQuery(query, "Creating table", tableName, {
		table = tableName,
		columns = columns,
		column_count = #columnDefs
	})

	if callback then callback(result, error) end
end