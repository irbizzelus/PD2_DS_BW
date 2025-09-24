core:import("CoreMissionScriptElement")
ElementSpawnEnemyDummy = ElementSpawnEnemyDummy or class(CoreMissionScriptElement.MissionScriptElement)

-- spawn more enemies per spawn instance. code partialy yoinked from: https://modworkshop.net/mod/20649
Hooks:PostHook(ElementSpawnEnemyDummy, "produce", "DS_BW_spawn_more_shit", function(self)
	
	if not (DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	if not (Network and Network:is_server()) then
		return
	end
	local unit = self._units[#self._units]
	if not unit or not alive(unit) then
		return
	end
	if not managers.groupai or not managers.groupai:state() then
		return
	end
	local grpai = managers.groupai:state()
	if not grpai or not grpai:is_AI_enabled() or not grpai:enemy_weapons_hot() or grpai:whisper_mode() then
		return
	end
	if not unit:character_damage():can_kill() or unit:character_damage():dead() then
		return
	end
	if grpai:is_enemy_converted_to_criminal(unit) then
		return
	end
	if not managers.enemy:is_enemy(unit) then
		return
	end
	if managers.enemy:is_civilian(unit) then
		return
	end
	
	local enemy_count = managers.enemy._enemy_data.nr_units or 0
	-- failsafe that is probably not needed
	if enemy_count == 0 then
		for key, data in pairs(managers.enemy:all_enemies()) do
			enemy_count = enemy_count + 1
		end
	end
	
	if DS_BW._dsbw_new_winter_penalty_applied_ang_going then
		if enemy_count > 150 then -- hard cap for the sake of FPS performance
			return
		end
	elseif enemy_count > DS_BW.base_groupaitweak_values.assault_force[3] then
		return
	end
	
	local _spawn_enemy = function (grpai, unit_name, pos, rot)
		local unit_done = safe_spawn_unit(unit_name, pos, rot)
		local team_id = tweak_data.levels:get_default_team_ID(unit_done:base():char_tweak().access == "gangster" and "gangster" or "combatant")
		unit_done:movement():set_team(grpai:team_data( team_id ))
		grpai:assign_enemy_to_group_ai(unit_done, team_id)
		return unit_done
	end

	local _pos_offset = function ()
		local ang = math.random() * 360 * math.pi
		local rad = math.random(20, 30)
		return Vector3(math.cos(ang) * rad, math.sin(ang) * rad, 0)
	end
	
	local spawn_mul = 1
	
	-- killwhoring adjustment system, if enemy amounts were too low for long enough, their spawn duplicates are increased. same in the opposite direction, but only if we already have higher than base level respawns
	DS_BW._low_spawns_manager = DS_BW._low_spawns_manager or {level = 0, detected_low = false, detected_high = false, adjustment_cooldown = -999}
	local function increased_spawn_adjustment_allowed()
		local res = true
		local is_hard = Global.level_data and Global.level_data.level_id and (table.contains(DS_BW.heists_without_1st_assault, Global.level_data.level_id))
		if DS_BW.Assault_info.number < 2 and not DS_BW.Assault_info.is_infinite and not is_hard then
			res = false
		end
		if not (DS_BW.Assault_info.phase == "sustain" or DS_BW.Assault_info.phase == "build") then
			res = false
		end
		if DS_BW._dsbw_new_winter_penalty_applied_ang_going then
			res = false
		end
		if not ((Application:time() - DS_BW._low_spawns_manager.adjustment_cooldown) > (10 + DS_BW._low_spawns_manager.level * 10)) then
			res = false
		end
		return res
	end
	if increased_spawn_adjustment_allowed() then
		local og_level = DS_BW._low_spawns_manager.level
		local target_enemy_spawns = managers.groupai:state()._task_data.assault.active and managers.groupai:state()._task_data.assault.force
		
		if target_enemy_spawns and enemy_count < (target_enemy_spawns * 0.75) then
			DS_BW._low_spawns_manager.detected_high = false
			if not DS_BW._low_spawns_manager.detected_low then
				DS_BW._low_spawns_manager.detected_low = Application:time()
			end
			local function is_over_kpm_threshold()
				local hkpm = -1
				for i=1,4 do
					if DS_BW.kpm_tracker.kpm[i] > hkpm then
						hkpm = DS_BW.kpm_tracker.kpm[i]
					end
				end
				local thresholds = {
					[1] = 0,
					[2] = 12,
					[3] = 16,
					[4] = 24,
					[5] = 35,
				}
				if hkpm > thresholds[DS_BW._low_spawns_manager.level+1] then
					return true
				else
					return false
				end
			end
			if (Application:time() - DS_BW._low_spawns_manager.detected_low) > (10 + DS_BW._low_spawns_manager.level * 5) and is_over_kpm_threshold() then
				DS_BW._low_spawns_manager.level = DS_BW._low_spawns_manager.level + 1
				if DS_BW._low_spawns_manager.level > 5 then
					DS_BW._low_spawns_manager.level = 5
				end
				DS_BW._low_spawns_manager.detected_low = false
				DS_BW._low_spawns_manager.detected_high = false
				DS_BW._low_spawns_manager.adjustment_cooldown = Application:time()
			end
		elseif target_enemy_spawns and enemy_count > (target_enemy_spawns * 0.75) then
			DS_BW._low_spawns_manager.detected_low = false
			if DS_BW._low_spawns_manager.level > 0 and not DS_BW._low_spawns_manager.detected_high then
				DS_BW._low_spawns_manager.detected_high = Application:time()
			end
			if DS_BW._low_spawns_manager.level > 0 and (Application:time() - DS_BW._low_spawns_manager.detected_high) > (15 + DS_BW._low_spawns_manager.level * 7.5) then
				DS_BW._low_spawns_manager.level = DS_BW._low_spawns_manager.level - 1
				if DS_BW._low_spawns_manager.level < 0 then
					DS_BW._low_spawns_manager.level = 0
				end
				DS_BW._low_spawns_manager.detected_low = false
				DS_BW._low_spawns_manager.detected_high = false
				DS_BW._low_spawns_manager.adjustment_cooldown = Application:time()
			end
		end
		
		if og_level ~= DS_BW._low_spawns_manager.level then
			DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update = og_level
		end
		
		DS_BW.kpm_tracker.update_cooldown = DS_BW.kpm_tracker.update_cooldown or -1
		local should_update_kpm_DR = false
		if Application:time() > DS_BW.kpm_tracker.update_cooldown then
			DS_BW.kpm_tracker.update_cooldown = Application:time() + 30
			should_update_kpm_DR = true
		end
		if DS_BW._low_spawns_manager.level <= og_level and DS_BW._low_spawns_manager.level <= 2 and DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update then
			for i=1,4 do
				if DS_BW.kpm_tracker.penalties[i].amount > 0 and not DS_BW.kpm_tracker.penalties[i].is_perma then
					DS_BW.kpm_tracker.penalties[i].amount = 0
				end
			end
		elseif og_level == DS_BW._low_spawns_manager.level and DS_BW._low_spawns_manager.level == 3 and (DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update or should_update_kpm_DR) then
			for i=1,4 do
				if DS_BW.kpm_tracker.penalties[i].amount > 0 and not DS_BW.kpm_tracker.penalties[i].is_perma then
					DS_BW.kpm_tracker.penalties[i].amount = 0
				end
			end
			DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update = nil
			local highest_kpm = -1
			local highest_kpm_id = -1
			for i=1,4 do
				if DS_BW.kpm_tracker.kpm[i] > highest_kpm then
					highest_kpm = DS_BW.kpm_tracker.kpm[i]
					highest_kpm_id = i
				end
			end
			if highest_kpm > 0 and not DS_BW.kpm_tracker.penalties[highest_kpm_id].is_perma then
				DS_BW.kpm_tracker.penalties[highest_kpm_id].amount = 0.2
			end
		elseif og_level == DS_BW._low_spawns_manager.level and DS_BW._low_spawns_manager.level == 4 and (DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update or should_update_kpm_DR) then
			for i=1,4 do
				if DS_BW.kpm_tracker.penalties[i].amount > 0 and not DS_BW.kpm_tracker.penalties[i].is_perma then
					DS_BW.kpm_tracker.penalties[i].amount = 0
				end
			end
			DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update = nil
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
			if highest_kpm > 0 and not DS_BW.kpm_tracker.penalties[highest_kpm_id].is_perma then
				DS_BW.kpm_tracker.penalties[highest_kpm_id].amount = 0.33
			end
			if second_highest_kpm > 0 and not DS_BW.kpm_tracker.penalties[second_highest_kpm_id].is_perma then
				DS_BW.kpm_tracker.penalties[second_highest_kpm_id].amount = 0.33
			end
		elseif og_level == DS_BW._low_spawns_manager.level and DS_BW._low_spawns_manager.level == 5 and DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update then
			DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update = nil
			for i=1,4 do
				DS_BW.kpm_tracker.penalties[i].amount = 0.33
				DS_BW.kpm_tracker.penalties[i].is_perma = true
			end
		end
		
		local function chat_debug()
			--DS_BW._enable_public_AKH_debug = true
			if og_level ~= DS_BW._low_spawns_manager.level then
				local lvl_str = tostring(DS_BW._low_spawns_manager.level)
				if DS_BW._dsbw_new_winter_penalty_applied_ang_going and DS_BW.Miniboss_info.is_alive then
					lvl_str = lvl_str.."+(4)"
				elseif DS_BW._dsbw_new_winter_penalty_applied_ang_going then
					lvl_str = lvl_str.."+(2)"
				elseif DS_BW.Miniboss_info.is_alive then
					lvl_str = lvl_str.."+(2)"
				end
				
				local msg = "Adaptable difficulty level: "..lvl_str
				if DS_BW._enable_public_AKH_debug then
					DS_BW.CM:public_chat_message("[DS_BW] "..msg)
				else
					DS_BW.CM:private_chat_message(1, msg)
				end
			end
		end
		chat_debug()
		
		if DS_BW._low_spawns_manager.level > 0 then
			spawn_mul = spawn_mul + DS_BW._low_spawns_manager.level
		end
	else
		DS_BW._low_spawns_manager.detected_low = false
		DS_BW._low_spawns_manager.detected_high = false
	end
	
	if DS_BW._dsbw_new_winter_penalty_applied_ang_going then
		spawn_mul = spawn_mul + 2
	end
	if DS_BW.Miniboss_info.is_alive then
		spawn_mul = spawn_mul + 2
	end
	
	-- only multiply specific unit types to increase spawns. currently includes: light/heavy swat at all times. cloaker, tazer, green-minigun-only dozer for ultra-increased moments
	local enemy_whitelist = {
		------ AMERICA ------
		[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()] = 0,
		[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()] = 0,
		[("units/pd2_dlc_gitgud/characters/ene_zeal_cloaker/ene_zeal_cloaker"):key()] = 2,
		[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()] = 1,
		[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()] = 2,
		[("units/pd2_dlc_gitgud/characters/ene_zeal_tazer/ene_zeal_tazer"):key()] = 1,
		[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield"):key()] = 0,
		[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()] = 1,
		[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()] = 2,
		[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()] = 3,
		[("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic"):key()] = 3,
		------ RUSSIA ------
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_g36/ene_akan_fbi_heavy_g36"):key()] = 0,
		[("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"):key()] = 0,
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_spooc_asval_smg/ene_akan_fbi_spooc_asval_smg"):key()] = 2,
		[("units/pd2_dlc_mad/characters/ene_akan_medic_ak47_ass/ene_akan_medic_ak47_ass"):key()] = 1,
		[("units/pd2_dlc_mad/characters/ene_akan_medic_r870/ene_akan_medic_r870"):key()] = 2,
		[("units/pd2_dlc_mad/characters/ene_akan_cs_tazer_ak47_ass/ene_akan_cs_tazer_ak47_ass"):key()] = 1,
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_shield_dw_sr2_smg/ene_akan_fbi_shield_dw_sr2_smg"):key()] = 0,
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_saiga/ene_akan_fbi_tank_saiga"):key()] = 1,
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_r870/ene_akan_fbi_tank_r870"):key()] = 2,
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_rpk_lmg/ene_akan_fbi_tank_rpk_lmg"):key()] = 3,
		------ ZOMBIE ------
		[("units/pd2_dlc_hvh/characters/ene_swat_heavy_hvh_1/ene_swat_heavy_hvh_1"):key()] = 0,
		[("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1"):key()] = 0,
		[("units/pd2_dlc_hvh/characters/ene_spook_hvh_1/ene_spook_hvh_1"):key()] = 2,
		[("units/pd2_dlc_hvh/characters/ene_medic_hvh_m4/ene_medic_hvh_m4"):key()] = 1,
		[("units/pd2_dlc_hvh/characters/ene_medic_hvh_r870/ene_medic_hvh_r870"):key()] = 2,
		[("units/pd2_dlc_hvh/characters/ene_tazer_hvh_1/ene_tazer_hvh_1"):key()] = 1,
		[("units/pd2_dlc_hvh/characters/ene_shield_hvh_1/ene_shield_hvh_1"):key()] = 0,
		[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_1/ene_bulldozer_hvh_1"):key()] = 1,
		[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_2/ene_bulldozer_hvh_2"):key()] = 2,
		[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_3/ene_bulldozer_hvh_3"):key()] = 3,
		------ MURKYWATER ------
		[("units/pd2_dlc_bph/characters/ene_murkywater_heavy/ene_murkywater_heavy"):key()] = 0,
		[("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light"):key()] = 0,
		[("units/pd2_dlc_bph/characters/ene_murkywater_cloaker/ene_murkywater_cloaker"):key()] = 2,
		[("units/pd2_dlc_bph/characters/ene_murkywater_medic/ene_murkywater_medic"):key()] = 1,
		[("units/pd2_dlc_bph/characters/ene_murkywater_medic_r870/ene_murkywater_medic_r870"):key()] = 2,
		[("units/pd2_dlc_bph/characters/ene_murkywater_tazer/ene_murkywater_tazer"):key()] = 1,
		[("units/pd2_dlc_bph/characters/ene_murkywater_shield/ene_murkywater_shield"):key()] = 0,
		[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_2/ene_murkywater_bulldozer_2"):key()] = 1,
		[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_3/ene_murkywater_bulldozer_3"):key()] = 2,
		[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_4/ene_murkywater_bulldozer_4"):key()] = 3,
		[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_medic/ene_murkywater_bulldozer_medic"):key()] = 3,
		------ FEDERALES ------
		[("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale/ene_swat_heavy_policia_federale"):key()] = 0,
		[("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale"):key()] = 0,
		[("units/pd2_dlc_bex/characters/ene_swat_cloaker_policia_federale/ene_swat_cloaker_policia_federale"):key()] = 2,
		[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale/ene_swat_medic_policia_federale"):key()] = 1,
		[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale_r870/ene_swat_medic_policia_federale_r870"):key()] = 2,
		[("units/pd2_dlc_bex/characters/ene_swat_tazer_policia_federale/ene_swat_tazer_policia_federale"):key()] = 1,
		[("units/pd2_dlc_bex/characters/ene_swat_shield_policia_federale_mp9/ene_swat_shield_policia_federale_mp9"):key()] = 0,
		[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_saiga/ene_swat_dozer_policia_federale_saiga"):key()] = 1,
		[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_r870/ene_swat_dozer_policia_federale_r870"):key()] = 2,
		[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_m249/ene_swat_dozer_policia_federale_m249"):key()] = 3,
		[("units/pd2_dlc_bex/characters/ene_swat_dozer_medic_policia_federale/ene_swat_dozer_medic_policia_federale"):key()] = 3,
	}
	local uni_name = unit:name()
	if enemy_whitelist[uni_name:key()] and (spawn_mul - 1) >= enemy_whitelist[uni_name:key()] then
		for i = 1, spawn_mul do
			local pos, rot = self:get_orientation()
			local _unit_objective = unit:brain() and unit:brain():objective() or nil
			call_on_next_update(function ()
				local unit_done = _spawn_enemy(grpai, uni_name, pos + _pos_offset(), rot)
				if not _unit_objective then
					local playerss = grpai:all_player_criminals()
					if playerss then
						local cc = playerss[table.random_key(playerss)]
						if Utils:IsInHeist() and cc and cc.unit and alive(cc.unit) then
							_unit_objective = {
								type = "follow",
								follow_unit = cc.unit,
								scan = true,
								is_default = true
							}
						end
					end
				end
				if _unit_objective then
					unit_done:brain():set_objective(_unit_objective)
				end
				table.insert(self._units, unit_done)
			end)
		end
	end
	
end)