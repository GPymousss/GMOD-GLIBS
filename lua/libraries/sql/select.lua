function gQuerySelect(tableName, columns, conditions, callback)
	if GPYMOUSSS.SQL.usingSQLite then
		local columnStr = columns and table.concat(columns, ", ") or "*"
		local query = string.format("SELECT %s FROM %s", columnStr, tableName)

		if conditions then
			local whereClause = {}
			for col, value in pairs(conditions) do
				if col == "OR" then
					local orClauses = {}
					for orCol, orVal in pairs(value) do
						table.insert(orClauses, string.format("%s = %s", orCol, sql.SQLStr(tostring(orVal))))
					end
					table.insert(whereClause, table.concat(orClauses, " OR "))
				else
					if type(value) == "table" then
						table.insert(whereClause, string.format("%s %s %s", col, value.operator or "=", sql.SQLStr(tostring(value.value))))
					else
						table.insert(whereClause, string.format("%s = %s", col, sql.SQLStr(tostring(value))))
					end
				end
			end
			query = query .. " WHERE " .. table.concat(whereClause, " AND ")
		end

		local result = sql.Query(query)

		gSQLDebugPrint("Select", "Selecting data from SQLite", {
			status = result ~= false and "success" or "error",
			query = query,
			error = result == false and sql.LastError() or nil,
			data = {
				table = tableName,
				columns = columns,
				conditions = conditions,
				rowCount = result and #result or 0
			}
		})

		if callback then callback(result) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local columnStr = columns and table.concat(columns, ", ") or "*"
	local queryStr = string.format("SELECT %s FROM %s", columnStr, tableName)
	local values = {}

	if conditions then
		local whereClause = {}
		for col, value in pairs(conditions) do
			if col == "OR" then
				local orClauses = {}
				for orCol, orVal in pairs(value) do
					table.insert(orClauses, string.format("%s = ?", orCol))
					table.insert(values, orVal)
				end
				table.insert(whereClause, "(" .. table.concat(orClauses, " OR ") .. ")")
			else
				if type(value) == "table" then
					table.insert(whereClause, string.format("%s %s ?", col, value.operator or "="))
					table.insert(values, value.value)
				else
					table.insert(whereClause, string.format("%s = ?", col))
					table.insert(values, value)
				end
			end
		end
		queryStr = queryStr .. " WHERE " .. table.concat(whereClause, " AND ")
	end

	local q = GPYMOUSSS.SQL.db:prepare(queryStr)
	for i, value in ipairs(values) do
		q:setString(i, tostring(value == nil and "NULL" or value))
	end

	gSQLDebugPrint("Select", "Selecting data from MySQL", {
		status = "info",
		query = queryStr,
		data = {
			table = tableName,
			columns = columns,
			conditions = conditions
		}
	})

	gHandleQuery(q, callback)
end