local CONFIG_SQL = {
	MySQL = {
		host = "",
		username = "",
		password = "",
		database = "",
		port = ""
	}
}

function gInitializeMySQL()
	if not CONFIG_SQL then
		GPYMOUSSS.SQL.usingSQLite = true
		sql.Query("BEGIN TRANSACTION")

		gSQLDebugPrint("Connect", "Using SQLite (CONFIG_SQL not found)", {
			status = "warning",
			query = "BEGIN TRANSACTION"
		})

		return true
	end

	GPYMOUSSS.SQL.db = mysqloo.connect(
		CONFIG_SQL.MySQL.host,
		CONFIG_SQL.MySQL.username,
		CONFIG_SQL.MySQL.password,
		CONFIG_SQL.MySQL.database,
		CONFIG_SQL.MySQL.port
	)

	GPYMOUSSS.SQL.db.onConnected = function()
		GPYMOUSSS.SQL.usingSQLite = false

		gSQLDebugPrint("Connect", "Connected to MySQL", {
			status = "success",
			query = "MySQL Connection",
			data = {
				host = CONFIG_SQL.MySQL.host,
				database = CONFIG_SQL.MySQL.database,
				port = CONFIG_SQL.MySQL.port
			}
		})

		hook.Run("gCreateTableSQL")
	end

	GPYMOUSSS.SQL.db.onConnectionFailed = function(db, err)
		GPYMOUSSS.SQL.usingSQLite = true
		sql.Query("BEGIN TRANSACTION")

		gSQLDebugPrint("Connect", "Failed to connect to MySQL, fallback to SQLite", {
			status = "error",
			query = "MySQL Connection",
			error = err,
			data = {
				host = CONFIG_SQL.MySQL.host,
				database = CONFIG_SQL.MySQL.database,
				port = CONFIG_SQL.MySQL.port
			}
		})

		hook.Run("gCreateTableSQL")
	end

	GPYMOUSSS.SQL.db:connect()

	timer.Simple(0.1, function()
		if not GPYMOUSSS.SQL.db:status() == mysqloo.DATABASE_CONNECTED then
			GPYMOUSSS.SQL.usingSQLite = true
			sql.Query("BEGIN TRANSACTION")
			
			gSQLDebugPrint("Connect", "MySQL connection timeout, fallback to SQLite", {
				status = "warning",
				query = "BEGIN TRANSACTION"
			})
		end
	end)

	return true
end