function gMySQLDelete(connectionName, tableName, conditions, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "Delete failed - connection", {
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
		gSQLDebugPrint("MySQL", "Delete failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not conditions or type(conditions) ~= "table" or table.Count(conditions) == 0 then
		local errorMsg = "Delete requires WHERE conditions for safety"
		gSQLDebugPrint("MySQL", "Delete failed - no conditions", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local queryStr = string.format("DELETE FROM %s", tableName)
	local whereClause, params = gMySQLBuildWhereClause(conditions)

	if whereClause == "" then
		local errorMsg = "Invalid WHERE conditions provided"
		gSQLDebugPrint("MySQL", "Delete failed - invalid conditions", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName, conditions = conditions }
		})
		if callback then callback(false, errorMsg) end
		return
	end

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

	gSQLDebugPrint("MySQL", "Deleting data", {
		status = "info",
		query = queryStr,
		data = {
			connection = connectionName,
			table = tableName,
			conditions = conditions,
			params = params
		}
	})

	local originalCallback = callback
	local enhancedCallback = function(result, error)
		if result and not error then
			local rowsAffected = query:affectedRows()
			gSQLDebugPrint("MySQL", "Delete successful", {
				status = "success",
				data = {
					connection = connectionName,
					table = tableName,
					rows_deleted = rowsAffected
				}
			})
		end

		if originalCallback then originalCallback(result, error) end
	end

	gMySQLHandleQuery(query, enhancedCallback, queryStr, params)
end