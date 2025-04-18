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
	if not columnTypes[type] then return false end

	if not tables[tableName].existingColumns[name] then
		tables[tableName].pendingColumns[name] = columnTypes[type]

		if GPYMOUSSS.SQL.usingSQLite then
			sql.Query(string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, name, columnTypes[type]))
		else
			if GPYMOUSSS.SQL.db then
				local q = GPYMOUSSS.SQL.db:query(string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, name, columnTypes[type]))
				q:start()
			end
		end

		tables[tableName].existingColumns[name] = true
	end
	return true
end

function gLogs(tableName, ...)
	if not tableName then return false end

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

		gQueryCreateTable(tableName, columns)
	end

	local args = {...}
	if #args == 0 then return false end
	if #args % 3 != 0 then return false end

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

	if hasError or table.Count(data) == 0 then return false end

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

		return sql.Query(query) != false
	else
		if not GPYMOUSSS.SQL.db then return false end

		local columns = table.GetKeys(data)
		local placeholders = {}
		local values = {}

		for _, col in ipairs(columns) do
			table.insert(placeholders, "?")
			table.insert(values, data[col])
		end

		local q = GPYMOUSSS.SQL.db:prepare(string.format("INSERT INTO %s (%s) VALUES (%s)",
			tableName,
			table.concat(columns, ", "),
			table.concat(placeholders, ", ")
		))

		for i, value in ipairs(values) do
			q:setString(i, tostring(value))
		end

		q:start()
		return true
	end
end