function gMySQLInsert(connectionName, tableName, data, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "Insert failed - connection", {
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
		gSQLDebugPrint("MySQL", "Insert failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local dataValid, dataError = gMySQLValidateData(data)
	if not dataValid then
		local errorMsg = "Invalid data: " .. dataError
		gSQLDebugPrint("MySQL", "Insert failed - data validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local columns = table.GetKeys(data)
	local placeholders = {}
	local params = {}

	for _, col in ipairs(columns) do
		table.insert(placeholders, "?")
		table.insert(params, data[col])
	end

	local queryStr = string.format("INSERT INTO %s (%s) VALUES (%s)",
		tableName,
		table.concat(columns, ", "),
		table.concat(placeholders, ", ")
	)

	local db = GPYMOUSSS.MySQL.connections[connectionName].db
	local query = db:prepare(queryStr)

	for i, param in ipairs(params) do
		if param == nil then
			query:setNull(i)
		else
			query:setString(i, tostring(param))
		end
	end

	gSQLDebugPrint("MySQL", "Inserting data", {
		status = "info",
		query = queryStr,
		data = {
			connection = connectionName,
			table = tableName,
			values = data,
			column_count = #columns,
			params = params
		}
	})

	local originalCallback = callback
	local enhancedCallback = function(result, error)
		if result and not error then
			local insertId = query:lastInsert()
			gSQLDebugPrint("MySQL", "Insert successful", {
				status = "success",
				data = {
					connection = connectionName,
					table = tableName,
					insert_id = insertId,
					rows_inserted = 1
				}
			})
		end

		if originalCallback then originalCallback(result, error) end
	end

	gMySQLHandleQuery(query, enhancedCallback, queryStr, params)
end