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
	include("libraries/debug/sqlite.lua")
	include("libraries/debug/mysql.lua")

	-- Module SQLite
	include("libraries/sqlite/utils.lua")
	include("libraries/sqlite/create.lua")
	include("libraries/sqlite/insert.lua")
	include("libraries/sqlite/select.lua")
	include("libraries/sqlite/update.lua")
	include("libraries/sqlite/delete.lua")

	-- Module MySQL
	include("libraries/mysql/init.lua")
	include("libraries/mysql/utils.lua")
	include("libraries/mysql/connect.lua")
	include("libraries/mysql/create.lua")
	include("libraries/mysql/insert.lua")
	include("libraries/mysql/select.lua")
	include("libraries/mysql/update.lua")
	include("libraries/mysql/delete.lua")

	-- Module Anims
	AddCSLuaFile("libraries/anims/anims.lua")
	include("libraries/anims/anims.lua")
end

if CLIENT then
	-- Module Responsive
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