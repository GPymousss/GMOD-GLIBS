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

		if callback then callback(result) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local q = GPYMOUSSS.SQL.db:query(string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, columnName, columnDefinition))
	gHandleQuery(q, callback)
end