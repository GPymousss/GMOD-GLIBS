function gQueryAddColumn(tableName, columnName, columnDefinition, callback)
	if GPYMOUSSS.SQL.usingSQLite then
		local baseType = string.upper(columnDefinition)
		local sqliteType = baseType

		if string.find(sqliteType, "INT") then
			sqliteType = "INTEGER"
		elseif string.find(sqliteType, "VARCHAR") or string.find(sqliteType, "TEXT") then
			sqliteType = "TEXT"
		end

		local query = string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, columnName, sqliteType)
		local result = sql.Query(query)

		gSQLDebugPrint("AddColumn", "Adding column in SQLite", {
			status = result ~= false and "success" or "error",
			query = query,
			error = result == false and sql.LastError() or nil,
			data = {
				table = tableName,
				column = columnName,
				definition = columnDefinition
			}
		})

		if callback then callback(result) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local queryStr = string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, columnName, columnDefinition)
	local q = GPYMOUSSS.SQL.db:query(queryStr)

	gSQLDebugPrint("AddColumn", "Adding column in MySQL", {
		status = "info",
		query = queryStr,
		data = {
			table = tableName,
			column = columnName,
			definition = columnDefinition
		}
	})

	gHandleQuery(q, callback)
end