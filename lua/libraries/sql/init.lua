require("mysqloo")

local function PrintHeader()
	local headerColor = Color(255, 20, 147)
	local accentColor = Color(0, 255, 255)
	local shadowColor = Color(100, 100, 100)
	local successColor = Color(46, 204, 113)

	MsgC(headerColor, "\n")
	MsgC(headerColor, "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n")
	MsgC(headerColor, "                                                                                  \n")
	MsgC(headerColor, "  ██████╗ ██████╗ ██╗   ██╗███╗   ███╗ ██████╗ ██╗   ██╗███████╗███████╗███████╗  \n")
	MsgC(headerColor, " ██╔════╝ ██╔══██╗╚██╗ ██╔╝████╗ ████║██╔═══██╗██║   ██║██╔════╝██╔════╝██╔════╝  \n")
	MsgC(headerColor, " ██║  ███╗██████╔╝ ╚████╔╝ ██╔████╔██║██║   ██║██║   ██║███████╗███████╗███████╗  \n")
	MsgC(headerColor, " ██║   ██║██╔═══╝   ╚██╔╝  ██║╚██╔╝██║██║   ██║██║   ██║╚════██║╚════██║╚════██║  \n")
	MsgC(headerColor, " ╚██████╔╝██║        ██║   ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝███████║███████║███████║  \n")
	MsgC(headerColor, "  ╚═════╝ ╚═╝        ╚═╝   ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚══════╝  \n")
	MsgC(accentColor, "                             Advanced SQL Library System                          \n")
	MsgC(shadowColor, "                              Created by GPymousss © 2025                         \n")
	MsgC(successColor,"                                   System Loading...                              \n")
	MsgC(headerColor, "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n\n")
end

GPYMOUSSS = GPYMOUSSS or {}
GPYMOUSSS.SQL = GPYMOUSSS.SQL or {}

GPYMOUSSS.SQL.COLORS = {
	SUCCESS = Color(46, 204, 113),
	ERROR = Color(231, 76, 60),
	WARNING = Color(241, 196, 15),
	INFO = Color(52, 152, 219),

	BRIGHT_GREEN = Color(0, 255, 127),
	BRIGHT_RED = Color(255, 69, 0),
	BRIGHT_BLUE = Color(30, 144, 255),
	BRIGHT_ORANGE = Color(255, 165, 0),
	BRIGHT_PURPLE = Color(138, 43, 226),
	BRIGHT_CYAN = Color(0, 255, 255),

	NEON_GREEN = Color(57, 255, 20),
	NEON_PINK = Color(255, 20, 147),
	NEON_BLUE = Color(0, 191, 255),
	NEON_YELLOW = Color(255, 255, 0),
	NEON_CYAN = Color(0, 255, 255),

	DARK_GREEN = Color(34, 139, 34),
	DARK_RED = Color(139, 0, 0),
	DARK_BLUE = Color(0, 0, 139),
	DARK_ORANGE = Color(255, 140, 0),

	PASTEL_PINK = Color(255, 182, 193),
	PASTEL_BLUE = Color(173, 216, 230),
	PASTEL_GREEN = Color(152, 251, 152),
	PASTEL_PURPLE = Color(221, 160, 221),

	GRADIENT_START = Color(255, 0, 150),
	GRADIENT_MID = Color(150, 0, 255),
	GRADIENT_END = Color(0, 150, 255),

	HIGHLIGHT = Color(255, 255, 255),
	SHADOW = Color(100, 100, 100),
	ACCENT = Color(255, 215, 0),
	BORDER = Color(169, 169, 169)
}

GPYMOUSSS.SQL.db = nil
GPYMOUSSS.SQL.usingSQLite = false

local function CreateGradientColor(startColor, endColor, progress)
	return Color(
		Lerp(progress, startColor.r, endColor.r),
		Lerp(progress, startColor.g, endColor.g),
		Lerp(progress, startColor.b, endColor.b)
	)
end

