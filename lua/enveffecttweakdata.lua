function EnvEffectTweakData:incendiary_fire()
	local params = {
		sound_event = "no_sound",
		range = 75,
		curve_pow = 3,
		damage = 1,
		fire_alert_radius = 1500,
		sound_event_burning_stop = "burn_loop_gen_stop_fade",
		alert_radius = 1500,
		sound_event_burning = "burn_loop_gen",
		player_damage = 2,
		sound_event_impact_duration = 0,
		burn_tick_period = 0.5,
		burn_duration = 6,
		dot_data_name = "proj_launcher_incendiary_groundfire",
		effect_name = "effects/payday2/particles/explosions/molotov_grenade"
	}
	
	-- if fire field was requested by the flashbang firetrap, apply new stats. damage value is important for firemanager.lua
	if DS_BW and DS_BW._creating_fire_trap then
		params.player_damage = DS_BW._creating_fire_trap
		params.burn_duration = 0
		params.damage = -0.69
		DS_BW._creating_fire_trap = nil
	end

	return params
end