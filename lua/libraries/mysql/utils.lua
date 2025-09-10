function gMySQLValidateName(name)
	if not name or type(name) ~= "string" or name == "" then
		return false, "Invalid name: must be a non-empty string"
	end

	if string.len(name) > 64 then
		return false, "Invalid name: too long (max 64 characters)"
	end

	if not string.match(name, "^[a-zA-Z_][a-zA-Z0-9_]*$") then
		return false, "Invalid name: only letters, numbers and underscores allowed, must start with letter or underscore"
	end

	local reservedWords = {
		"SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "ALTER", "TABLE", 
		"INDEX", "VIEW", "TRIGGER", "DATABASE", "SCHEMA", "SHOW", "DESCRIBE",
		"WHERE", "FROM", "JOIN", "INNER", "OUTER", "LEFT", "RIGHT", "ON", "AS",
		"GROUP", "ORDER", "BY", "HAVING", "LIMIT", "OFFSET", "UNION", "INTERSECT",
		"AND", "OR", "NOT", "NULL", "TRUE", "FALSE", "IS", "IN", "LIKE",
		"BETWEEN", "EXISTS", "CASE", "WHEN", "THEN", "ELSE", "END"
	}

	for _, word in ipairs(reservedWords) do
		if string.upper(name) == word then
			return false, "Invalid name: '" .. name .. "' is a reserved SQL keyword"
		end
	end

	return true, nil
end

function gMySQLValidateData(data)
	if not data or type(data) ~= "table" then
		return false, "Data must be a table"
	end

	if table.Count(data) == 0 then
		return false, "Data table cannot be empty"
	end

	for key, value in pairs(data) do
		local valid, error = gMySQLValidateName(key)
		if not valid then
			return false, "Invalid column name '" .. tostring(key) .. "': " .. error
		end

		local valueType = type(value)
		if valueType ~= "string" and valueType ~= "number" and valueType ~= "boolean" and value ~= nil then
			return false, "Invalid data type for column '" .. key .. "': " .. valueType .. " (only string, number, boolean, nil allowed)"
		end
	end

	return true, nil
end

function gMySQLValidateConnection(connectionName)
	if not connectionName or type(connectionName) ~= "string" or connectionName == "" then
		return false, "Connection name must be a non-empty string"
	end

	if not GPYMOUSSS.MySQL.connections[connectionName] then
		return false, "Connection '" .. connectionName .. "' does not exist"
	end

	local conn = GPYMOUSSS.MySQL.connections[connectionName]
	if not conn.db then
		return false, "Connection '" .. connectionName .. "' is not initialized"
	end

	if conn.db:status() ~= mysqloo.DATABASE_CONNECTED then
		return false, "Connection '" .. connectionName .. "' is not connected (status: " .. tostring(conn.db:status()) .. ")"
	end

	return true, nil
end

function gMySQLParseColumnDefinition(name, definition)
	if type(definition) == "string" then
		local parts = {}
		for part in definition:gmatch("%S+") do
			table.insert(parts, part:upper())
		end
		local baseType = parts[1]
		local constraints = {}

		for i = 2, #parts do
			table.insert(constraints, parts[i])
		end

		return baseType, table.concat(constraints, " ")
	end
	return definition.type, ""
end

function gMySQLBuildWhereClause(conditions)
	if not conditions or type(conditions) ~= "table" or table.Count(conditions) == 0 then 
		return "", {}
	end

	local whereClause = {}
	local params = {}

	for col, value in pairs(conditions) do
		local valid, error = gMySQLValidateName(col)
		if col ~= "OR" and not valid then
			gSQLDebugPrint("MySQL", "Invalid column name in WHERE clause", {
				status = "error",
				data = { column = col, error = error }
			})
			continue
		end

		if col == "OR" then
			if type(value) == "table" then
				local orClauses = {}
				for orCol, orVal in pairs(value) do
					local orValid, orError = gMySQLValidateName(orCol)
					if orValid then
						table.insert(orClauses, string.format("%s = ?", orCol))
						table.insert(params, orVal)
					end
				end
				if #orClauses > 0 then
					table.insert(whereClause, "(" .. table.concat(orClauses, " OR ") .. ")")
				end
			end
		else
			if type(value) == "table" and value.operator and value.value then
				local allowedOperators = {"=", "!=", "<>", "<", ">", "<=", ">=", "LIKE", "NOT LIKE", "IN", "NOT IN"}
				local operatorValid = false
				for _, op in ipairs(allowedOperators) do
					if string.upper(value.operator) == op then
						operatorValid = true
						break
					end
				end

				if operatorValid then
					table.insert(whereClause, string.format("%s %s ?", col, value.operator))
					table.insert(params, value.value)
				else
					gSQLDebugPrint("MySQL", "Invalid operator in WHERE clause", {
						status = "error",
						data = { column = col, operator = value.operator }
					})
				end
			else
				table.insert(whereClause, string.format("%s = ?", col))
				table.insert(params, value)
			end
		end
	end

	if #whereClause == 0 then
		return "", {}
	end

	return " WHERE " .. table.concat(whereClause, " AND "), params
end

function gMySQLHandleQuery(query, callback, queryString, params)
	if not query then 
		if callback then callback(nil, "Invalid query object") end
		return 
	end

	local storedQuery = queryString or "Unknown"
	local storedParams = params or {}
	local startTime = os.clock()

	query.onSuccess = function(q, data)
		local executionTime = os.clock() - startTime

		gSQLDebugPrint("MySQL", "Query executed successfully", {
			status = "success",
			query = storedQuery,
			data = {
				params = storedParams,
				result_count = data and #data or 0,
				execution_time = executionTime
			}
		})

		if callback then callback(data, nil) end
	end

	query.onError = function(q, err)
		local executionTime = os.clock() - startTime

		gSQLDebugPrint("MySQL", "Query failed", {
			status = "error",
			query = storedQuery,
			error = err,
			data = {
				params = storedParams,
				execution_time = executionTime
			}
		})

		if callback then callback(nil, err) end
	end

	pcall(function() query:start() end)
end