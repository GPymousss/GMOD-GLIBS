local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080
local BASE_RATIO = 16/9
local scaleX, scaleY, aspectRatio

local function UpdateScaleFactors()
	local screenW = ScrW()
	local screenH = ScrH()

	aspectRatio = screenW / screenH
	scaleY = screenH / BASE_HEIGHT

	if math.abs(aspectRatio - BASE_RATIO) < 0.01 then
		scaleX = screenW / BASE_WIDTH
	else
		scaleX = scaleY * (aspectRatio / BASE_RATIO)
	end
end

function gRespX(value)
	return math.Round(value * scaleX)
end

function gRespY(value)
	return math.Round(value * scaleY)
end

function gRespFont(size)
	return math.Round(size * math.min(scaleX, scaleY))
end

function gCreateRespFont(name, fontFamily, baseSize, weight, antialias, shadow, outline)
	local fontData = {
		font = fontFamily,
		size = gRespFont(baseSize),
		weight = weight or 500,
		antialias = antialias or true,
		shadow = shadow or false,
		outline = outline or false
	}
	surface.CreateFont(name, fontData)
end

local function Initialize()
	UpdateScaleFactors()
	for i = 1, 100 do
		gCreateRespFont("Inter:" .. i, "Lora", i, 400)
	end
end

hook.Add("Initialize", "InitializeResponsiveSystem", Initialize)

hook.Add("OnScreenSizeChanged", "UpdateResponsiveFactors", function()
	Initialize()
end)

Initialize()