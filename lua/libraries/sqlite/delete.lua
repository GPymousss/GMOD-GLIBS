function gSQLiteDelete(tableName, conditions, callback)
	local valid, error = gSQLiteValidateName(tableName)
	if not valid then
		local errorMsg = "Invalid table name: " .. error
		gSQLDebugPrint("SQLite", "Delete failed - validation", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not conditions or type(conditions) ~= "table" or table.Count(conditions) == 0 then
		local errorMsg = "Delete requires WHERE conditions for safety"
		gSQLDebugPrint("SQLite", "Delete failed - no conditions", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local query = string.format("DELETE FROM %s", tableName)
	local whereClause = gSQLiteBuildWhereClause(conditions)

	if whereClause == "" then
		local errorMsg = "Invalid WHERE conditions provided"
		gSQLDebugPrint("SQLite", "Delete failed - invalid conditions", {
			status = "error",
			error = errorMsg,
			data = { table = tableName, conditions = conditions }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	query = query .. whereClause

	local result, queryError = gSQLiteExecuteQuery(query, "Deleting data", tableName, {
		table = tableName,
		conditions = conditions
	})

	local rowsAffected = 0
	if result ~= false then
		local changesResult = sql.Query("SELECT changes()")
		if changesResult and changesResult[1] then
			rowsAffected = changesResult[1]["changes()"]
		end

		gSQLDebugPrint("SQLite", "Delete successful", {
			status = "success",
			data = {
				table = tableName,
				rows_deleted = rowsAffected
			}
		})
	end

	if callback then callback(result, queryError) end
end