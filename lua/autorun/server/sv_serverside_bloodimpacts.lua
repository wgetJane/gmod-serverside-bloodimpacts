if game.SinglePlayer() then
	return
end

util.AddNetworkString("serverside_bloodimpacts")

local maxplayers_bits = math.ceil(math.log(game.MaxPlayers()) / math.log(2))

local dmgtypes = bit.bor(DMG_CRUSH, DMG_BULLET, DMG_SLASH, DMG_BLAST, DMG_CLUB, DMG_AIRBOAT)

hook.Add("PlayerTraceAttack", "serverside_bloodimpacts_PlayerTraceAttack", function(victim, dmginfo, dir, trace)
	if not IsValid(victim) then
		return
	end

	local dmg = dmginfo:GetDamage()

	if not (dmg > 0 and dmginfo:IsDamageType(dmgtypes)) then
		return
	end

	local attacker = dmginfo:GetAttacker()

	if not (
		IsValid(attacker)
		and attacker:IsPlayer()
		and not attacker:IsBot()
		--and attacker:GetInfoNum("cl_predictweapons", 1) == 1
	) then
		return
	end

	local blood = victim:GetBloodColor()

	if blood == DONT_BLEED then
		return
	end

	net.Start("serverside_bloodimpacts")

	net.WriteUInt(victim:EntIndex(), maxplayers_bits)

	net.WriteUInt(blood, 3)

	net.WriteNormal(dir)

	net.WriteVector(trace.HitPos)

	net.WriteUInt(
		dmg < 10 and 0
		or dmg < 25 and 1
		or 2,
		2
	)

	net.WriteBool(dmginfo:IsDamageType(DMG_AIRBOAT))

	net.Send(attacker)
end)
