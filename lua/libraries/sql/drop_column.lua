function gQueryDropColumn(tableName, columnName, callback)
	if GPYMOUSSS.SQL.usingSQLite then
		local columnsQuery = sql.Query("PRAGMA table_info(" .. tableName .. ")")
		if not columnsQuery then
			gSQLDebugPrint("DropColumn", "Failed to get table info in SQLite", {
				status = "error",
				query = "PRAGMA table_info(" .. tableName .. ")",
				error = sql.LastError()
			})

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
			gSQLDebugPrint("DropColumn", "No columns remaining after drop", {
				status = "error",
				query = "",
				data = {
					table = tableName,
					column = columnName
				}
			})

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

		local success = true
		for i, query in ipairs(queries) do
			local result = sql.Query(query)
			if result == false then
				gSQLDebugPrint("DropColumn", "SQLite drop column step " .. i .. " failed", {
					status = "error",
					query = query,
					error = sql.LastError()
				})

				success = false
				break
			end
		end

		if success then
			gSQLDebugPrint("DropColumn", "Column dropped in SQLite", {
				status = "success",
				query = table.concat(queries, "; "),
				data = {
					table = tableName,
					column = columnName
				}
			})
		end

		if callback then callback(success) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local queryStr = string.format("ALTER TABLE %s DROP COLUMN %s", tableName, columnName)
	local q = GPYMOUSSS.SQL.db:query(queryStr)

	gSQLDebugPrint("DropColumn", "Dropping column in MySQL", {
		status = "info",
		query = queryStr,
		data = {
			table = tableName,
			column = columnName
		}
	})

	gHandleQuery(q, callback)
end