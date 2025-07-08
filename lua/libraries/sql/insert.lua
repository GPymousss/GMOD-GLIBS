function gQueryInsert(tableName, data, callback)
	local function checkForExistingData(data, callback)
		local primaryKeys = {"id", "steamid", "steamid64", "user_id"}
		local conditions = {}

		for _, key in ipairs(primaryKeys) do
			if data[key] then
				conditions[key] = data[key]
				break
			end
		end

		if table.Count(conditions) == 0 then
			callback(nil, "NEW_RECORD")
			return
		end

		gQuerySelect(tableName, nil, conditions, function(existingData)
			if existingData and #existingData > 0 then
				callback(existingData[1], "CONFLICT_DETECTED")
			else
				callback(nil, "NEW_RECORD")
			end
		end)
	end

	if GPYMOUSSS.SQL.usingSQLite then
		checkForExistingData(data, function(existingData, status)
			local columns = table.GetKeys(data)
			local values = {}

			for _, col in ipairs(columns) do
				table.insert(values, data[col] == nil and "NULL" or sql.SQLStr(tostring(data[col])))
			end

			local query = string.format("INSERT INTO %s (%s) VALUES (%s)",
				tableName,
				table.concat(columns, ", "),
				table.concat(values, ", ")
			)

			local result = sql.Query(query)
			local insertId = result ~= false and sql.Query("SELECT last_insert_rowid()")[1]["last_insert_rowid()"] or nil

			gSQLDebugPrint("Insert", "Inserting data in SQLite", {
				status = result ~= false and "success" or "error",
				query = query,
				error = result == false and sql.LastError() or nil,
				data = {
					table = tableName,
					values = data,
					insert_type = status,
					existing_data = existingData,
					new_record_id = insertId,
					is_overwrite = status == "CONFLICT_DETECTED"
				}
			})

			gLogQuery("INSERT", tableName, {
				values = data,
				insert_type = status,
				existing_data = existingData,
				new_record_id = insertId,
				is_overwrite = status == "CONFLICT_DETECTED"
			}, result, result == false and sql.LastError() or nil)

			if callback then callback(result) end
		end)
		return
	end

	if not GPYMOUSSS.SQL.db then return end

	checkForExistingData(data, function(existingData, status)
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

		q.onSuccess = function(query, result)
			local insertId = query:lastInsert()

			gSQLDebugPrint("Insert", "Inserting data in MySQL", {
				status = "success",
				query = queryStr,
				data = {
					table = tableName,
					values = data,
					params = values,
					insert_type = status,
					existing_data = existingData,
					new_record_id = insertId,
					is_overwrite = status == "CONFLICT_DETECTED"
				}
			})

			gLogQuery("INSERT", tableName, {
				values = data,
				insert_type = status,
				existing_data = existingData,
				new_record_id = insertId,
				is_overwrite = status == "CONFLICT_DETECTED"
			}, result, nil)

			if callback then callback(result, nil) end
		end

		q.onError = function(_, err)
			local conflictType = "UNKNOWN_ERROR"
			if string.find(string.lower(err), "duplicate") or string.find(string.lower(err), "unique") then
				conflictType = "DUPLICATE_KEY_ERROR"
			end

			gSQLDebugPrint("Insert", "Insert failed in MySQL", {
				status = "error",
				query = queryStr,
				error = err,
				data = {
					table = tableName,
					values = data,
					params = values,
					insert_type = status,
					existing_data = existingData,
					conflict_type = conflictType,
					is_duplicate_error = conflictType == "DUPLICATE_KEY_ERROR"
				}
			})

			gLogQuery("INSERT", tableName, {
				values = data,
				insert_type = status,
				existing_data = existingData,
				conflict_type = conflictType
			}, nil, err)

			if callback then callback(nil, err) end
		end

		q:start()
	end)
end

function gQueryInsertOrUpdate(tableName, data, conditions, callback)
	gQuerySelect(tableName, nil, conditions or data, function(existingData)
		if existingData and #existingData > 0 then
			gSQLDebugPrint("InsertOrUpdate", "Record exists, updating", {
				status = "info",
				data = {
					table = tableName,
					action = "UPDATE",
					existing_record = existingData[1]
				}
			})

			gQueryUpdate(tableName, data, conditions or data, callback)
		else
			gSQLDebugPrint("InsertOrUpdate", "Record doesn't exist, inserting", {
				status = "info",
				data = {
					table = tableName,
					action = "INSERT"
				}
			})

			gQueryInsert(tableName, data, callback)
		end
	end)
end

function gQueryUpsert(tableName, data, uniqueColumns, callback)
	local conditions = {}

	for _, col in ipairs(uniqueColumns) do
		if data[col] then
			conditions[col] = data[col]
		end
	end

	if table.Count(conditions) == 0 then
		gSQLDebugPrint("Upsert", "No unique columns found, forcing insert", {
			status = "warning",
			data = {
				table = tableName,
				unique_columns = uniqueColumns
			}
		})

		gQueryInsert(tableName, data, callback)
		return
	end

	gQueryInsertOrUpdate(tableName, data, conditions, callback)
end