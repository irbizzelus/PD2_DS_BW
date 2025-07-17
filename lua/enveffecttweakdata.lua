-- if fire field was requested by the flashbang firetrap, apply new stats. damage value is important for firemanager.lua
local DS_BW_orig_incendiary_fire = EnvEffectTweakData.incendiary_fire
function EnvEffectTweakData:incendiary_fire()
	local result = DS_BW_orig_incendiary_fire(self)
	
	if DS_BW and DS_BW.DS_difficultycheck and DS_BW._creating_fire_trap then
		result.burn_duration = 0
		result.damage = -0.69
		DS_BW._creating_fire_trap = nil
	end

	return result
end