function gQueryInsert(tableName, data, callback)
	if GPYMOUSSS.SQL.usingSQLite then
		local columns = table.GetKeys(data)
		local values = {}
		local placeholders = {}

		for _, col in ipairs(columns) do
			table.insert(values, data[col] == nil and "NULL" or sql.SQLStr(tostring(data[col])))
			table.insert(placeholders, "?")
		end

		local query = string.format("INSERT INTO %s (%s) VALUES (%s)",
			tableName,
			table.concat(columns, ", "),
			table.concat(values, ", ")
		)

		local result = sql.Query(query)

		gSQLDebugPrint("Insert", "Inserting data in SQLite", {
			status = result ~= false and "success" or "error",
			query = query,
			error = result == false and sql.LastError() or nil,
			data = {
				table = tableName,
				values = data
			}
		})

		if callback then callback(result) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

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
		q:setString(i, tostring(value == nil and "NULL" or value))
	end

	gSQLDebugPrint("Insert", "Inserting data in MySQL", {
		status = "info",
		query = queryStr,
		data = {
			table = tableName,
			values = data
		}
	})

	gHandleQuery(q, callback)
end