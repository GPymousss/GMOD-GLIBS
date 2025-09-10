function gMySQLSelect(connectionName, tableName, columns, conditions, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "Select failed - connection", {
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
		gSQLDebugPrint("MySQL", "Select failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local columnStr = "*"
	if columns then
		if type(columns) ~= "table" then
			local errorMsg = "Columns must be a table or nil"
			gSQLDebugPrint("MySQL", "Select failed - invalid columns", {
				status = "error",
				error = errorMsg,
				data = { connection = connectionName, table = tableName }
			})
			if callback then callback(false, errorMsg) end
			return
		end

		local validColumns = {}
		for _, col in ipairs(columns) do
			local colValid, colError = gMySQLValidateName(col)
			if colValid then
				table.insert(validColumns, col)
			else
				local errorMsg = "Invalid column name '" .. tostring(col) .. "': " .. colError
				gSQLDebugPrint("MySQL", "Select failed - invalid column", {
					status = "error",
					error = errorMsg,
					data = { connection = connectionName, table = tableName, column = col }
				})
				if callback then callback(false, errorMsg) end
				return
			end
		end

		if #validColumns == 0 then
			local errorMsg = "No valid columns provided"
			gSQLDebugPrint("MySQL", "Select failed - no valid columns", {
				status = "error",
				error = errorMsg,
				data = { connection = connectionName, table = tableName }
			})
			if callback then callback(false, errorMsg) end
			return
		end

		columnStr = table.concat(validColumns, ", ")
	end

	local queryStr = string.format("SELECT %s FROM %s", columnStr, tableName)
	local whereClause, params = gMySQLBuildWhereClause(conditions)
	queryStr = queryStr .. whereClause

	local db = GPYMOUSSS.MySQL.connections[connectionName].db
	local query = db:prepare(queryStr)

	for i, param in ipairs(params) do
		if param == nil then
			query:setNull(i)
		else
			query:setString(i, tostring(param))
		end
	end

	gSQLDebugPrint("MySQL", "Selecting data", {
		status = "info",
		query = queryStr,
		data = {
			connection = connectionName,
			table = tableName,
			columns = columns,
			conditions = conditions,
			params = params
		}
	})

	local originalCallback = callback
	local enhancedCallback = function(result, error)
		if result and not error then
			gSQLDebugPrint("MySQL", "Select successful", {
				status = "success",
				data = {
					connection = connectionName,
					table = tableName,
					row_count = #result
				}
			})
		end

		if originalCallback then originalCallback(result, error) end
	end

	gMySQLHandleQuery(query, enhancedCallback, queryStr, params)
end