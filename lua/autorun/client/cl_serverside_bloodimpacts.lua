local hblood = GetConVar("violence_hblood"):GetBool()

cvars.AddChangeCallback("violence_hblood", function(_,_, new)
	hblood = tonumber(new) == 1
end, "serverside_bloodimpacts_hblood")

local ablood = GetConVar("violence_ablood"):GetBool()

cvars.AddChangeCallback("violence_ablood", function(_,_, new)
	ablood = tonumber(new) == 1
end, "serverside_bloodimpacts_ablood")

local maxplayers_bits = math.ceil(math.log(game.MaxPlayers()) / math.log(2))

local vec = Vector()
local traceres = {}
local tracedata = {
	endpos = vec,
	mask = bit.band(MASK_SOLID_BRUSHONLY, bit.bnot(CONTENTS_GRATE)),
	collisiongroup = COLLISION_GROUP_NONE,
	ignoreworld = false,
	output = traceres,
}

net.Receive("serverside_bloodimpacts", function()
	local victim = Entity(net.ReadUInt(maxplayers_bits))

	if not IsValid(victim) then
		victim = nil
	end

	local blood = net.ReadUInt(3)

	if blood == BLOOD_COLOR_RED then
		if not hblood then
			return
		end
	elseif not ablood then
		return
	end

	local dir = net.ReadNormal()

	local hitpos = net.ReadVector()

	local dmg = net.ReadUInt(2)

	local dist = net.ReadBool() and 384 or 172

	local eff = EffectData()
	eff:SetScale(1)
	eff:SetColor(blood)
	eff:SetOrigin(hitpos)
	eff:SetNormal(dir)

	util.Effect("BloodImpact", eff)

	if blood == BLOOD_COLOR_MECH then
		return
	end

	local decal = blood == 0 and "Blood" or "YellowBlood"

	local vec, tracedata, traceres = vec, tracedata, traceres

	tracedata.start = hitpos
	tracedata.filter = victim

	local noise, count

	if dmg == 0 then
		noise, count = 0.1, 1
	elseif dmg == 1 then
		noise, count = 0.2, 2
	else
		noise, count = 0.3, 4
	end

	::loop::

	for i = 1, 3 do
		vec[i] = hitpos[i] + (dir[i] + math.Rand(-noise, noise)) * dist
	end

	util.TraceLine(tracedata)

	if traceres.Hit then
		util.Decal(decal, hitpos, vec, victim)
	end

	if count > 1 then
		count = count - 1

		goto loop
	end
end)

hook.Add("ScalePlayerDamage", "serverside_bloodimpacts_ScalePlayerDamage", function()
	return true
end)
