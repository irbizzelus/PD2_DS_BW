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
	
	local target_enemy_spawns = managers.groupai:state()._task_data.assault.active and managers.groupai:state()._task_data.assault.force
	
	-- hard cap for the sake of FPS performance
	if DS_BW._dsbw_new_winter_penalty_applied_ang_going and enemy_count > 150 then 
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
	
	local spawn_mul = 0
	
	-- killwhoring adjustment system, if enemy amounts were too low for long enough, their spawn duplicates are increased. same in the opposite direction, but only if we already have higher than base level respawns
	DS_BW._low_spawns_manager = DS_BW._low_spawns_manager or {level = 0, detected_low = false, detected_high = false, adjustment_cooldown = -999}
	local function increased_spawn_adjustment_allowed()
		local res = true
		-- if DS_BW.Assault_info.number < 2 and not DS_BW.Assault_info.is_infinite and not DS_BW.is_hard_heist() then
			-- res = false
		-- end
		if not (DS_BW.Assault_info.phase == "sustain" or DS_BW.Assault_info.phase == "build") then
			res = false
		end
		if DS_BW._dsbw_new_winter_penalty_applied_ang_going then
			res = false
		end
		if not ((Application:time() - DS_BW._low_spawns_manager.adjustment_cooldown) > (20 + DS_BW._low_spawns_manager.level * 8.5)) then
			res = false
		end
		return res
	end
	
	local level_floor_limit = DS_BW.settings.starting_adapt_diff - 1 -- lua starts at 1 :)
	if level_floor_limit > 0 and DS_BW._low_spawns_manager.level < level_floor_limit then
		DS_BW._low_spawns_manager.level = level_floor_limit
		DS_BW._low_spawns_manager.detected_low = false
		DS_BW._low_spawns_manager.detected_high = false
		DS_BW._low_spawns_manager.adjustment_cooldown = Application:time()
		DS_BW.announce_adapt_diff()
	end
	-- if lvl 1 is ever reached, never drop bellow it
	if DS_BW._low_spawns_manager.level == 1 then
		level_floor_limit = 1
	end
	
	if increased_spawn_adjustment_allowed() then
		local og_level = DS_BW._low_spawns_manager.level
		
		local function kpm_threshold_check()
			local hkpm = -1
			local avg_kpm = 0
			for i=1,4 do
				avg_kpm = avg_kpm + DS_BW.kpm_tracker.kpm[i]
				if DS_BW.kpm_tracker.kpm[i] > hkpm then
					hkpm = DS_BW.kpm_tracker.kpm[i]
				end
			end
			avg_kpm = avg_kpm / (managers.groupai:state():num_alive_players() or 4)
			if DS_BW._low_spawns_manager.level < 5 and hkpm >= DS_BW.kpm_tracker.thresholds[DS_BW._low_spawns_manager.level+1] and avg_kpm >= (DS_BW.kpm_tracker.thresholds[DS_BW._low_spawns_manager.level+1] * 0.6) then
				return "over" -- allows to go up
			elseif DS_BW._low_spawns_manager.level >= 1 and hkpm < DS_BW.kpm_tracker.thresholds[DS_BW._low_spawns_manager.level] then
				return "under" -- forces to go down
			else
				return false
			end
		end
		
		if target_enemy_spawns and enemy_count <= (target_enemy_spawns * 0.75) and kpm_threshold_check() == "over" then
			DS_BW._low_spawns_manager.detected_high = false
			if not DS_BW._low_spawns_manager.detected_low then
				DS_BW._low_spawns_manager.detected_low = Application:time()
			end
			if (Application:time() - DS_BW._low_spawns_manager.detected_low) > (20 + DS_BW._low_spawns_manager.level * 8.5) then
				DS_BW._low_spawns_manager.level = DS_BW._low_spawns_manager.level + 1
				if DS_BW._low_spawns_manager.level > 5 then
					DS_BW._low_spawns_manager.level = 5
				end
				DS_BW._low_spawns_manager.detected_low = false
				DS_BW._low_spawns_manager.detected_high = false
				DS_BW._low_spawns_manager.adjustment_cooldown = Application:time()
			end
		elseif (target_enemy_spawns and enemy_count >= (target_enemy_spawns * 0.85)) or kpm_threshold_check() == "under" then
			DS_BW._low_spawns_manager.detected_low = false
			if DS_BW._low_spawns_manager.level > 0 and not DS_BW._low_spawns_manager.detected_high then
				DS_BW._low_spawns_manager.detected_high = Application:time()
			end
			if DS_BW._low_spawns_manager.level > 0 and (Application:time() - DS_BW._low_spawns_manager.detected_high) > (40 + DS_BW._low_spawns_manager.level * 17) and (DS_BW._low_spawns_manager.level > level_floor_limit) then
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
			DS_BW.kpm_tracker.update_cooldown = Application:time() + 60
			should_update_kpm_DR = true
		end
		if DS_BW._low_spawns_manager.level <= og_level and DS_BW._low_spawns_manager.level <= 3 and DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update then
			for i=1,4 do
				if DS_BW.kpm_tracker.penalties[i].amount > 0 and not DS_BW.kpm_tracker.penalties[i].is_perma then
					DS_BW.kpm_tracker.penalties[i].amount = 0
				end
			end
		-- elseif og_level == DS_BW._low_spawns_manager.level and DS_BW._low_spawns_manager.level == 3 and (DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update or should_update_kpm_DR) then
			-- for i=1,4 do
				-- if DS_BW.kpm_tracker.penalties[i].amount > 0 and not DS_BW.kpm_tracker.penalties[i].is_perma then
					-- DS_BW.kpm_tracker.penalties[i].amount = 0
				-- end
			-- end
			-- DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update = nil
			-- for i=1,4 do
				-- if DS_BW.kpm_tracker.kpm[i] >= DS_BW.kpm_tracker.thresholds[3] then
					-- if not DS_BW.kpm_tracker.penalties[i].is_perma then
						-- DS_BW.kpm_tracker.penalties[i].amount = 0.2
					-- end
				-- end
			-- end
		elseif og_level == DS_BW._low_spawns_manager.level and DS_BW._low_spawns_manager.level == 4 and (DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update or should_update_kpm_DR) then
			DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update = nil
			for i=1,4 do
				if DS_BW.kpm_tracker.penalties[i].amount > 0 and not DS_BW.kpm_tracker.penalties[i].is_perma then
					DS_BW.kpm_tracker.penalties[i].amount = 0
				end
				if DS_BW.kpm_tracker.kpm[i] >= DS_BW.kpm_tracker.thresholds[4] then
					DS_BW.kpm_tracker.penalties[i].amount = 0.33
				else
					DS_BW.kpm_tracker.penalties[i].amount = 0.20
				end
			end
		elseif og_level == DS_BW._low_spawns_manager.level and DS_BW._low_spawns_manager.level == 5 and DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update then
			DS_BW._low_spawns_manager.update_dmg_res_penalties_next_update = nil
			for i=1,4 do
				DS_BW.kpm_tracker.penalties[i].is_perma = true
				if DS_BW.kpm_tracker.kpm[i] >= DS_BW.kpm_tracker.thresholds[5] then
					DS_BW.kpm_tracker.penalties[i].amount = 0.5
				else
					DS_BW.kpm_tracker.penalties[i].amount = 0.33
				end
			end
			local msg = "[DS_BW] Congrautlations! Team performance was just re-evaluated, and deemed way too effective. All enemies now have a permanent 33-50% damage resistance against all players, scaling based on your performance. Good luck."
			DS_BW.CM:public_chat_message(msg)
		end
		
		if DS_BW.kpm_tracker.penalties[1].is_perma and should_update_kpm_DR then
			for i=1,4 do
				if DS_BW.kpm_tracker.kpm[i] >= DS_BW.kpm_tracker.thresholds[5] then
					DS_BW.kpm_tracker.penalties[i].amount = 0.5
				else
					DS_BW.kpm_tracker.penalties[i].amount = 0.33
				end
			end
		end
		
		if og_level ~= DS_BW._low_spawns_manager.level then
			DS_BW.announce_adapt_diff()
		end
		
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
		[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()] = {start = 1, mul = 1.25},
		[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()] = {start = 2, mul = 1},
		[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_gitgud/characters/ene_zeal_tazer/ene_zeal_tazer"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield"):key()] = {start = 2, mul = 0.75},
		[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()] = {start = 2, mul = 0.6},
		[("units/pd2_dlc_gitgud/characters/ene_zeal_cloaker/ene_zeal_cloaker"):key()] = {start = 3, mul = 0.75},
		[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()] = {start = 3, mul = 0.6},
		[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()] = {start = 4, mul = 0.6},
		[("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic"):key()] = {start = 4, mul = 0.4},
		------ RUSSIA ------
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_g36/ene_akan_fbi_heavy_g36"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_mad/characters/ene_akan_medic_ak47_ass/ene_akan_medic_ak47_ass"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_mad/characters/ene_akan_medic_r870/ene_akan_medic_r870"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_mad/characters/ene_akan_cs_tazer_ak47_ass/ene_akan_cs_tazer_ak47_ass"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_shield_dw_sr2_smg/ene_akan_fbi_shield_dw_sr2_smg"):key()] = {start = 2, mul = 0.75},
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_saiga/ene_akan_fbi_tank_saiga"):key()] = {start = 2, mul = 0.6},
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_spooc_asval_smg/ene_akan_fbi_spooc_asval_smg"):key()] = {start = 3, mul = 0.75},
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_r870/ene_akan_fbi_tank_r870"):key()] = {start = 3, mul = 0.6},
		[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_rpk_lmg/ene_akan_fbi_tank_rpk_lmg"):key()] = {start = 4, mul = 0.6},
		------ ZOMBIE ------
		[("units/pd2_dlc_hvh/characters/ene_swat_heavy_hvh_1/ene_swat_heavy_hvh_1"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_hvh/characters/ene_medic_hvh_m4/ene_medic_hvh_m4"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_hvh/characters/ene_medic_hvh_r870/ene_medic_hvh_r870"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_hvh/characters/ene_tazer_hvh_1/ene_tazer_hvh_1"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_hvh/characters/ene_shield_hvh_1/ene_shield_hvh_1"):key()] = {start = 2, mul = 0.75},
		[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_1/ene_bulldozer_hvh_1"):key()] = {start = 2, mul = 0.6},
		[("units/pd2_dlc_hvh/characters/ene_spook_hvh_1/ene_spook_hvh_1"):key()] = {start = 3, mul = 0.75},
		[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_2/ene_bulldozer_hvh_2"):key()] = {start = 3, mul = 0.6},
		[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_3/ene_bulldozer_hvh_3"):key()] = {start = 4, mul = 0.6},
		------ MURKYWATER ------
		[("units/pd2_dlc_bph/characters/ene_murkywater_heavy/ene_murkywater_heavy"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_bph/characters/ene_murkywater_medic/ene_murkywater_medic"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_bph/characters/ene_murkywater_medic_r870/ene_murkywater_medic_r870"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_bph/characters/ene_murkywater_tazer/ene_murkywater_tazer"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_bph/characters/ene_murkywater_shield/ene_murkywater_shield"):key()] = {start = 2, mul = 0.75},
		[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_2/ene_murkywater_bulldozer_2"):key()] = {start = 2, mul = 0.6},
		[("units/pd2_dlc_bph/characters/ene_murkywater_cloaker/ene_murkywater_cloaker"):key()] = {start = 3, mul = 0.75},
		[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_3/ene_murkywater_bulldozer_3"):key()] = {start = 3, mul = 0.6},
		[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_4/ene_murkywater_bulldozer_4"):key()] = {start = 4, mul = 0.6},
		[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_medic/ene_murkywater_bulldozer_medic"):key()] = {start = 4, mul = 0.4},
		------ FEDERALES ------
		[("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale/ene_swat_heavy_policia_federale"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale"):key()] = {start = 1, mul = 1.25},
		[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale/ene_swat_medic_policia_federale"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale_r870/ene_swat_medic_policia_federale_r870"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_bex/characters/ene_swat_tazer_policia_federale/ene_swat_tazer_policia_federale"):key()] = {start = 2, mul = 1},
		[("units/pd2_dlc_bex/characters/ene_swat_shield_policia_federale_mp9/ene_swat_shield_policia_federale_mp9"):key()] = {start = 2, mul = 0.75},
		[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_saiga/ene_swat_dozer_policia_federale_saiga"):key()] = {start = 2, mul = 0.6},
		[("units/pd2_dlc_bex/characters/ene_swat_cloaker_policia_federale/ene_swat_cloaker_policia_federale"):key()] = {start = 3, mul = 0.75},
		[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_r870/ene_swat_dozer_policia_federale_r870"):key()] = {start = 3, mul = 0.6},
		[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_m249/ene_swat_dozer_policia_federale_m249"):key()] = {start = 4, mul = 0.6},
		[("units/pd2_dlc_bex/characters/ene_swat_dozer_medic_policia_federale/ene_swat_dozer_medic_policia_federale"):key()] = {start = 4, mul = 0.4},
	}
	local uni_name = unit:name()
	if enemy_whitelist[uni_name:key()] and spawn_mul >= enemy_whitelist[uni_name:key()].start and target_enemy_spawns and enemy_count < (target_enemy_spawns * 0.8) then
		spawn_mul = math.floor(spawn_mul * enemy_whitelist[uni_name:key()].mul)
		if spawn_mul >= 1 then
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
	end
	
end)