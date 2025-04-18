function gMaterials(name, posx, posy, sizex, sizey, color)
	surface.SetMaterial(name)
	surface.SetDrawColor(color or color_white)
	surface.DrawTexturedRect(
		gRespX(posx) or 0,
		gRespY(posy) or 0,
		gRespX(sizex) or 0,
		gRespY(sizey) or 0
	)
end

function pMaterials(name, posx, posy, sizex, sizey, color)
	surface.SetMaterial(name)
	surface.SetDrawColor(color or color_white)
	surface.DrawTexturedRect(
		posx or 0,
		posy or 0,
		sizex or 0,
		sizey or 0
	)
end

function gMaterialsUV(name, posx, posy, sizex, sizey, color, u0, v0, u1, v1)
	surface.SetMaterial(name)
	surface.SetDrawColor(color or color_white)
	surface.DrawTexturedRectUV(
		gRespX(posx) or 0,
		gRespY(posy) or 0,
		gRespX(sizex) or 0,
		gRespY(sizey) or 0,
		u0 or 0,
		v0 or 0,
		u1 or 1,
		v1 or 1	
	)
end

function pMaterialsUV(name, posx, posy, sizex, sizey, color, u0, v0, u1, v1)
	surface.SetMaterial(name)
	surface.SetDrawColor(color or color_white)
	surface.DrawTexturedRectUV(
		posx or 0,
		posy or 0,
		sizex or 0,
		sizey or 0,
		u0 or 0,
		v0 or 0,
		u1 or 1,
		v1 or 1	
	)
end