function gSQLiteSelect(tableName, columns, conditions, callback)
	local valid, error = gSQLiteValidateName(tableName)
	if not valid then
		local errorMsg = "Invalid table name: " .. error
		gSQLDebugPrint("SQLite", "Select failed - validation", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local columnStr = "*"
	if columns then
		if type(columns) ~= "table" then
			local errorMsg = "Columns must be a table or nil"
			gSQLDebugPrint("SQLite", "Select failed - invalid columns", {
				status = "error",
				error = errorMsg,
				data = { table = tableName }
			})
			if callback then callback(false, errorMsg) end
			return
		end

		local validColumns = {}
		for _, col in ipairs(columns) do
			local colValid, colError = gSQLiteValidateName(col)
			if colValid then
				table.insert(validColumns, col)
			else
				local errorMsg = "Invalid column name '" .. tostring(col) .. "': " .. colError
				gSQLDebugPrint("SQLite", "Select failed - invalid column", {
					status = "error",
					error = errorMsg,
					data = { table = tableName, column = col }
				})
				if callback then callback(false, errorMsg) end
				return
			end
		end

		if #validColumns == 0 then
			local errorMsg = "No valid columns provided"
			gSQLDebugPrint("SQLite", "Select failed - no valid columns", {
				status = "error",
				error = errorMsg,
				data = { table = tableName }
			})
			if callback then callback(false, errorMsg) end
			return
		end

		columnStr = table.concat(validColumns, ", ")
	end

	local query = string.format("SELECT %s FROM %s", columnStr, tableName)
	local whereClause = gSQLiteBuildWhereClause(conditions)
	query = query .. whereClause

	local result, queryError = gSQLiteExecuteQuery(query, "Selecting data", tableName, {
		table = tableName,
		columns = columns,
		conditions = conditions,
		row_count = result and #result or 0
	})

	if callback then callback(result, queryError) end
end