local function GetTableColorByOperation(operation)
	local colors = {
		Connect = GPYMOUSSS.SQL.COLORS.NEON_BLUE,
		Close = GPYMOUSSS.SQL.COLORS.DARK_RED,
		CreateTable = GPYMOUSSS.SQL.COLORS.BRIGHT_PURPLE,
		AddColumn = GPYMOUSSS.SQL.COLORS.BRIGHT_ORANGE,
		DropColumn = GPYMOUSSS.SQL.COLORS.BRIGHT_RED,
		Insert = GPYMOUSSS.SQL.COLORS.NEON_GREEN,
		Select = GPYMOUSSS.SQL.COLORS.BRIGHT_CYAN,
		Update = GPYMOUSSS.SQL.COLORS.NEON_YELLOW,
		Delete = GPYMOUSSS.SQL.COLORS.BRIGHT_RED,
		Query = GPYMOUSSS.SQL.COLORS.PASTEL_BLUE,
		Logs = GPYMOUSSS.SQL.COLORS.PASTEL_PURPLE,
		Explain = GPYMOUSSS.SQL.COLORS.PASTEL_PINK,
		Stats = GPYMOUSSS.SQL.COLORS.ACCENT,
		Config = GPYMOUSSS.SQL.COLORS.DARK_ORANGE
	}
	return colors[operation] or GPYMOUSSS.SQL.COLORS.INFO
end

local function GetStatusColor(status)
	local colors = {
		success = GPYMOUSSS.SQL.COLORS.BRIGHT_GREEN,
		error = GPYMOUSSS.SQL.COLORS.NEON_PINK,
		warning = GPYMOUSSS.SQL.COLORS.NEON_YELLOW,
		info = GPYMOUSSS.SQL.COLORS.NEON_BLUE
	}
	return colors[status] or GPYMOUSSS.SQL.COLORS.INFO
end

local function GetExecutionTimeColor(time)
	if time < 0.01 then
		return GPYMOUSSS.SQL.COLORS.BRIGHT_GREEN
	elseif time < 0.1 then
		return GPYMOUSSS.SQL.COLORS.NEON_GREEN
	elseif time < 0.5 then
		return GPYMOUSSS.SQL.COLORS.NEON_YELLOW
	elseif time < 1.0 then
		return GPYMOUSSS.SQL.COLORS.BRIGHT_ORANGE
	elseif time < 3.0 then
		return GPYMOUSSS.SQL.COLORS.BRIGHT_RED
	else
		return GPYMOUSSS.SQL.COLORS.NEON_PINK
	end
end

local function FormatTable(tbl, indent, maxDepth)
	if not tbl then return "nil" end
	if not indent then indent = 0 end
	if not maxDepth then maxDepth = 3 end
	if indent > maxDepth then return "{...}" end

	local result = {}
	local indentStr = string.rep("  ", indent)

	table.insert(result, "{")

	for k, v in pairs(tbl) do
		local valueStr
		if type(v) == "table" then
			valueStr = FormatTable(v, indent + 1, maxDepth)
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

