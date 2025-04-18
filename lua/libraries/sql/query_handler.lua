function gHandleQuery(query, callback)
	if not query then return end

	query.onSuccess = function(_, data)
		if callback then callback(data, nil) end
	end

	query.onError = function(_, err)
		if callback then callback(nil, err) end
	end

	pcall(function() query:start() end)
end