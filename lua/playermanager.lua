Hooks:PreHook(PlayerManager, "set_player_state", "DSBW_on_local_player_downed", function(self, state)
	if not (Network:is_server() and DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	if state == "bleed_out" and DS_BW.kpm_tracker.kills[1] then
		DS_BW.kpm_tracker.kills[1] = (DS_BW.kpm_tracker.kills[1] or 0) - 5
	end
end