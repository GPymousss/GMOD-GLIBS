function gCloseMySQL()
	if GPYMOUSSS.SQL.usingSQLite then
		sql.Query("COMMIT")
		return
	end

	if GPYMOUSSS.SQL.db then
		GPYMOUSSS.SQL.db:disconnect()
	end
end