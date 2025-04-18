local meta = FindMetaTable("Panel")

function meta:gSetX(x)
	self:SetPos(gRespX(x), self:GetY())
end

function meta:gSetY(y)
	self:SetPos(self:GetX(), gRespY(y))
end

function meta:gSetPos(x, y)
	self:SetPos(gRespX(x), gRespY(y))
end

function meta:gSetHeight(h)
	self:SetSize(self:GetWide(), gRespY(h))
end

function meta:gSetWidth(w)
	self:SetSize(gRespX(w), self:GetTall())
end

function meta:gSetSize(w, h)
	self:SetSize(gRespX(w), gRespY(h))
end

function meta:gSetMinWidth(w)
	self:SetMinWidth(gRespX(w))
end

function meta:gSetMinHeight(h)
	self:SetMinHeight(gRespY(h))
end

function meta:gSetMaxWidth(w)
	self:SetMaxWidth(gRespX(w))
end

function meta:gSetMaxHeight(h)
	self:SetMaxHeight(gRespY(h))
end

function meta:gSetSquareSize(size)
	self:SetSize(gRespX(size), gRespY(size))
end

function meta:gCenterHorizontal(offset)
	offset = offset or 0
	local parent = self:GetParent()
	local x = (parent:GetWide() - self:GetWide()) / 2
	self:SetX(x + gRespX(offset))
end

function meta:gCenterVertical(offset)
	offset = offset or 0
	local parent = self:GetParent()
	local y = (parent:GetTall() - self:GetTall()) / 2
	self:SetY(y + gRespY(offset))
end

function meta:gCenter(xOffset, yOffset)
	self:gCenterHorizontal(xOffset)
	self:gCenterVertical(yOffset)
end

function meta:gDockMargin(left, top, right, bottom)
	self:DockMargin(
		gRespX(left), 
		gRespY(top), 
		gRespX(right), 
		gRespY(bottom)
	)
end

function meta:gDockPadding(left, top, right, bottom)
	self:DockPadding(
		gRespX(left), 
		gRespY(top), 
		gRespX(right), 
		gRespY(bottom)
	)
end

function meta:gSetMargin(margin)
	self:gDockMargin(margin, margin, margin, margin)
end

function meta:gSetPadding(padding)
	self:gDockPadding(padding, padding, padding, padding)
end