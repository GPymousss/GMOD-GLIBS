function gQueryUpdate(tableName, data, conditions, callback)
	if GPYMOUSSS.SQL.usingSQLite then
		local setPairs = {}

		for col, value in pairs(data) do
			table.insert(setPairs, string.format("%s = %s", col, sql.SQLStr(tostring(value))))
		end

		local query = string.format("UPDATE %s SET %s", tableName, table.concat(setPairs, ", "))

		if conditions then
			local whereClause = {}
			for col, value in pairs(conditions) do
				table.insert(whereClause, string.format("%s = %s", col, sql.SQLStr(tostring(value))))
			end
			query = query .. " WHERE " .. table.concat(whereClause, " AND ")
		end

		local result = sql.Query(query)
		if callback then callback(result) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local setPairs = {}
	local values = {}

	for col, value in pairs(data) do
		table.insert(setPairs, string.format("%s = ?", col))
		table.insert(values, value)
	end

	local query = string.format("UPDATE %s SET %s", tableName, table.concat(setPairs, ", "))

	if conditions then
		local whereClause = {}
		for col, value in pairs(conditions) do
			table.insert(whereClause, string.format("%s = ?", col))
			table.insert(values, value)
		end
		query = query .. " WHERE " .. table.concat(whereClause, " AND ")
	end

	local q = GPYMOUSSS.SQL.db:prepare(query)
	for i, value in ipairs(values) do
		q:setString(i, tostring(value == nil and "NULL" or value))
	end
	
	gHandleQuery(q, callback)
end