function gFormatExecutionTime(seconds)
	if seconds < 0.001 then
		return string.format("%.3f µs", seconds * 1000000)
	elseif seconds < 1 then
		return string.format("%.2f ms", seconds * 1000)
	else
		return string.format("%.3f s", seconds)
	end
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

	MsgC(GPYMOUSSS.SQL.COLORS.ACCENT, "=== GPYMOUSSS SQL Debug Status ===\n")
	MsgC(GPYMOUSSS.SQL.COLORS.NEON_BLUE, "Debug Enabled: ")
	MsgC(status.Enabled and GPYMOUSSS.SQL.COLORS.BRIGHT_GREEN or GPYMOUSSS.SQL.COLORS.BRIGHT_RED, tostring(status.Enabled) .. "\n")
	MsgC(GPYMOUSSS.SQL.COLORS.NEON_BLUE, "Verbose Mode: ")
	MsgC(status.Verbose and GPYMOUSSS.SQL.COLORS.BRIGHT_GREEN or GPYMOUSSS.SQL.COLORS.BRIGHT_RED, tostring(status.Verbose) .. "\n")
	MsgC(GPYMOUSSS.SQL.COLORS.NEON_BLUE, "SQL Mode: ")
	MsgC(status.SQLMode == "MySQL" and GPYMOUSSS.SQL.COLORS.BRIGHT_PURPLE or GPYMOUSSS.SQL.COLORS.PASTEL_BLUE, status.SQLMode .. "\n")

	if status.SQLMode == "MySQL" then
		MsgC(GPYMOUSSS.SQL.COLORS.NEON_BLUE, "MySQL Connection: ")
		MsgC(status.MySQLConnected and GPYMOUSSS.SQL.COLORS.BRIGHT_GREEN or GPYMOUSSS.SQL.COLORS.BRIGHT_RED, 
			(status.MySQLConnected and "Connected" or "Disconnected") .. "\n")
	end

	MsgC(GPYMOUSSS.SQL.COLORS.NEON_YELLOW, "\nOperation Filters:\n")
	for op, enabled in pairs(status.Config) do
		MsgC(GPYMOUSSS.SQL.COLORS.PASTEL_PINK, "  " .. op .. ": ")
		MsgC(enabled and GPYMOUSSS.SQL.COLORS.BRIGHT_GREEN or GPYMOUSSS.SQL.COLORS.BRIGHT_RED, tostring(enabled) .. "\n")
	end

	MsgC(GPYMOUSSS.SQL.COLORS.ACCENT, "================================\n")

	return status
end

