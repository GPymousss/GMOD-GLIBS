function gMySQLUpdate(connectionName, tableName, data, conditions, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "Update failed - connection", {
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
		gSQLDebugPrint("MySQL", "Update failed - validation", {
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
		gSQLDebugPrint("MySQL", "Update failed - data validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not conditions or type(conditions) ~= "table" or table.Count(conditions) == 0 then
		local errorMsg = "Update requires WHERE conditions for safety"
		gSQLDebugPrint("MySQL", "Update failed - no conditions", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local setPairs = {}
	local setParams = {}

	for col, value in pairs(data) do
		table.insert(setPairs, string.format("%s = ?", col))
		table.insert(setParams, value)
	end

	local queryStr = string.format("UPDATE %s SET %s", tableName, table.concat(setPairs, ", "))
	local whereClause, whereParams = gMySQLBuildWhereClause(conditions)

	if whereClause == "" then
		local errorMsg = "Invalid WHERE conditions provided"
		gSQLDebugPrint("MySQL", "Update failed - invalid conditions", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName, conditions = conditions }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	queryStr = queryStr .. whereClause

	local allParams = {}
	for _, param in ipairs(setParams) do
		table.insert(allParams, param)
	end
	for _, param in ipairs(whereParams) do
		table.insert(allParams, param)
	end

	local db = GPYMOUSSS.MySQL.connections[connectionName].db
	local query = db:prepare(queryStr)

	for i, param in ipairs(allParams) do
		if param == nil then
			query:setNull(i)
		else
			query:setString(i, tostring(param))
		end
	end

	gSQLDebugPrint("MySQL", "Updating data", {
		status = "info",
		query = queryStr,
		data = {
			connection = connectionName,
			table = tableName,
			values = data,
			conditions = conditions,
			column_count = table.Count(data),
			params = allParams
		}
	})

	local originalCallback = callback
	local enhancedCallback = function(result, error)
		if result and not error then
			local rowsAffected = query:affectedRows()
			gSQLDebugPrint("MySQL", "Update successful", {
				status = "success",
				data = {
					connection = connectionName,
					table = tableName,
					rows_affected = rowsAffected
				}
			})
		end

		if originalCallback then originalCallback(result, error) end
	end

	gMySQLHandleQuery(query, enhancedCallback, queryStr, allParams)
end