function gMySQLCreateTable(connectionName, tableName, columns, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "Create table failed - connection", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local valid, error = gMySQLValidateName(tableName)
	if not valid then
		local errorMsg = "Invalid table name: " .. error
		gSQLDebugPrint("MySQL", "Create table failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not columns or type(columns) ~= "table" or table.Count(columns) == 0 then
		local errorMsg = "Columns must be a non-empty table"
		gSQLDebugPrint("MySQL", "Create table failed - no columns", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local columnDefs = {}
	for name, definition in pairs(columns) do
		local nameValid, nameError = gMySQLValidateName(name)
		if not nameValid then
			local errorMsg = "Invalid column name '" .. tostring(name) .. "': " .. nameError
			gSQLDebugPrint("MySQL", "Create table failed - invalid column", {
				status = "error",
				error = errorMsg,
				data = { connection = connectionName, table = tableName, column = name }
			})
			if callback then callback(false, errorMsg) end
			return
		end

		local baseType, constraints = gMySQLParseColumnDefinition(name, definition)

		if constraints ~= "" then
			table.insert(columnDefs, string.format("%s %s %s", name, baseType, constraints))
		else
			table.insert(columnDefs, string.format("%s %s", name, baseType))
		end
	end

	local queryStr = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(columnDefs, ", "))
	local db = GPYMOUSSS.MySQL.connections[connectionName].db
	local query = db:query(queryStr)

	gSQLDebugPrint("MySQL", "Creating table", {
		status = "info",
		query = queryStr,
		data = {
			connection = connectionName,
			table = tableName,
			columns = columns,
			column_count = #columnDefs
		}
	})

	gMySQLHandleQuery(query, callback, queryStr, {})
end