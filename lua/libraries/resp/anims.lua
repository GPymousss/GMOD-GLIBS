local meta = FindMetaTable("Panel")

function meta:gMoveTo(x, y, duration, delay, ease, callback)
	self:MoveTo(
		gRespX(x),
		gRespY(y),
		duration or 0.3,
		delay or 0,
		ease or nil,
		callback or nil
	)
end

function meta:gMoveToX(x, duration, delay, ease, callback)
	self:MoveTo(
		gRespX(x),
		self:GetY(),
		duration or 0.3,
		delay or 0,
		ease or nil,
		callback or nil
	)
end

function meta:gMoveToY(y, duration, delay, ease, callback)
	self:MoveTo(
		self:GetX(),
		gRespY(y),
		duration or 0.3,
		delay or 0,
		ease or nil,
		callback or nil
	)
end

function meta:gSizeTo(w, h, duration, delay, ease, callback)
	self:SizeTo(
		gRespX(w),
		gRespY(h),
		duration or 0.3,
		delay or 0,
		ease or nil,
		callback or nil
	)
end

function meta:gSizeToW(w, duration, delay, ease, callback)
	self:SizeTo(
		gRespX(w),
		self:GetTall(),
		duration or 0.3,
		delay or 0,
		ease or nil,
		callback or nil
	)
end

function meta:gSizeToH(h, duration, delay, ease, callback)
	self:SizeTo(
		self:GetWide(),
		gRespY(h),
		duration or 0.3,
		delay or 0,
		ease or nil,
		callback or nil
	)
end

function meta:gCenterTo(duration, delay, ease, callback)
	local parent = self:GetParent()
	local x = (parent:GetWide() - self:GetWide()) / 2
	local y = (parent:GetTall() - self:GetTall()) / 2

	self:MoveTo(x, y, duration or 0.3, delay or 0, ease or nil, callback or nil)
end

function meta:gSizeToSquare(size, duration, delay, ease, callback)
	self:SizeTo(
		gRespX(size),
		gRespY(size),
		duration or 0.3,
		delay or 0,
		ease or nil,
		callback or nil
	)
end

function meta:gAnimateTo(x, y, w, h, duration, delay, ease, callback)
	local startTime = SysTime()
	local startX, startY = self:GetPos()
	local startW, startH = self:GetSize()
	local targetX, targetY = gRespX(x), gRespY(y)
	local targetW, targetH = gRespX(w), gRespY(h)
	duration = duration or 0.3
	delay = delay or 0
	ease = ease or nil

	self.Think = function(self)
		local time = SysTime() - startTime - delay
		if time < 0 then return end
		if time >= duration then
			self:SetPos(targetX, targetY)
			self:SetSize(targetW, targetH)
			self.Think = nil
			if callback then callback() end
			return
		end

		local fraction = time / duration
		if ease then
			fraction = ease(fraction)
		end

		local curX = Lerp(fraction, startX, targetX)
		local curY = Lerp(fraction, startY, targetY)
		local curW = Lerp(fraction, startW, targetW)
		local curH = Lerp(fraction, startH, targetH)

		self:SetPos(curX, curY)
		self:SetSize(curW, curH)
	end
end

function meta:gFadeIn(duration, delay, callback)
	self:SetAlpha(0)
		self:AlphaTo(
		255,
		duration or 0.3,
		delay or 0,
		callback or nil
	)
end

function meta:gFadeOut(duration, delay, callback)
	self:AlphaTo(
		0,
		duration or 0.3,
		delay or 0,
		callback or nil
	)
end

function meta:gAnimateSequence(animations)
	local currentDelay = 0

	for _, anim in ipairs(animations) do
		local duration = anim.duration or 0.3
		local delay = currentDelay + (anim.delay or 0)

		if anim.type == "move" then
			self:gMoveTo(anim.x, anim.y, duration, delay, anim.ease, anim.callback)
		elseif anim.type == "size" then
			self:gSizeTo(anim.w, anim.h, duration, delay, anim.ease, anim.callback)
		elseif anim.type == "fade" then
			self:AlphaTo(anim.alpha, duration, delay, anim.callback)
		end

		currentDelay = delay + duration
	end
end