-- remove ecm effects from most enemies (excluding cops and gangsters cuz they are not elite enough i guess) to add more pain for hacker players. sadly it also affects standard ecm, but what can you do
Hooks:PostHook(CharacterTweakData, "_set_sm_wish", "DS_BW_remove_ECM_bullshit", function(self)
	
	if not Network:is_server() then
		return
	end
	
	local enemies = {
		"tank",
		"tank_medic",
		"tank_mini",
		"tank_hw",
		"swat",
		"fbi_swat",
		"city_swat",
		"zeal_swat",
		"heavy_swat",
		"heavy_swat_sniper",
		"fbi_heavy_swat",
		"zeal_heavy_swat",
		"shield",
		"spooc",
		"sniper",
		"taser",
		"medic",
		"marshal_marksman",
		"marshal_shield",
		"marshal_shield_break",
		"phalanx_minion",
		"phalanx_vip"
	}
	
	for i=1, #enemies do
		if self[tostring(enemies[i])] and self[tostring(enemies[i])].ecm_vulnerability then
			self[tostring(enemies[i])].ecm_vulnerability = 0.18
			if self[tostring(enemies[i])].ecm_hurts and self[tostring(enemies[i])].ecm_hurts.ears then
				self[tostring(enemies[i])].ecm_hurts.ears = 1.5
			end
		end
	end
	
	-- used for enemy type tracking in other parts of the mod
	table.insert(self.tank_hw.tags, "DS_BW_tag_miniboss")
	table.insert(self.phalanx_minion.tags, "DS_BW_tag_reinforced_shield")
	
end)

-- Make winters no longer invincible, cause bugged out infinite assaults from him are annoying. This could help, if host kills him. Also people die when you shoot at them :)
Hooks:PostHook(CharacterTweakData, "_init_phalanx_vip", "DS_BW_make_winters_killable", function(self, presets)
	if not Network:is_server() then
		return
	end
	
	self.phalanx_vip.LOWER_HEALTH_PERCENTAGE_LIMIT = nil
	self.phalanx_vip.FINAL_LOWER_HEALTH_PERCENTAGE_LIMIT = nil
end)