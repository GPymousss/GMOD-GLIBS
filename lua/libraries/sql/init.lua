require("mysqloo")

GPYMOUSSS.SQL = GPYMOUSSS.SQL or {}
GPYMOUSSS.SQL.COLORS = {
	SUCCESS = Color(46,204,113),
	ERROR = Color(231,76,60),
	WARNING = Color(241,196,15),
	INFO = Color(52,152,219)
}

GPYMOUSSS.SQL.db = nil
GPYMOUSSS.SQL.usingSQLite = false

local function FormatTable(tbl, indent)
	if not tbl then return "nil" end
	if not indent then indent = 0 end

	local result = {}
	local indentStr = string.rep("  ", indent)

	table.insert(result, "{")

	for k, v in pairs(tbl) do
		local valueStr
		if type(v) == "table" then
			valueStr = FormatTable(v, indent + 1)
		elseif type(v) == "string" then
			valueStr = '"' .. v .. '"'
		else
			valueStr = tostring(v)
		end

		table.insert(result, indentStr .. "  [" .. tostring(k) .. "] = " .. valueStr .. ",")
	end

	table.insert(result, indentStr .. "}")

	return table.concat(result, "\n")
end

function gDebugSQL()
	local status = {}

	status.Enabled = GPYMOUSSS.Debug.Enabled
	status.Verbose = GPYMOUSSS.Debug.Verbose
	status.Config = GPYMOUSSS.Debug.Config
	status.SQLMode = GPYMOUSSS.SQL.usingSQLite and "SQLite" or "MySQL"

	if not GPYMOUSSS.SQL.usingSQLite and GPYMOUSSS.SQL.db then
		status.MySQLStatus = GPYMOUSSS.SQL.db:status()
		status.MySQLConnected = (status.MySQLStatus == mysqloo.DATABASE_CONNECTED)
	end

	print("=== GPYMOUSSS SQL Debug Status ===")
	print("Debug Enabled: " .. tostring(status.Enabled))
	print("Verbose Mode: " .. tostring(status.Verbose))
	print("SQL Mode: " .. status.SQLMode)

	if status.SQLMode == "MySQL" then
		print("MySQL Connection: " .. (status.MySQLConnected and "Connected" or "Disconnected"))
	end

	print("\nOperation Filters:")
	for op, enabled in pairs(status.Config) do
		print("  " .. op .. ": " .. tostring(enabled))
	end

	print("================================")

	return status
end

function gSQLDebugPrint(module, action, details)
	if not GPYMOUSSS.Debug.Enabled then return end
	
	if GPYMOUSSS.Debug.Config and GPYMOUSSS.Debug.Config[module] == false then 
		return 
	end

	local color = GPYMOUSSS.SQL.COLORS.INFO
	if details.status == "success" then
		color = GPYMOUSSS.SQL.COLORS.SUCCESS
	elseif details.status == "error" then
		color = GPYMOUSSS.SQL.COLORS.ERROR
	elseif details.status == "warning" then
		color = GPYMOUSSS.SQL.COLORS.WARNING
	end

	local timeStr = os.date("%H:%M:%S", os.time())
	local prefix = "[" .. timeStr .. "] [GPYMOUSSS.SQL] [" .. module .. "] "

	print(prefix .. action)
	MsgC(color, "Query: " .. (details.query or "N/A") .. "\n")

	if details.status == "error" then
		MsgC(GPYMOUSSS.SQL.COLORS.ERROR, "Error: " .. (details.error or "Unknown error") .. "\n")
	end

	if details.data and GPYMOUSSS.Debug.Verbose then
		print("Data:")
		print(FormatTable(details.data))
	end

	print("--------------------------------------------------")
end

gInitializeMySQL()