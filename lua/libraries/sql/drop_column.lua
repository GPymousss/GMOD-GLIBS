function gQueryDropColumn(tableName, columnName, callback)
	if GPYMOUSSS.SQL.usingSQLite then
		local columnsQuery = sql.Query("PRAGMA table_info(" .. tableName .. ")")
		if not columnsQuery then
			if callback then callback(false) end
			return
		end

		local columns = {}
		for _, col in ipairs(columnsQuery) do
			if col.name ~= columnName then
				table.insert(columns, col.name)
			end
		end

		if #columns == 0 then
			if callback then callback(false) end
			return
		end

		local columnList = table.concat(columns, ", ")
		local queries = {
			string.format("CREATE TEMPORARY TABLE backup_table AS SELECT %s FROM %s", columnList, tableName),
			string.format("DROP TABLE %s", tableName),
			string.format("CREATE TABLE %s AS SELECT %s FROM backup_table", tableName, columnList),
			"DROP TABLE backup_table"
		}

		for _, query in ipairs(queries) do
			local result = sql.Query(query)
			if result == false then
				if callback then callback(false) end
				return
			end
		end

		if callback then callback(true) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local q = GPYMOUSSS.SQL.db:query(string.format("ALTER TABLE %s DROP COLUMN %s", tableName, columnName))
	gHandleQuery(q, callback)
end