function gSQLDebugPrint(module, action, details)
	if not GPYMOUSSS.Debug.Enabled then return end

	if GPYMOUSSS.Debug.Config and GPYMOUSSS.Debug.Config[module] == false then 
		return 
	end

	local statusColor = GetStatusColor(details.status)
	local moduleColor = GetTableColorByOperation(module)
	local timeColor = GPYMOUSSS.SQL.COLORS.PASTEL_BLUE

	if details.executionTime then
		timeColor = GetExecutionTimeColor(details.executionTime)
	end

	local timeStr = os.date("%H:%M:%S", os.time())

	MsgC(GPYMOUSSS.SQL.COLORS.SHADOW, "[")
	MsgC(GPYMOUSSS.SQL.COLORS.PASTEL_GREEN, timeStr)
	MsgC(GPYMOUSSS.SQL.COLORS.SHADOW, "] [")
	MsgC(GPYMOUSSS.SQL.COLORS.ACCENT, "GPYMOUSSS.SQL")
	MsgC(GPYMOUSSS.SQL.COLORS.SHADOW, "] [")
	MsgC(moduleColor, module)
	MsgC(GPYMOUSSS.SQL.COLORS.SHADOW, "] ")
	MsgC(GPYMOUSSS.SQL.COLORS.HIGHLIGHT, action .. "\n")

	if details.query then
		local queryLines = string.Explode("\n", details.query)
		for i, line in ipairs(queryLines) do
			local progress = (i - 1) / math.max(1, #queryLines - 1)
			local gradientColor = CreateGradientColor(
				GPYMOUSSS.SQL.COLORS.GRADIENT_START, 
				GPYMOUSSS.SQL.COLORS.GRADIENT_END, 
				progress
			)

			if i == 1 then
				MsgC(GPYMOUSSS.SQL.COLORS.NEON_CYAN, "Query: ")
			else
				MsgC(GPYMOUSSS.SQL.COLORS.SHADOW, "       ")
			end
			MsgC(gradientColor, line .. "\n")
		end
	else
		MsgC(GPYMOUSSS.SQL.COLORS.NEON_CYAN, "Query: ")
		MsgC(GPYMOUSSS.SQL.COLORS.SHADOW, "N/A\n")
	end

	if details.status == "error" and details.error then
		MsgC(GPYMOUSSS.SQL.COLORS.NEON_PINK, "Error: ")
		MsgC(GPYMOUSSS.SQL.COLORS.BRIGHT_RED, details.error .. "\n")
	end

	if details.executionTime then
		MsgC(GPYMOUSSS.SQL.COLORS.PASTEL_PURPLE, "Execution Time: ")
		MsgC(timeColor, gFormatExecutionTime(details.executionTime) .. "\n")
	end

	if details.data and GPYMOUSSS.Debug.Verbose then
		MsgC(GPYMOUSSS.SQL.COLORS.PASTEL_PINK, "Data:\n")

		local dataLines = string.Explode("\n", FormatTable(details.data))
		for i, line in ipairs(dataLines) do
			local progress = (i - 1) / math.max(1, #dataLines - 1)
			local gradientColor = CreateGradientColor(
				GPYMOUSSS.SQL.COLORS.PASTEL_BLUE, 
				GPYMOUSSS.SQL.COLORS.PASTEL_PURPLE, 
				progress
			)
			MsgC(gradientColor, line .. "\n")
		end
	end

	local separator = ""
	for i = 1, 50 do
		if i % 2 == 1 then
			separator = separator .. "-"
		else
			separator = separator .. "="
		end
	end

	for i = 1, string.len(separator) do
		local progress = (i - 1) / (string.len(separator) - 1)
		local rainbowColor = CreateGradientColor(
			GPYMOUSSS.SQL.COLORS.NEON_PINK, 
			GPYMOUSSS.SQL.COLORS.NEON_BLUE, 
			math.sin(progress * math.pi * 4) * 0.5 + 0.5
		)
		MsgC(rainbowColor, string.sub(separator, i, i))
	end
	MsgC(Color(255, 255, 255), "\n")
end

function gSQLRainbowPrint(text)
	for i = 1, string.len(text) do
		local progress = (i - 1) / (string.len(text) - 1)
		local hue = (progress * 360 + CurTime() * 50) % 360
		local color = HSVToColor(hue, 1, 1)
		MsgC(color, string.sub(text, i, i))
	end
	MsgC(Color(255, 255, 255), "\n")
end

function gSQLMatrixPrint(text)
	local matrixChars = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	local matrixColors = {
		Color(0, 255, 0),
		Color(0, 200, 0),
		Color(0, 150, 0),
		Color(0, 100, 0)
	}

	for i = 1, 30 do
		local char = matrixChars[math.random(1, #matrixChars)]
		local color = matrixColors[math.random(1, #matrixColors)]
		MsgC(color, char)
	end
	MsgC(Color(0, 255, 0), " >>> " .. text .. "\n")
end

function gSQLBorderPrint(text, style)
	style = style or "double"

	local styles = {
		simple = {
			top = "-",
			side = "|",
			corner = "+"
		},
		double = {
			top = "=",
			side = "#",
			corner = "#"
		},
		fancy = {
			top = "~",
			side = ":",
			corner = "*"
		},
		arrows = {
			top = ">",
			side = "v",
			corner = "^"
		}
	}

	local currentStyle = styles[style] or styles.simple
	local width = string.len(text) + 4

	local topBorder = currentStyle.corner .. string.rep(currentStyle.top, width - 2) .. currentStyle.corner
	local sideBorder = currentStyle.side .. " " .. text .. " " .. currentStyle.side
	local bottomBorder = currentStyle.corner .. string.rep(currentStyle.top, width - 2) .. currentStyle.corner

	MsgC(GPYMOUSSS.SQL.COLORS.ACCENT, topBorder .. "\n")
	MsgC(GPYMOUSSS.SQL.COLORS.BRIGHT_GREEN, sideBorder .. "\n")
	MsgC(GPYMOUSSS.SQL.COLORS.ACCENT, bottomBorder .. "\n")
end

PrintHeader()
MsgC(GPYMOUSSS.SQL.COLORS.SUCCESS, "[GPYMOUSSS.SQL] ")
MsgC(GPYMOUSSS.SQL.COLORS.HIGHLIGHT, "Initializing MySQL connection...\n")
gInitializeMySQL()
MsgC(GPYMOUSSS.SQL.COLORS.SUCCESS, "[GPYMOUSSS.SQL] ")
MsgC(GPYMOUSSS.SQL.COLORS.BRIGHT_GREEN, "System fully loaded and ready!\n")
gSQLRainbowPrint("GPymousss SQL Library - Ready to serve!")
MsgC(GPYMOUSSS.SQL.COLORS.NEON_CYAN, "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n")