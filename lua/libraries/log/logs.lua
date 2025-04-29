local tables = {}

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

		if GPYMOUSSS.SQL.usingSQLite then
			local query = string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, name, columnTypes[type])
			local result = sql.Query(query)

			gSQLDebugPrint("Logs", "Adding column to log table in SQLite", {
				status = result ~= false and "success" or "error",
				query = query,
				error = result == false and sql.LastError() or nil,
				data = {
					table = tableName,
					column = name,
					type = columnTypes[type]
				}
			})
		else
			if GPYMOUSSS.SQL.db then
				local queryStr = string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, name, columnTypes[type])
				local q = GPYMOUSSS.SQL.db:query(queryStr)

				gSQLDebugPrint("Logs", "Adding column to log table in MySQL", {
					status = "info",
					query = queryStr,
					data = {
						table = tableName,
						column = name,
						type = columnTypes[type]
					}
				})

				q:start()
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

	if GPYMOUSSS.SQL.usingSQLite then
		local columns = table.GetKeys(data)
		local values = {}

		for _, col in ipairs(columns) do
			table.insert(values, sql.SQLStr(tostring(data[col])))
		end

		local query = string.format("INSERT INTO %s (%s) VALUES (%s)", 
			tableName,
			table.concat(columns, ", "), 
			table.concat(values, ", ")
		)

		local result = sql.Query(query)

		gSQLDebugPrint("Logs", "Inserted log data in SQLite", {
			status = result ~= false and "success" or "error",
			query = query,
			error = result == false and sql.LastError() or nil
		})

		return result ~= false
	else
		if not GPYMOUSSS.SQL.db then 
			gSQLDebugPrint("Logs", "MySQL connection not available", {
				status = "error"
			})
			return false 
		end

		local columns = table.GetKeys(data)
		local placeholders = {}
		local values = {}

		for _, col in ipairs(columns) do
			table.insert(placeholders, "?")
			table.insert(values, data[col])
		end

		local queryStr = string.format("INSERT INTO %s (%s) VALUES (%s)",
			tableName,
			table.concat(columns, ", "),
			table.concat(placeholders, ", ")
		)

		local q = GPYMOUSSS.SQL.db:prepare(queryStr)

		for i, value in ipairs(values) do
			q:setString(i, tostring(value))
		end

		q:start()

		gSQLDebugPrint("Logs", "Inserted log data in MySQL", {
			status = "success",
			query = queryStr
		})

		return true
	end
end