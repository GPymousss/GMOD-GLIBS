GPYMOUSSS = GPYMOUSSS or {}
GPYMOUSSS.GLibs = false

if SERVER then
	-- Module responsive
	AddCSLuaFile("libraries/resp/responsive.lua")
	AddCSLuaFile("libraries/resp/panel.lua")
	AddCSLuaFile("libraries/resp/materials.lua")
	AddCSLuaFile("libraries/resp/anims.lua")

	-- Module Debug
	AddCSLuaFile("libraries/debug/config.lua")
	AddCSLuaFile("libraries/debug/utils.lua")
	include("libraries/debug/config.lua")
	include("libraries/debug/utils.lua")

	-- Module MySQLoo
	include("libraries/sql/query_handler.lua")
	include("libraries/sql/connect.lua")
	include("libraries/sql/create_table.lua")
	include("libraries/sql/add_column.lua")
	include("libraries/sql/drop_column.lua")
	include("libraries/sql/insert.lua")
	include("libraries/sql/select.lua")
	include("libraries/sql/update.lua")
	include("libraries/sql/delete.lua")
	include("libraries/sql/close.lua")
	include("libraries/sql/init.lua")
	include("libraries/log/logs.lua")

	-- Module Anims
	AddCSLuaFile("libraries/anims/anims.lua")
	include("libraries/anims/anims.lua")
end

if CLIENT then
	-- Module responsive
	include("libraries/resp/responsive.lua")
	include("libraries/resp/panel.lua")
	include("libraries/resp/materials.lua")
	include("libraries/resp/anims.lua")

	-- Module Debug
	include("libraries/debug/config.lua")
	include("libraries/debug/utils.lua")

	-- Module Anims
	include("libraries/anims/anims.lua")
end

GPYMOUSSS.GLibs = true