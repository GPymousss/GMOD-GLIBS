--local CONFIG_SQL = {
--	MySQL = {
--		host = "",
--		username = "",
--		password = "",
--		database = "",
--		port = "",
--		socket = ""
--	}
--}

function gInitializeMySQL()
	if not CONFIG_SQL then
		GPYMOUSSS.SQL.usingSQLite = true
		sql.Query("BEGIN TRANSACTION")
		return true
	end

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
	end

	GPYMOUSSS.SQL.db.onConnectionFailed = function()
		GPYMOUSSS.SQL.usingSQLite = true
		sql.Query("BEGIN TRANSACTION")
	end

	GPYMOUSSS.SQL.db:connect()

	timer.Simple(0.1, function()
		if not GPYMOUSSS.SQL.db:status() == mysqloo.DATABASE_CONNECTED then
			GPYMOUSSS.SQL.usingSQLite = true
			sql.Query("BEGIN TRANSACTION")
		end
	end)

	return true
end