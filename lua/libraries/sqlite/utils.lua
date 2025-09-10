function gSQLiteValidateName(name)
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
		"INDEX", "VIEW", "TRIGGER", "DATABASE", "SCHEMA", "PRAGMA", "VACUUM",
		"WHERE", "FROM", "JOIN", "INNER", "OUTER", "LEFT", "RIGHT", "ON", "AS",
		"GROUP", "ORDER", "BY", "HAVING", "LIMIT", "OFFSET", "UNION", "INTERSECT",
		"EXCEPT", "AND", "OR", "NOT", "NULL", "TRUE", "FALSE", "IS", "IN", "LIKE",
		"BETWEEN", "EXISTS", "CASE", "WHEN", "THEN", "ELSE", "END"
	}

	for _, word in ipairs(reservedWords) do
		if string.upper(name) == word then
			return false, "Invalid name: '" .. name .. "' is a reserved SQL keyword"
		end
	end

	return true, nil
end

function gSQLiteValidateData(data)
	if not data or type(data) ~= "table" then
		return false, "Data must be a table"
	end

	if table.Count(data) == 0 then
		return false, "Data table cannot be empty"
	end

	for key, value in pairs(data) do
		local valid, error = gSQLiteValidateName(key)
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

function gSQLiteParseColumnDefinition(name, definition)
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

function gSQLiteConvertType(baseType)
	if not baseType or type(baseType) ~= "string" then
		return "TEXT"
	end

	local sqliteType = string.lower(baseType)

	if string.find(sqliteType, "int") then
		return "INTEGER"
	elseif string.find(sqliteType, "varchar") or string.find(sqliteType, "text") then
		return "TEXT"
	elseif string.find(sqliteType, "real") or string.find(sqliteType, "float") or string.find(sqliteType, "double") then
		return "REAL"
	elseif string.find(sqliteType, "blob") then
		return "BLOB"
	end

	return "TEXT"
end

function gSQLiteBuildWhereClause(conditions)
	if not conditions or type(conditions) ~= "table" or table.Count(conditions) == 0 then 
		return "" 
	end

	local whereClause = {}
	for col, value in pairs(conditions) do
		local valid, error = gSQLiteValidateName(col)
		if col ~= "OR" and not valid then
			if gSQLDebugPrint then
				gSQLDebugPrint("SQLite", "Invalid column name in WHERE clause", {
					status = "error",
					data = { column = col, error = error }
				})
			end
			continue
		end

		if col == "OR" then
			if type(value) == "table" then
				local orClauses = {}
				for orCol, orVal in pairs(value) do
					local orValid, orError = gSQLiteValidateName(orCol)
					if orValid then
						table.insert(orClauses, string.format("%s = %s", orCol, sql.SQLStr(tostring(orVal))))
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
					table.insert(whereClause, string.format("%s %s %s", col, value.operator, sql.SQLStr(tostring(value.value))))
				else
					if gSQLDebugPrint then
						gSQLDebugPrint("SQLite", "Invalid operator in WHERE clause", {
							status = "error",
							data = { column = col, operator = value.operator }
						})
					end
				end
			else
				table.insert(whereClause, string.format("%s = %s", col, sql.SQLStr(tostring(value))))
			end
		end
	end

	if #whereClause == 0 then
		return ""
	end

	return " WHERE " .. table.concat(whereClause, " AND ")
end

function gSQLiteExecuteQuery(query, operation, tableName, data)
	if not query or type(query) ~= "string" or query == "" then
		local error = "Invalid query: must be a non-empty string"
		if gSQLDebugPrint then
			gSQLDebugPrint("SQLite", operation, {
				status = "error",
				error = error,
				data = data
			})
		end
		return false, error
	end

	local result = sql.Query(query)
	local error = result == false and sql.LastError() or nil

	local success = (error == nil or error == "")

	if gSQLDebugPrint then
		gSQLDebugPrint("SQLite", operation, {
			status = success and "success" or "error",
			query = query,
			error = error,
			data = data
		})
	end

	return success and (result or true), error
end