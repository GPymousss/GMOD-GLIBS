function gMySQLAddConnection(connectionName, config, callback)
	local valid, error = gMySQLValidateName(connectionName)
	if not valid then
		local errorMsg = "Invalid connection name: " .. error
		gSQLDebugPrint("MySQL", "Add connection failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not config or type(config) ~= "table" then
		local errorMsg = "Config must be a table"
		gSQLDebugPrint("MySQL", "Add connection failed - invalid config", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local requiredFields = {"host", "username", "database", "port"}
	for _, field in ipairs(requiredFields) do
		if not config[field] or config[field] == "" then
			local errorMsg = "Missing required field: " .. field
			gSQLDebugPrint("MySQL", "Add connection failed - missing field", {
				status = "error",
				error = errorMsg,
				data = { connection = connectionName, field = field }
			})
			if callback then callback(false, errorMsg) end
			return
		end
	end

	if GPYMOUSSS.MySQL.connections[connectionName] then
		local errorMsg = "Connection '" .. connectionName .. "' already exists"
		gSQLDebugPrint("MySQL", "Add connection failed - already exists", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	GPYMOUSSS.MySQL.connections[connectionName] = {
		host = config.host,
		username = config.username,
		password = config.password or "",
		database = config.database,
		port = config.port,
		socket = config.socket or "",
		db = nil
	}

	gSQLDebugPrint("MySQL", "Connection configuration added", {
		status = "success",
		data = {
			connection = connectionName,
			host = config.host,
			database = config.database,
			port = config.port
		}
	})

	if callback then callback(true, nil) end
end

function gMySQLConnect(connectionName, callback)
	local connValid, connError = gMySQLValidateName(connectionName)
	if not connValid then
		local errorMsg = "Invalid connection name: " .. connError
		gSQLDebugPrint("MySQL", "Connect failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not GPYMOUSSS.MySQL.connections[connectionName] then
		local errorMsg = "Connection '" .. connectionName .. "' does not exist"
		gSQLDebugPrint("MySQL", "Connect failed - not found", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local config = GPYMOUSSS.MySQL.connections[connectionName]

	if config.db and config.db:status() == mysqloo.DATABASE_CONNECTED then
		gSQLDebugPrint("MySQL", "Already connected", {
			status = "info",
			data = { connection = connectionName }
		})
		if callback then callback(true, nil) end
		return
	end

	gSQLDebugPrint("MySQL", "Attempting connection", {
		status = "info",
		data = {
			connection = connectionName,
			host = config.host,
			database = config.database,
			port = config.port
		}
	})

	config.db = mysqloo.connect(
		config.host,
		config.username,
		config.password,
		config.database,
		config.port,
		config.socket
	)

	config.db.onConnected = function()
		gSQLDebugPrint("MySQL", "Successfully connected", {
			status = "success",
			data = {
				connection = connectionName,
				host = config.host,
				database = config.database,
				connection_time = os.date("%H:%M:%S")
			}
		})

		if callback then callback(true, nil) end
	end

	config.db.onConnectionFailed = function(db, err)
		local errorType = "Connection Failed"
		if string.find(string.lower(err), "access denied") then
			errorType = "Authentication Failed"
		elseif string.find(string.lower(err), "unknown database") then
			errorType = "Database Not Found"
		elseif string.find(string.lower(err), "can't connect") then
			errorType = "Server Unreachable"
		end

		gSQLDebugPrint("MySQL", "Connection failed", {
			status = "error",
			error = err,
			data = {
				connection = connectionName,
				host = config.host,
				database = config.database,
				port = config.port,
				error_type = errorType
			}
		})

		config.db = nil
		if callback then callback(false, err) end
	end

	config.db:connect()

	timer.Simple(10, function()
		if config.db and config.db:status() ~= mysqloo.DATABASE_CONNECTED then
			gSQLDebugPrint("MySQL", "Connection timeout", {
				status = "error",
				data = {
					connection = connectionName,
					timeout_duration = "10 seconds",
					final_status = config.db:status()
				}
			})

			config.db = nil
			if callback then callback(false, "Connection timeout") end
		end
	end)
end

function gMySQLDisconnect(connectionName, callback)
	local connValid, connError = gMySQLValidateName(connectionName)
	if not connValid then
		local errorMsg = "Invalid connection name: " .. connError
		gSQLDebugPrint("MySQL", "Disconnect failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not GPYMOUSSS.MySQL.connections[connectionName] then
		local errorMsg = "Connection '" .. connectionName .. "' does not exist"
		gSQLDebugPrint("MySQL", "Disconnect failed - not found", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	local config = GPYMOUSSS.MySQL.connections[connectionName]

	if config.db then
		config.db:disconnect()
		config.db = nil

		gSQLDebugPrint("MySQL", "Disconnected successfully", {
			status = "success",
			data = { connection = connectionName }
		})
	else
		gSQLDebugPrint("MySQL", "Already disconnected", {
			status = "info",
			data = { connection = connectionName }
		})
	end

	if callback then callback(true, nil) end
end

function gMySQLRemoveConnection(connectionName, callback)
	local connValid, connError = gMySQLValidateName(connectionName)
	if not connValid then
		local errorMsg = "Invalid connection name: " .. connError
		gSQLDebugPrint("MySQL", "Remove connection failed - validation", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	if not GPYMOUSSS.MySQL.connections[connectionName] then
		local errorMsg = "Connection '" .. connectionName .. "' does not exist"
		gSQLDebugPrint("MySQL", "Remove connection failed - not found", {
			status = "error",
			error = errorMsg,
			data = { connection = connectionName }
		})
		if callback then callback(false, errorMsg) end
		return
	end

	gMySQLDisconnect(connectionName, function()
		GPYMOUSSS.MySQL.connections[connectionName] = nil

		gSQLDebugPrint("MySQL", "Connection removed", {
			status = "success",
			data = { connection = connectionName }
		})

		if callback then callback(true, nil) end
	end)
end