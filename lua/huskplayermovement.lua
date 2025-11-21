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
	
	-- make cuffing checks for clients without DSBW installed only
	if not DS_BW.peers_with_mod[managers.network:session():peer_by_unit(self._unit):id()] then
		
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
		
	end
	
end)

Hooks:PostHook(HuskPlayerMovement, "_apply_attention_setting_modifications", "DS_BW_post_apply_attention_setting_modifications", function(self, setting)
	
	if not DS_BW.DS_difficultycheck then
		return
	end
	
	if Network and Network:is_client() then
		return
	end
	
	-- add attention level to player(s) with too high of a kpm
	if DS_BW._low_spawns_manager and DS_BW._low_spawns_manager.level == 3 then
		local highest_kpm = -1
		local highest_kpm_id = -1
		for i=1,4 do
			if DS_BW.kpm_tracker.kpm[i] > highest_kpm then
				highest_kpm = DS_BW.kpm_tracker.kpm[i]
				highest_kpm_id = i
			end
		end
		if highest_kpm > 0 and managers.network:session():peer_by_unit(self._unit):id() == highest_kpm_id then
			local new_mul = 5
			setting.weight_mul = (setting.weight_mul or 1) * new_mul
		end
	elseif DS_BW._low_spawns_manager and DS_BW._low_spawns_manager.level >= 4 then
		local highest_kpm = -1
		local highest_kpm_id = -1
		local second_highest_kpm = -1
		local second_highest_kpm_id = -1
		for i=1,4 do
			if DS_BW.kpm_tracker.kpm[i] > highest_kpm then
				second_highest_kpm = highest_kpm
				second_highest_kpm_id = highest_kpm_id
				
				highest_kpm = DS_BW.kpm_tracker.kpm[i]
				highest_kpm_id = i
			elseif DS_BW.kpm_tracker.kpm[i] > second_highest_kpm then
				second_highest_kpm = DS_BW.kpm_tracker.kpm[i]
				second_highest_kpm_id = i
			end
		end
		if highest_kpm > 0 and managers.network:session():peer_by_unit(self._unit):id() == highest_kpm_id then
			local new_mul = 2.5
			setting.weight_mul = (setting.weight_mul or 1) * new_mul
		end
		if second_highest_kpm > 0 and managers.network:session():peer_by_unit(self._unit):id() == second_highest_kpm_id then
			local new_mul = 2.5
			setting.weight_mul = (setting.weight_mul or 1) * new_mul
		end
	end
	
end)

Hooks:PostHook(HuskPlayerMovement, "set_need_revive", "DSBW_on_husk_downed", function(self, need_revive, down_time)
	if not (Network:is_server() and DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	if need_revive and self._unit and alive(self._unit) then
		local peer_id = managers.network:session():peer_by_unit(self._unit):id()
		if peer_id and DS_BW.kpm_tracker.kills[peer_id] then
			DS_BW.kpm_tracker.kills[peer_id] = (DS_BW.kpm_tracker.kills[peer_id] or 0) - 5
		end
	end
end)