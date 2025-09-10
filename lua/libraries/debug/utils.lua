function gSQLiteExplainQuery(query)
	local result = sql.Query("EXPLAIN QUERY PLAN " .. query)

	gSQLDebugPrint("SQLite", "SQLite query explanation", {
		status = "info",
		query = query,
		data = result
	})

	return result
end

function gMySQLExplainQuery(connectionName, query, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "Explain query failed - connection", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(nil, errorMsg) end
		return
	end

	local db = GPYMOUSSS.MySQL.connections[connectionName].db
	local q = db:query("EXPLAIN " .. query)

	q.onSuccess = function(_, data)
		gSQLDebugPrint("MySQL", "MySQL query explanation", {
			status = "success",
			query = query,
			data = {
				connection = connectionName,
				explain_data = data
			}
		})
		if callback then callback(data, nil) end
	end

	q.onError = function(_, err)
		gSQLDebugPrint("MySQL", "MySQL query explanation failed", {
			status = "error",
			query = query,
			error = err,
			data = { connection = connectionName }
		})
		if callback then callback(nil, err) end
	end

	q:start()
end

function gSQLiteQueryStats()
	local stats = {}

	stats.journalMode = sql.Query("PRAGMA journal_mode")[1]["journal_mode"]
	stats.syncMode = sql.Query("PRAGMA synchronous")[1]["synchronous"]
	stats.cacheSize = sql.Query("PRAGMA cache_size")[1]["cache_size"]
	stats.tempStore = sql.Query("PRAGMA temp_store")[1]["temp_store"]
	stats.foreignKeys = sql.Query("PRAGMA foreign_keys")[1]["foreign_keys"]

	gSQLDebugPrint("SQLite", "SQLite configuration", {
		status = "info",
		data = stats
	})

	return stats
end

function gMySQLQueryStats(connectionName, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "Query stats failed - connection", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(nil, errorMsg) end
		return
	end

	local db = GPYMOUSSS.MySQL.connections[connectionName].db
	local stats = {}

	local q = db:query("SHOW VARIABLES LIKE '%version%'")
	q.onSuccess = function(_, data)
		for _, row in ipairs(data) do
			stats[row.Variable_name] = row.Value
		end

		local q2 = db:query("SHOW STATUS")
		q2.onSuccess = function(_, data2)
			for _, row in ipairs(data2) do
				stats[row.Variable_name] = row.Value
			end

			gSQLDebugPrint("MySQL", "MySQL configuration and statistics", {
				status = "success",
				data = {
					connection = connectionName,
					stats = stats
				}
			})

			if callback then callback(stats, nil) end
		end

		q2.onError = function(_, err)
			gSQLDebugPrint("MySQL", "MySQL stats query failed", {
				status = "error",
				error = err,
				data = { connection = connectionName }
			})
			if callback then callback(nil, err) end
		end

		q2:start()
	end

	q.onError = function(_, err)
		gSQLDebugPrint("MySQL", "MySQL version query failed", {
			status = "error",
			error = err,
			data = { connection = connectionName }
		})
		if callback then callback(nil, err) end
	end

	q:start()
end

function gSQLiteListTables()
	local tables = {}
	local result = sql.Query("SELECT name FROM sqlite_master WHERE type='table'")

	for _, row in ipairs(result or {}) do
		table.insert(tables, row.name)
	end

	gSQLDebugPrint("SQLite", "SQLite tables", {
		status = "info",
		data = {
			tables = tables,
			count = #tables
		}
	})

	return tables
end

function gMySQLListTables(connectionName, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "List tables failed - connection", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(nil, errorMsg) end
		return
	end

	local db = GPYMOUSSS.MySQL.connections[connectionName].db
	local tables = {}

	local q = db:query("SHOW TABLES")
	q.onSuccess = function(_, data)
		for _, row in ipairs(data) do
			local firstKey = table.GetKeys(row)[1]
			table.insert(tables, row[firstKey])
		end

		gSQLDebugPrint("MySQL", "MySQL tables", {
			status = "success",
			data = {
				connection = connectionName,
				tables = tables,
				count = #tables
			}
		})

		if callback then callback(tables, nil) end
	end

	q.onError = function(_, err)
		gSQLDebugPrint("MySQL", "List tables failed", {
			status = "error",
			error = err,
			data = { connection = connectionName }
		})
		if callback then callback(nil, err) end
	end

	q:start()
end

function gSQLiteTableInfo(tableName)
	local valid, error = gSQLiteValidateName(tableName)
	if not valid then
		gSQLDebugPrint("SQLite", "Table info failed - invalid name", {
			status = "error",
			error = error,
			data = { table = tableName }
		})
		return nil
	end

	local info = {}
	info.columns = sql.Query("PRAGMA table_info(" .. tableName .. ")")
	info.indexes = sql.Query("PRAGMA index_list(" .. tableName .. ")")

	gSQLDebugPrint("SQLite", "SQLite table information", {
		status = "info",
		data = {
			table = tableName,
			column_count = info.columns and #info.columns or 0,
			index_count = info.indexes and #info.indexes or 0,
			info = info
		}
	})

	return info
end

function gMySQLTableInfo(connectionName, tableName, callback)
	local connValid, connError = gMySQLValidateConnection(connectionName)
	if not connValid then
		local errorMsg = "Connection validation failed: " .. connError
		gSQLDebugPrint("MySQL", "Table info failed - connection", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(nil, errorMsg) end
		return
	end

	local valid, error = gMySQLValidateName(tableName)
	if not valid then
		local errorMsg = "Invalid table name: " .. error
		gSQLDebugPrint("MySQL", "Table info failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(nil, errorMsg) end
		return
	end

	local db = GPYMOUSSS.MySQL.connections[connectionName].db
	local info = {}

	local q = db:query("DESCRIBE " .. tableName)
	q.onSuccess = function(_, data)
		info.columns = data

		local q2 = db:query("SHOW INDEX FROM " .. tableName)
		q2.onSuccess = function(_, data2)
			info.indexes = data2

			gSQLDebugPrint("MySQL", "MySQL table information", {
				status = "success",
				data = {
					connection = connectionName,
					table = tableName,
					column_count = info.columns and #info.columns or 0,
					index_count = info.indexes and #info.indexes or 0,
					info = info
				}
			})

			if callback then callback(info, nil) end
		end

		q2.onError = function(_, err)
			gSQLDebugPrint("MySQL", "Table indexes query failed", {
				status = "error",
				error = err,
				data = { connection = connectionName, table = tableName }
			})
			if callback then callback(nil, err) end
		end

		q2:start()
	end

	q.onError = function(_, err)
		gSQLDebugPrint("MySQL", "Table describe failed", {
			status = "error",
			error = err,
			data = { connection = connectionName, table = tableName }
		})
		if callback then callback(nil, err) end
	end

	q:start()
end

function gSQLDebugPrint(dbType, operation, data)
	if not GPYMOUSSS.Debug.Enabled then return end

	local operationType = operation:gsub(" .*", "")
	if not GPYMOUSSS.Debug.Config[dbType] or not GPYMOUSSS.Debug.Config[operationType] then
		return
	end

	local timestamp = os.date("[%H:%M:%S]")
	local status = data.status or "info"
	local statusColor = Color(200, 200, 200)

	if status == "success" then
		statusColor = Color(100, 255, 100)
	elseif status == "error" then
		statusColor = Color(255, 100, 100)
	elseif status == "info" then
		statusColor = Color(100, 150, 255)
	end

	MsgC(Color(150, 150, 150), timestamp)
	MsgC(Color(255, 255, 255), " [")
	MsgC(Color(255, 200, 100), dbType)
	MsgC(Color(255, 255, 255), "] ")
	MsgC(statusColor, operation)

	if data.error then
		MsgC(Color(255, 100, 100), " - ERROR: " .. data.error)
	end

	print("")

	if GPYMOUSSS.Debug.Verbose and data.data then
		for key, value in pairs(data.data) do
			if type(value) == "table" then
				print("  " .. key .. ":", table.ToString(value))
			else
				print("  " .. key .. ":", tostring(value))
			end
		end
		print("")
	end

	if data.query and GPYMOUSSS.Debug.Verbose then
		MsgC(Color(150, 150, 150), "  Query: ")
		MsgC(Color(200, 200, 255), data.query)
		print("")
		print("")
	end
end