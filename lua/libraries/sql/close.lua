function gCloseMySQL()
	if GPYMOUSSS.SQL.usingSQLite then
		sql.Query("COMMIT")

		gSQLDebugPrint("Close", "Committed SQLite transaction", {
			status = "success",
			query = "COMMIT"
		})

		return
	end

	if GPYMOUSSS.SQL.db then
		GPYMOUSSS.SQL.db:disconnect()

		gSQLDebugPrint("Close", "Disconnected from MySQL", {
			status = "success",
			query = "MySQL Disconnect"
		})
	end
end