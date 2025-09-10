function gSQLiteUpdate(tableName, data, conditions, callback)
	local valid, error = gSQLiteValidateName(tableName)
	if not valid then
		local errorMsg = "Invalid table name: " .. error
		gSQLDebugPrint("SQLite", "Update failed - validation", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local dataValid, dataError = gSQLiteValidateData(data)
	if not dataValid then
		local errorMsg = "Invalid data: " .. dataError
		gSQLDebugPrint("SQLite", "Update failed - data validation", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not conditions or type(conditions) ~= "table" or table.Count(conditions) == 0 then
		local errorMsg = "Update requires WHERE conditions for safety"
		gSQLDebugPrint("SQLite", "Update failed - no conditions", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local setPairs = {}
	for col, value in pairs(data) do
		if value == nil then
			table.insert(setPairs, string.format("%s = NULL", col))
		else
			table.insert(setPairs, string.format("%s = %s", col, sql.SQLStr(tostring(value))))
		end
	end

	local query = string.format("UPDATE %s SET %s", tableName, table.concat(setPairs, ", "))
	local whereClause = gSQLiteBuildWhereClause(conditions)

	if whereClause == "" then
		local errorMsg = "Invalid WHERE conditions provided"
		gSQLDebugPrint("SQLite", "Update failed - invalid conditions", {
			status = "error",
			error = errorMsg,
			data = { table = tableName, conditions = conditions }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	query = query .. whereClause

	local result, queryError = gSQLiteExecuteQuery(query, "Updating data", tableName, {
		table = tableName,
		values = data,
		conditions = conditions,
		column_count = table.Count(data)
	})

	local rowsAffected = 0
	if result ~= false then
		local changesResult = sql.Query("SELECT changes()")
		if changesResult and changesResult[1] then
			rowsAffected = changesResult[1]["changes()"]
		end

		gSQLDebugPrint("SQLite", "Update successful", {
			status = "success",
			data = {
				table = tableName,
				rows_affected = rowsAffected
			}
		})
	end

	if callback then callback(result, queryError) end
end