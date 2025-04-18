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

	local q = GPYMOUSSS.SQL.db:prepare(string.format("INSERT INTO %s (%s) VALUES (%s)",
		tableName,
		table.concat(columns, ", "),
		table.concat(placeholders, ", ")
	))

	for i, value in ipairs(values) do
		q:setString(i, tostring(value == nil and "NULL" or value))
	end

	gHandleQuery(q, callback)
end