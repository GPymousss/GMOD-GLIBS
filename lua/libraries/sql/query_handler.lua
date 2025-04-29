function gHandleQuery(query, callback)
	if not query then return end

	query.onSuccess = function(q, data)
		gSQLDebugPrint("Query", "Query executed successfully", {
			status = "success",
			query = q:lastQuery(),
			data = data
		})

		if callback then callback(data, nil) end
	end

	query.onError = function(q, err)
		gSQLDebugPrint("Query", "Query failed", {
			status = "error",
			query = q:lastQuery(),
			error = err
		})

		if callback then callback(nil, err) end
	end

	pcall(function() query:start() end)
end