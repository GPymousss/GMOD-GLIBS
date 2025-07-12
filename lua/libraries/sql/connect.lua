local CONFIG_SQL = {
	MySQL = {
		host = "",
		username = "",
		password = "",
		database = "",
		port = "",
		socket = ""
	}
}

local function isValidMySQLConfig()
	if not CONFIG_SQL or not CONFIG_SQL.MySQL then
		return false
	end

	local config = CONFIG_SQL.MySQL
	return config.host ~= "" and 
		   config.username ~= "" and 
		   config.database ~= "" and
		   config.port ~= ""
end

function gInitializeMySQL()
	if not isValidMySQLConfig() then
		GPYMOUSSS.SQL.usingSQLite = true
		sql.Query("BEGIN TRANSACTION")

		gSQLDebugPrint("Connect", "No MySQL configuration found, using SQLite", {
			status = "info",
			query = "BEGIN TRANSACTION",
			data = {
				reason = "Missing or incomplete MySQL configuration",
				fallback = "SQLite"
			}
		})

		timer.Simple(0.1, function()
			hook.Run("gCreateTableSQL")
		end)

		return true
	end

	gSQLDebugPrint("Connect", "Attempting MySQL connection", {
		status = "info",
		query = "MySQL Connection Attempt",
		data = {
			host = CONFIG_SQL.MySQL.host,
			database = CONFIG_SQL.MySQL.database,
			port = CONFIG_SQL.MySQL.port,
			username = CONFIG_SQL.MySQL.username ~= "" and "configured" or "empty"
		}
	})

	GPYMOUSSS.SQL.db = mysqloo.connect(
		CONFIG_SQL.MySQL.host,
		CONFIG_SQL.MySQL.username,
		CONFIG_SQL.MySQL.password,
		CONFIG_SQL.MySQL.database,
		CONFIG_SQL.MySQL.port,
		CONFIG_SQL.MySQL.socket
	)

	GPYMOUSSS.SQL.db.onConnected = function()
		GPYMOUSSS.SQL.usingSQLite = false

		gSQLDebugPrint("Connect", "Successfully connected to MySQL", {
			status = "success",
			query = "MySQL Connection",
			data = {
				host = CONFIG_SQL.MySQL.host,
				database = CONFIG_SQL.MySQL.database,
				port = CONFIG_SQL.MySQL.port,
				connection_time = os.date("%H:%M:%S")
			}
		})

		hook.Run("gCreateTableSQL")
	end

	GPYMOUSSS.SQL.db.onConnectionFailed = function(db, err)
		GPYMOUSSS.SQL.usingSQLite = true
		sql.Query("BEGIN TRANSACTION")

		local errorType = "Connection Failed"
		if string.find(string.lower(err), "access denied") then
			errorType = "Authentication Failed"
		elseif string.find(string.lower(err), "unknown database") then
			errorType = "Database Not Found"
		elseif string.find(string.lower(err), "can't connect") then
			errorType = "Server Unreachable"
		end

		gSQLDebugPrint("Connect", "MySQL connection failed, fallback to SQLite", {
			status = "warning",
			query = "MySQL Connection",
			error = err,
			data = {
				host = CONFIG_SQL.MySQL.host,
				database = CONFIG_SQL.MySQL.database,
				port = CONFIG_SQL.MySQL.port,
				error_type = errorType,
				fallback = "SQLite",
				fallback_reason = "MySQL unavailable"
			}
		})

		timer.Simple(0.1, function()
			hook.Run("gCreateTableSQL")
		end)
	end

	GPYMOUSSS.SQL.db:connect()

	timer.Simple(5, function()
		if GPYMOUSSS.SQL.db and GPYMOUSSS.SQL.db:status() ~= mysqloo.DATABASE_CONNECTED then
			GPYMOUSSS.SQL.usingSQLite = true
			sql.Query("BEGIN TRANSACTION")

			gSQLDebugPrint("Connect", "MySQL connection timeout, fallback to SQLite", {
				status = "warning",
				query = "BEGIN TRANSACTION",
				data = {
					timeout_duration = "5 seconds",
					final_status = GPYMOUSSS.SQL.db:status(),
					fallback = "SQLite"
				}
			})

			timer.Simple(0.1, function()
				hook.Run("gCreateTableSQL")
			end)
		end
	end)

	return true
end