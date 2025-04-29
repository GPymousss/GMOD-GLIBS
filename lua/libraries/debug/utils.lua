function gSQLExplainQuery(query)
	if GPYMOUSSS.SQL.usingSQLite then
		local result = sql.Query("EXPLAIN QUERY PLAN " .. query)

		gSQLDebugPrint("Explain", "SQLite query explanation", {
			status = "info",
			query = query,
			data = result
		})

		return result
	end

	if not GPYMOUSSS.SQL.db then return end

	local q = GPYMOUSSS.SQL.db:query("EXPLAIN " .. query)
	q.onSuccess = function(_, data)
		gSQLDebugPrint("Explain", "MySQL query explanation", {
			status = "success",
			query = query,
			data = data
		})
	end

	q.onError = function(_, err)
		gSQLDebugPrint("Explain", "MySQL query explanation failed", {
			status = "error",
			query = query,
			error = err
		})
	end

	q:start()
end

function gSQLQueryStats()
	local stats = {}

	if GPYMOUSSS.SQL.usingSQLite then
		stats.journalMode = sql.Query("PRAGMA journal_mode")[1]["journal_mode"]
		stats.syncMode = sql.Query("PRAGMA synchronous")[1]["synchronous"]
		stats.cacheSize = sql.Query("PRAGMA cache_size")[1]["cache_size"]
		stats.tempStore = sql.Query("PRAGMA temp_store")[1]["temp_store"]
		stats.foreignKeys = sql.Query("PRAGMA foreign_keys")[1]["foreign_keys"]

		gSQLDebugPrint("Stats", "SQLite configuration", {
			status = "info",
			data = stats
		})
	else
		if not GPYMOUSSS.SQL.db then return end

		local q = GPYMOUSSS.SQL.db:query("SHOW VARIABLES LIKE '%version%'")
		q.onSuccess = function(_, data)
			for _, row in ipairs(data) do
				stats[row.Variable_name] = row.Value
			end

			local q2 = GPYMOUSSS.SQL.db:query("SHOW STATUS")
			q2.onSuccess = function(_, data2)
				for _, row in ipairs(data2) do
					stats[row.Variable_name] = row.Value
				end

				gSQLDebugPrint("Stats", "MySQL configuration and statistics", {
					status = "success",
					data = stats
				})
			end

			q2:start()
		end

		q:start()
	end

	return stats
end

function gSQLListTables()
	local tables = {}

	if GPYMOUSSS.SQL.usingSQLite then
		local result = sql.Query("SELECT name FROM sqlite_master WHERE type='table'")

		for _, row in ipairs(result or {}) do
			table.insert(tables, row.name)
		end

		gSQLDebugPrint("ListTables", "SQLite tables", {
			status = "info",
			data = tables
		})
	else
		if not GPYMOUSSS.SQL.db then return end

		local q = GPYMOUSSS.SQL.db:query("SHOW TABLES")
		q.onSuccess = function(_, data)
			for _, row in ipairs(data) do
				local firstKey = table.GetKeys(row)[1]
				table.insert(tables, row[firstKey])
			end

			gSQLDebugPrint("ListTables", "MySQL tables", {
				status = "success",
				data = tables
			})
		end

		q:start()
	end

	return tables
end

function gSQLTableInfo(tableName)
	local info = {}

	if GPYMOUSSS.SQL.usingSQLite then
		info.columns = sql.Query("PRAGMA table_info(" .. tableName .. ")")
		info.indexes = sql.Query("PRAGMA index_list(" .. tableName .. ")")

		gSQLDebugPrint("TableInfo", "SQLite table information", {
			status = "info",
			data = {
				table = tableName,
				info = info
			}
		})
	else
		if not GPYMOUSSS.SQL.db then return end

		local q = GPYMOUSSS.SQL.db:query("DESCRIBE " .. tableName)
		q.onSuccess = function(_, data)
			info.columns = data

			local q2 = GPYMOUSSS.SQL.db:query("SHOW INDEX FROM " .. tableName)
			q2.onSuccess = function(_, data2)
				info.indexes = data2

				gSQLDebugPrint("TableInfo", "MySQL table information", {
					status = "success",
					data = {
						table = tableName,
						info = info
					}
				})
			end

			q2:start()
		end

		q:start()
	end

	return info
end