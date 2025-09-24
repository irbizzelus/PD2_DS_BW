Hooks:PostHook(PlayerMovement, "_apply_attention_setting_modifications", "DS_BW_post_playermovement_apply_attention_setting_modifications", function(self, setting)
	if not (DS_BW and DS_BW.DS_difficultycheck) then
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
	
	local new_mul = 1
	setting.weight_mul = (setting.weight_mul or 1) * new_mul
end)