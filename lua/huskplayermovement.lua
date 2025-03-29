if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

-- When a client starts interacting, send a cop to arrest them + activate scan to enable cuffing from other units
Hooks:PostHook(HuskPlayerMovement, "sync_interaction_anim_start", "DS_BW_cuffing_on_husk_interaction_start", function(self,tweak)

	if not DS_BW.DS_difficultycheck then
		return
	end
	
	if Network and Network:is_client() then
		return
	end
	
	DS_BW.CopUtils:SendCopToArrestPlayer(self._unit, tweak)
	-- check starts slightly later for connected peers to prevent cuffing on players with high ping
	if tweak == "revive" then
		DelayedCalls:Add("DS_BW_delay_for_cuff_scan_on_husk_"..tostring(self._unit), 3.6, function()
			DS_BW.CopUtils:NearbyCopAutoArrestCheck(self._unit, false)
		end)
	else
		DelayedCalls:Add("DS_BW_delay_for_cuff_scan_on_husk"..tostring(self._unit), 1.6, function()
			DS_BW.CopUtils:NearbyCopAutoArrestCheck(self._unit, false)
		end)
	end
	
end)
