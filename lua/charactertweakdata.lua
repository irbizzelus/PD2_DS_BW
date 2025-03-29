-- remove ecm effects from most enemies (excluding cops and gangsters cuz they are not elite enough i guess) to add more pain for hacker players. sadly it also affects standard ecm, but what can you do
Hooks:PostHook(CharacterTweakData, "_set_sm_wish", "DS_BW_remove_ECM_bullshit", function(self)
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
			self[tostring(enemies[i])].ecm_vulnerability = nil
			self[tostring(enemies[i])].ecm_hurts = nil
		end
	end
	
	-- used for enemy type tracking in other parts of the mod
	table.insert(self.tank_hw.tags, "DSBW_tag_miniboss")
	table.insert(self.phalanx_minion.tags, "DSBW_tag_reinforced_shield")
	
end)

-- Make winters no longer invincible, cause bugged out infinite assaults from him are annoying. This could help. Also people die when you shoot at them :)
Hooks:PostHook(CharacterTweakData, "_init_phalanx_vip", "ds_bw_make_winters_killable", function(self, presets)
	self.phalanx_vip.LOWER_HEALTH_PERCENTAGE_LIMIT = nil
	self.phalanx_vip.FINAL_LOWER_HEALTH_PERCENTAGE_LIMIT = nil
end)