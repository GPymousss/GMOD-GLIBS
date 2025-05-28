function gHandleQuery(query, callback)
	if not query then return end

	query.onSuccess = function(q, data)
		local queryString = "Unknown"

		if q and type(q.lastQuery) == "function" then
			local success, result = pcall(function() return q:lastQuery() end)
			if success and result then
				queryString = result
			end
		end

		gSQLDebugPrint("Query", "Query executed successfully", {
			status = "success",
			query = queryString,
			data = data
		})

		if callback then callback(data, nil) end
	end

	query.onError = function(q, err)
		local queryString = "Unknown"

		if q and type(q.lastQuery) == "function" then
			local success, result = pcall(function() return q:lastQuery() end)
			if success and result then
				queryString = result
			end
		end

		gSQLDebugPrint("Query", "Query failed", {
			status = "error",
			query = queryString,
			error = err
		})

		if callback then callback(nil, err) end
	end

	pcall(function() query:start() end)
end