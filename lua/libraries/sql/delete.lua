function gQueryDelete(tableName, conditions, callback)
	if GPYMOUSSS.SQL.usingSQLite then
		local query = string.format("DELETE FROM %s", tableName)

		if conditions then
			local whereClause = {}
			for col, value in pairs(conditions) do
				table.insert(whereClause, string.format("%s = %s", col, sql.SQLStr(tostring(value))))
			end
			query = query .. " WHERE " .. table.concat(whereClause, " AND ")
		end

		local result = sql.Query(query)

		gSQLDebugPrint("Delete", "Deleting data from SQLite", {
			status = result ~= false and "success" or "error",
			query = query,
			error = result == false and sql.LastError() or nil,
			data = {
				table = tableName,
				conditions = conditions
			}
		})

		if callback then callback(result) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local queryStr = string.format("DELETE FROM %s", tableName)
	local values = {}

	if conditions then
		local whereClause = {}
		for col, value in pairs(conditions) do
			table.insert(whereClause, string.format("%s = ?", col))
			table.insert(values, value)
		end
		queryStr = queryStr .. " WHERE " .. table.concat(whereClause, " AND ")
	end

	local q = GPYMOUSSS.SQL.db:prepare(queryStr)
	for i, value in ipairs(values) do
		q:setString(i, tostring(value == nil and "NULL" or value))
	end

	gSQLDebugPrint("Delete", "Deleting data from MySQL", {
		status = "info",
		query = queryStr,
		data = {
			table = tableName,
			conditions = conditions
		}
	})

	gHandleQuery(q, callback)
end