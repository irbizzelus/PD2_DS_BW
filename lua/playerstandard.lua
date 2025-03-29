if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

-- When local player starts interacting, send a cop to arrest them + activate scan to enable cuffing from other units
Hooks:PostHook(PlayerStandard, "_start_action_interact", "DS_BW_cuffing_on_local_player_interaction_start", function(self)

	if not DS_BW.DS_difficultycheck then
		return
	end
	
	if Network and Network:is_client() then
		return
	end
	
	local interaction_type = self._unit:movement():current_state()._interact_params.tweak_data
	DS_BW.CopUtils:SendCopToArrestPlayer(self._unit, interaction_type)
	
	if interaction_type == "revive" then
		DelayedCalls:Add("DS_BW_delay_for_cuff_scan_on_local", 3.5, function()
			DS_BW.CopUtils:NearbyCopAutoArrestCheck(self._unit, true)
		end)
	else
		DelayedCalls:Add("DS_BW_delay_for_cuff_scan_on_local", 1.5, function()
			DS_BW.CopUtils:NearbyCopAutoArrestCheck(self._unit, true)
		end)
	end

end)