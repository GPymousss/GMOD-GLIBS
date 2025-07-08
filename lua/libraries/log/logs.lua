local tables = {}
local queryHistory = {}

local columnTypes = {
	STRING = "VARCHAR(255)",
	TEXT = "TEXT",
	INT = "INTEGER",
	FLOAT = "FLOAT",
	BOOL = "BOOLEAN",
	DATE = "TIMESTAMP"
}

local function ensureColumn(tableName, name, type)
	if not columnTypes[type] then 
		gSQLDebugPrint("Logs", "Invalid column type: " .. type, {
			status = "error",
			data = {
				table = tableName,
				column = name,
				type = type
			}
		})
		return false 
	end

	if not tables[tableName].existingColumns[name] then
		tables[tableName].pendingColumns[name] = columnTypes[type]

		local actualQuery = string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, name, columnTypes[type])

		if GPYMOUSSS.SQL.usingSQLite then
			local result = sql.Query(actualQuery)

			gSQLDebugPrint("Logs", "Adding column to log table in SQLite", {
				status = result ~= false and "success" or "error",
				query = actualQuery,
				error = result == false and sql.LastError() or nil,
				data = {
					table = tableName,
					column = name,
					type = columnTypes[type]
				}
			})
		else
			if GPYMOUSSS.SQL.db then
				local q = GPYMOUSSS.SQL.db:query(actualQuery)

				gSQLDebugPrint("Logs", "Adding column to log table in MySQL", {
					status = "info",
					query = actualQuery,
					data = {
						table = tableName,
						column = name,
						type = columnTypes[type]
					}
				})

				gHandleQuery(q, nil, actualQuery)
			end
		end

		tables[tableName].existingColumns[name] = true
	end
	return true
end

function gLogs(tableName, ...)
	if not tableName then 
		gSQLDebugPrint("Logs", "No table name provided", {
			status = "error"
		})
		return false 
	end

	if not tables[tableName] then
		tables[tableName] = {
			existingColumns = {
				id = true,
				date = true
			},
			pendingColumns = {}
		}

		local columns = {
			id = "INTEGER PRIMARY KEY AUTOINCREMENT",
			date = "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
		}

		gSQLDebugPrint("Logs", "Creating new log table", {
			status = "info",
			data = {
				table = tableName
			}
		})

		gQueryCreateTable(tableName, columns)
	end

	local args = {...}
	if #args == 0 then 
		gSQLDebugPrint("Logs", "No data provided", {
			status = "error",
			data = {
				table = tableName
			}
		})
		return false 
	end

	if #args % 3 ~= 0 then 
		gSQLDebugPrint("Logs", "Invalid arguments format (must be in triplets: name, type, value)", {
			status = "error",
			data = {
				table = tableName,
				argCount = #args
			}
		})
		return false 
	end

	local data = {}
	local hasError = false

	for i = 1, #args, 3 do
		local columnName = args[i]
		local columnType = args[i + 1]
		local value = args[i + 2]

		if not columnName or not columnType or not value then break end
		if columnName == "id" or columnName == "date" then continue end

		if not ensureColumn(tableName, columnName, columnType) then
			hasError = true
			continue
		end

		data[columnName] = value
	end

	if hasError or table.Count(data) == 0 then 
		gSQLDebugPrint("Logs", "No valid data to insert", {
			status = "error",
			data = {
				table = tableName
			}
		})
		return false 
	end

	gSQLDebugPrint("Logs", "Inserting log data", {
		status = "info",
		data = {
			table = tableName,
			values = data
		}
	})

	gQueryInsert(tableName, data, function(result, error)
		if error then
			gSQLDebugPrint("Logs", "Failed to insert log data", {
				status = "error",
				error = error,
				data = {
					table = tableName,
					values = data
				}
			})
		else
			gSQLDebugPrint("Logs", "Log data inserted successfully", {
				status = "success",
				data = {
					table = tableName,
					values = data
				}
			})
		end
	end)

	return true
end

function gLogQuery(queryType, tableName, queryData, result, error)
	local logData = {
		query_type = queryType,
		table_name = tableName,
		query_data = util.TableToJSON(queryData or {}),
		success = error == nil,
		error_message = error or "",
		execution_time = os.date("%Y-%m-%d %H:%M:%S")
	}

	table.insert(queryHistory, logData)

	if #queryHistory > 1000 then
		table.remove(queryHistory, 1)
	end
end

function gGetQueryHistory(limit)
	limit = limit or 100
	local history = {}

	for i = math.max(1, #queryHistory - limit + 1), #queryHistory do
		table.insert(history, queryHistory[i])
	end

	return history
end

function gClearQueryHistory()
	queryHistory = {}
	gSQLDebugPrint("Logs", "Query history cleared", {
		status = "info"
	})
end

function gCreateQueryLogsTable()
	if GPYMOUSSS.SQL.usingSQLite then
		local query = [[
			CREATE TABLE IF NOT EXISTS gquery_logs (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
				query_type VARCHAR(255),
				table_name VARCHAR(255),
				query_data TEXT,
				success INTEGER,
				error_message TEXT,
				execution_time VARCHAR(255)
			)
		]]

		local result = sql.Query(query)

		gSQLDebugPrint("Logs", "Creating gquery_logs table in SQLite", {
			status = result ~= false and "success" or "error",
			query = query,
			error = result == false and sql.LastError() or nil
		})
	else
		if not GPYMOUSSS.SQL.db then return end

		local query = [[
			CREATE TABLE IF NOT EXISTS gquery_logs (
				id INTEGER PRIMARY KEY AUTO_INCREMENT,
				date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
				query_type VARCHAR(255),
				table_name VARCHAR(255),
				query_data TEXT,
				success BOOLEAN,
				error_message TEXT,
				execution_time VARCHAR(255)
			)
		]]

		local q = GPYMOUSSS.SQL.db:query(query)

		gSQLDebugPrint("Logs", "Creating gquery_logs table in MySQL", {
			status = "info",
			query = query
		})

		q.onSuccess = function()
			gSQLDebugPrint("Logs", "gquery_logs table created successfully", {
				status = "success",
				query = query
			})
		end

		q.onError = function(_, err)
			gSQLDebugPrint("Logs", "Failed to create gquery_logs table", {
				status = "error",
				query = query,
				error = err
			})
		end

		q:start()
	end
end

function gSaveQueryToLogs(queryType, tableName, queryData, result, error)
	local data = {
		query_type = queryType,
		table_name = tableName,
		query_data = util.TableToJSON(queryData or {}),
		success = error == nil and 1 or 0,
		error_message = error or "",
		execution_time = os.date("%Y-%m-%d %H:%M:%S")
	}

	gQueryInsert("gquery_logs", data)
end