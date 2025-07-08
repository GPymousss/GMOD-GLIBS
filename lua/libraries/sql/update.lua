function gQueryUpdate(tableName, data, conditions, callback)
	local function logBeforeAfter(beforeData, afterData, updateData, conditions)
		local changes = {}

		for col, newValue in pairs(updateData) do
			local oldValue = beforeData and beforeData[col] or "NULL"
			if tostring(oldValue) ~= tostring(newValue) then
				table.insert(changes, {
					column = col,
					old_value = oldValue,
					new_value = newValue
				})
			end
		end

		gSQLDebugPrint("Update", "Data modification details", {
			status = "info",
			data = {
				table = tableName,
				conditions = conditions,
				changes = changes,
				rows_affected = afterData and #afterData or 0,
				before_data = beforeData,
				after_data = afterData
			}
		})
	end

	if GPYMOUSSS.SQL.usingSQLite then
		local beforeQuery = string.format("SELECT * FROM %s", tableName)

		if conditions then
			local whereClause = {}
			for col, value in pairs(conditions) do
				table.insert(whereClause, string.format("%s = %s", col, sql.SQLStr(tostring(value))))
			end
			beforeQuery = beforeQuery .. " WHERE " .. table.concat(whereClause, " AND ")
		end

		local beforeData = sql.Query(beforeQuery)

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

		local afterData = nil
		if result ~= false and conditions then
			afterData = sql.Query(beforeQuery)
		end

		logBeforeAfter(beforeData and beforeData[1] or nil, afterData and afterData[1] or nil, data, conditions)

		gSQLDebugPrint("Update", "Updating data in SQLite", {
			status = result ~= false and "success" or "error",
			query = query,
			error = result == false and sql.LastError() or nil,
			data = {
				table = tableName,
				values = data,
				conditions = conditions,
				rows_affected = sql.Query("SELECT changes()")[1]["changes()"]
			}
		})

		gLogQuery("UPDATE", tableName, {
			values = data,
			conditions = conditions,
			before_data = beforeData and beforeData[1] or nil,
			after_data = afterData and afterData[1] or nil
		}, result, result == false and sql.LastError() or nil)

		if callback then callback(result) end
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	local selectQuery = string.format("SELECT * FROM %s", tableName)
	local selectValues = {}

	if conditions then
		local whereClause = {}
		for col, value in pairs(conditions) do
			table.insert(whereClause, string.format("%s = ?", col))
			table.insert(selectValues, value)
		end
		selectQuery = selectQuery .. " WHERE " .. table.concat(whereClause, " AND ")
	end

	local beforeQuery = GPYMOUSSS.SQL.db:prepare(selectQuery)
	for i, value in ipairs(selectValues) do
		beforeQuery:setString(i, tostring(value == nil and "NULL" or value))
	end

	beforeQuery.onSuccess = function(_, beforeData)
		local setPairs = {}
		local values = {}

		for col, value in pairs(data) do
			table.insert(setPairs, string.format("%s = ?", col))
			table.insert(values, value)
		end

		local queryStr = string.format("UPDATE %s SET %s", tableName, table.concat(setPairs, ", "))

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

		q.onSuccess = function(_, updateResult)
			local afterQuery = GPYMOUSSS.SQL.db:prepare(selectQuery)
			for i, value in ipairs(selectValues) do
				afterQuery:setString(i, tostring(value == nil and "NULL" or value))
			end

			afterQuery.onSuccess = function(_, afterData)
				logBeforeAfter(beforeData and beforeData[1] or nil, afterData and afterData[1] or nil, data, conditions)

				gSQLDebugPrint("Update", "Updating data in MySQL", {
					status = "success",
					query = queryStr,
					data = {
						table = tableName,
						values = data,
						conditions = conditions,
						params = values,
						rows_affected = q:affectedRows(),
						before_data = beforeData and beforeData[1] or nil,
						after_data = afterData and afterData[1] or nil
					}
				})

				gLogQuery("UPDATE", tableName, {
					values = data,
					conditions = conditions,
					before_data = beforeData and beforeData[1] or nil,
					after_data = afterData and afterData[1] or nil,
					rows_affected = q:affectedRows()
				}, updateResult, nil)

				if callback then callback(updateResult, nil) end
			end

			afterQuery.onError = function(_, err)
				gSQLDebugPrint("Update", "Failed to fetch after data", {
					status = "error",
					error = err
				})
				if callback then callback(updateResult, nil) end
			end

			afterQuery:start()
		end

		q.onError = function(_, err)
			gSQLDebugPrint("Update", "Update failed in MySQL", {
				status = "error",
				query = queryStr,
				error = err,
				data = {
					table = tableName,
					values = data,
					conditions = conditions,
					params = values
				}
			})

			gLogQuery("UPDATE", tableName, {
				values = data,
				conditions = conditions
			}, nil, err)

			if callback then callback(nil, err) end
		end

		q:start()
	end

	beforeQuery.onError = function(_, err)
		gSQLDebugPrint("Update", "Failed to fetch before data", {
			status = "error",
			error = err
		})
		if callback then callback(nil, err) end
	end

	beforeQuery:start()
end