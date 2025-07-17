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
	
	DS_BW.CopUtils.allowed_cuffing_time = DS_BW.CopUtils.allowed_cuffing_time or {0,0,0,0}
	
	if tweak == "revive" then
		DS_BW.CopUtils.allowed_cuffing_time[managers.network:session():peer_by_unit(self._unit):id()] = Application:time() + 3.4 -- should cover up to 300 ping, theoretically
	else
		DS_BW.CopUtils.allowed_cuffing_time[managers.network:session():peer_by_unit(self._unit):id()] = Application:time() + 1.4
	end
	
	DelayedCalls:Add("DS_BW_delay_for_cuff_scan_on_husk_"..tostring(self._unit), 1, function()
		DS_BW.CopUtils:NearbyCopAutoArrestCheck(self._unit, false)
	end)
	
end)
