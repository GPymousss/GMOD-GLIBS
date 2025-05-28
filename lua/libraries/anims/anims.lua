if SERVER then
	local Player = FindMetaTable("Player")

	util.AddNetworkString( "gAnims" )

	function Player:SetAnim( seq )
		net.Start("gAnims")
			net.WriteEntity( self )
			net.WriteString( seq )
		net.Broadcast()
	end
end

if CLIENT then
	net.Receive("gAnims", function()
		local ply = net.ReadEntity()
		local seq = net.ReadString()

		if IsValid(ply) then
			ply:AddVCDSequenceToGestureSlot(6, ply:LookupSequence(seq), 0, true)
		end
	end)
end