function gSQLiteInsert(tableName, data, callback)
	local valid, error = gSQLiteValidateName(tableName)
	if not valid then
		local errorMsg = "Invalid table name: " .. error
		gSQLDebugPrint("SQLite", "Insert failed - validation", {
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
		gSQLDebugPrint("SQLite", "Insert failed - data validation", {
			status = "error",
			error = errorMsg,
			data = { table = tableName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local columns = table.GetKeys(data)
	local values = {}

	for _, col in ipairs(columns) do
		local value = data[col]
		if value == nil then
			table.insert(values, "NULL")
		else
			table.insert(values, sql.SQLStr(tostring(value)))
		end
	end

	local query = string.format("INSERT INTO %s (%s) VALUES (%s)",
		tableName,
		table.concat(columns, ", "),
		table.concat(values, ", ")
	)

	local result, queryError = gSQLiteExecuteQuery(query, "Inserting data", tableName, {
		table = tableName,
		values = data,
		column_count = #columns
	})

	local insertId = nil
	if result ~= false then
		local idResult = sql.Query("SELECT last_insert_rowid()")
		if idResult and idResult[1] then
			insertId = idResult[1]["last_insert_rowid()"]
		end
	end

	if result ~= false and insertId then
		gSQLDebugPrint("SQLite", "Insert successful", {
			status = "success",
			data = {
				table = tableName,
				insert_id = insertId,
				rows_inserted = 1
			}
		})
	end

	if callback then callback(result, queryError) end
end