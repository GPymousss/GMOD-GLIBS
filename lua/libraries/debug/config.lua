GPYMOUSSS.Debug = GPYMOUSSS.Debug or {}

GPYMOUSSS.Debug.Enabled = true
GPYMOUSSS.Debug.Verbose = true

GPYMOUSSS.Debug.Config = {
	SQLite = true,
	MySQL = true,
	CreateTable = true,
	Insert = true,
	Select = true,
	Update = true,
	Delete = true,
	Connection = true,
	Logs = true
}

function gDisableSQLDebug(operationType)
	if operationType then
		GPYMOUSSS.Debug.Config[operationType] = false
	else
		GPYMOUSSS.Debug.Enabled = false
	end

	gSQLDebugPrint("Config", "Debug disabled", {
		status = "info",
		data = {
			operationType = operationType or "all"
		}
	})
end

function gEnableSQLDebug(operationType)
	if operationType then
		GPYMOUSSS.Debug.Config[operationType] = true
	else
		GPYMOUSSS.Debug.Enabled = true
	end

	gSQLDebugPrint("Config", "Debug enabled", {
		status = "info",
		data = {
			operationType = operationType or "all"
		}
	})
end

function gSetSQLDebugVerbose(enabled)
	GPYMOUSSS.Debug.Verbose = enabled

	gSQLDebugPrint("Config", "Verbose mode " .. (enabled and "enabled" or "disabled"), {
		status = "info"
	})
end

function gResetSQLDebug()
	GPYMOUSSS.Debug.Enabled = true
	GPYMOUSSS.Debug.Verbose = true

	GPYMOUSSS.Debug.Config = {
		SQLite = true,
		MySQL = true,
		CreateTable = true,
		Insert = true,
		Select = true,
		Update = true,
		Delete = true,
		Connection = true,
		Logs = true
	}

	gSQLDebugPrint("Config", "Debug configuration reset to defaults", {
		status = "info"
	})
end