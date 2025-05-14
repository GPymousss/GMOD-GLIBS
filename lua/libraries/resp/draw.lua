local tex_corner8 = surface.GetTextureID("gui/corner8")
local tex_corner16 = surface.GetTextureID("gui/corner16")
local tex_corner32 = surface.GetTextureID("gui/corner32")
local tex_corner64 = surface.GetTextureID("gui/corner64")
local tex_corner512 = surface.GetTextureID("gui/corner512")

function gRoundedBox(bordersize, x, y, w, h, color)
	return gRoundedBoxEx(bordersize, x, y, w, h, color, true, true, true, true)
end

function gRoundedBoxEx(bordersize, x, y, w, h, color, tl, tr, bl, br)
	surface.SetDrawColor(color.r, color.g, color.b, color.a)

	local posX = gRespX(x)
	local posY = gRespY(y)
	local width = gRespX(w)
	local height = gRespY(h)
	local respBorder = gRespX(bordersize)

	if (respBorder <= 0) then
		surface.DrawRect(posX, posY, width, height)
		return
	end

	respBorder = math.min(respBorder, math.floor(width / 2), math.floor(height / 2))

	surface.DrawRect(posX + respBorder, posY, width - respBorder * 2, height)
	surface.DrawRect(posX, posY + respBorder, respBorder, height - respBorder * 2)
	surface.DrawRect(posX + width - respBorder, posY + respBorder, respBorder, height - respBorder * 2)

	local tex = tex_corner8
	if (respBorder > 8) then tex = tex_corner16 end
	if (respBorder > 16) then tex = tex_corner32 end
	if (respBorder > 32) then tex = tex_corner64 end
	if (respBorder > 64) then tex = tex_corner512 end

	surface.SetTexture(tex)

	if (tl) then
		surface.DrawTexturedRectUV(posX, posY, respBorder, respBorder, 0, 0, 1, 1)
	else
		surface.DrawRect(posX, posY, respBorder, respBorder)
	end

	if (tr) then
		surface.DrawTexturedRectUV(posX + width - respBorder, posY, respBorder, respBorder, 1, 0, 0, 1)
	else
		surface.DrawRect(posX + width - respBorder, posY, respBorder, respBorder)
	end

	if (bl) then
		surface.DrawTexturedRectUV(posX, posY + height - respBorder, respBorder, respBorder, 0, 1, 1, 0)
	else
		surface.DrawRect(posX, posY + height - respBorder, respBorder, respBorder)
	end

	if (br) then
		surface.DrawTexturedRectUV(posX + width - respBorder, posY + height - respBorder, respBorder, respBorder, 1, 1, 0, 0)
	else
		surface.DrawRect(posX + width - respBorder, posY + height - respBorder, respBorder, respBorder)
	end
end