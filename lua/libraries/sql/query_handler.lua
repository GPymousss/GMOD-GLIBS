function gFormatExecutionTime(seconds)
	if seconds < 0.001 then
		return string.format("%.3f µs", seconds * 1000000)
	elseif seconds < 1 then
		return string.format("%.2f ms", seconds * 1000)
	else
		return string.format("%.3f s", seconds)
	end
end

function gHandleQuery(query, callback, queryString, queryParams)
	if not query then return end

	local storedQuery = queryString or "Unknown"
	local storedParams = queryParams or {}
	local startTime = os.clock()

	query.onSuccess = function(q, data)
		local executionTime = os.clock() - startTime
		local finalQuery = storedQuery

		if q and type(q.lastQuery) == "function" then
			local success, result = pcall(function() return q:lastQuery() end)
			if success and result then
				finalQuery = result
			end
		end

		local logData = {
			query = finalQuery,
			params = storedParams,
			resultCount = data and #data or 0,
			executionTime = executionTime,
			executionTimeFormatted = gFormatExecutionTime(executionTime)
		}

		gSQLDebugPrint("Query", "Query executed successfully", {
			status = "success",
			query = finalQuery,
			data = logData
		})

		if callback then callback(data, nil) end
	end

	query.onError = function(q, err)
		local executionTime = os.clock() - startTime
		local finalQuery = storedQuery

		if q and type(q.lastQuery) == "function" then
			local success, result = pcall(function() return q:lastQuery() end)
			if success and result then
				finalQuery = result
			end
		end

		local logData = {
			query = finalQuery,
			params = storedParams,
			error = err,
			executionTime = executionTime,
			executionTimeFormatted = gFormatExecutionTime(executionTime)
		}

		gSQLDebugPrint("Query", "Query failed", {
			status = "error",
			query = finalQuery,
			error = err,
			data = logData
		})

		if callback then callback(nil, err) end
	end

	pcall(function() query:start() end)
end

function gEnhancedQuery(queryString, params, callback)
	if not GPYMOUSSS.SQL.db then 
		gSQLDebugPrint("Query", "MySQL connection not available", {
			status = "error",
			query = queryString
		})
		return 
	end

	local startTime = os.clock()
	local q = GPYMOUSSS.SQL.db:prepare(queryString)

	if params then
		for i, param in ipairs(params) do
			q:setString(i, tostring(param == nil and "NULL" or param))
		end
	end

	q.onSuccess = function(query, data)
		local executionTime = os.clock() - startTime

		gSQLDebugPrint("Query", "Enhanced query executed successfully", {
			status = "success",
			query = queryString,
			data = {
				params = params,
				resultCount = data and #data or 0,
				executionTime = executionTime
			}
		})

		if callback then callback(data, nil) end
	end

	q.onError = function(query, err)
		local executionTime = os.clock() - startTime

		gSQLDebugPrint("Query", "Enhanced query failed", {
			status = "error",
			query = queryString,
			error = err,
			data = {
				params = params,
				executionTime = executionTime
			}
		})

		if callback then callback(nil, err) end
	end

	q:start()
	return q
end