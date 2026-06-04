Hooks:PreHook(PlayerManager, "set_player_state", "DSBW_on_local_player_downed", function(self, state)
	if not (Network:is_server() and DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	if state == "bleed_out" and DS_BW.kpm_tracker.kills[1] and not DS_BW.kpm_tracker.downed_this_update[1] then
		DS_BW.kpm_tracker.kills[1] = (DS_BW.kpm_tracker.kills[1] or 0) - (DS_BW.kpm_tracker.down_adjustmets_per_lvl[DS_BW._low_spawns_manager.level] * 0.75)
		DS_BW.kpm_tracker.downed_this_update[1] = true
	end
end