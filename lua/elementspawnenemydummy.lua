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
	local target_enemy_spawns = managers.groupai:state()._task_data.assault.active and managers.groupai:state()._task_data.assault.force
	
	-- hard cap for the sake of FPS performance
	if DS_BW._dsbw_new_winter_penalty_applied_ang_going and enemy_count > 150 then 
		return
	end
	
	local _spawn_enemy = function (grpai, unit_name, pos, rot, og_unit)
		local assign_to_group = "default"
		if alive(og_unit) and og_unit.brain and og_unit:brain() and og_unit:brain()._logic_data and og_unit:brain()._logic_data.group then
			assign_to_group = og_unit:brain()._logic_data.group
		end
		local unit_done = nil
		if alive(og_unit) and og_unit.unit_data and og_unit:unit_data() and og_unit:unit_data().mission_element then
			element_to_asign = og_unit:unit_data().mission_element
			unit_done = safe_spawn_unit(unit_name, pos, rot)
			local team_id = tweak_data.levels:get_default_team_ID("combatant")
			unit_done:movement():set_team(grpai:team_data( team_id ))
			if assign_to_group == "default" then
				grpai:assign_enemy_to_group_ai(unit_done, team_id)
			else
				grpai:assign_enemy_to_existing_group(unit_done, assign_to_group)
			end
			if alive(unit_done) and unit_done.unit_data and unit_done:unit_data() then
				unit_done:unit_data().mission_element = element_to_asign
				unit_done:unit_data()._DSBW_unit_spawned_at = Application:time()
			end
		end
		return unit_done
	end

	local _pos_offset = function ()
		local ang = math.random() * 360 * math.pi
		local rad = math.random(20, 30)
		return Vector3(math.cos(ang) * rad, math.sin(ang) * rad, 0)
	end
	
	if not DS_BW.adu_running then
		DS_BW:ADU_Update()
	end
	
	local spawn_mul = 0
	
	if DS_BW._low_spawns_manager.level > 0 then
		spawn_mul = spawn_mul + DS_BW._low_spawns_manager.level
	end
	
	if DS_BW._dsbw_new_winter_penalty_applied_ang_going then
		spawn_mul = spawn_mul + 2
	end
	
	-- captain not affecting spawns at level 5 is probably not a huge loss, since his penalties are genreally "whatever" if compared to diff 5 overall
	if spawn_mul > 5 then
		spawn_mul = 5
	end
	
	-- for every spawned in unit, spawn x copies of said unit. scales with ADL 
	local enemy_whitelist = {}
	------ AMERICA ------
	enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()] = {
		[0] = 0,
		[1] = 1,
		[2] = 1,
		[3] = 2,
		[4] = 2,
		[5] = 3,
	}
	enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()] = {
		[0] = 1,
		[1] = 1,
		[2] = 2,
		[3] = 2,
		[4] = 3,
		[5] = 3,
	}
	enemy_whitelist[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()] = {
		[0] = 0,
		[1] = 0,
		[2] = 1,
		[3] = 2,
		[4] = 2,
		[5] = 3,
	}
	enemy_whitelist[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()] = {
		[0] = 0,
		[1] = 0,
		[2] = 1,
		[3] = 2,
		[4] = 2,
		[5] = 3,
	}
	enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_tazer/ene_zeal_tazer"):key()] = {
		[0] = 0,
		[1] = 1,
		[2] = 1,
		[3] = 2,
		[4] = 3,
		[5] = 3,
	}
	enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield"):key()] = {
		[0] = 1,
		[1] = 1,
		[2] = 2,
		[3] = 3,
		[4] = 3,
		[5] = 3,
	}
	enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()] = {
		[0] = 0,
		[1] = 0,
		[2] = 1,
		[3] = 2,
		[4] = 3,
		[5] = 3,
	}
	enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_cloaker/ene_zeal_cloaker"):key()] = {
		[0] = 1,
		[1] = 1,
		[2] = 1,
		[3] = 2,
		[4] = 2,
		[5] = 2,
	}
	enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()] = {
		[0] = 0,
		[1] = 0,
		[2] = 1,
		[3] = 2,
		[4] = 3,
		[5] = 3,
	}
	enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()] = {
		[0] = 0,
		[1] = 0,
		[2] = 0,
		[3] = 1,
		[4] = 2,
		[5] = 3,
	}
	enemy_whitelist[("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic"):key()] = {
		[0] = 0,
		[1] = 0,
		[2] = 0,
		[3] = 1,
		[4] = 2,
		[5] = 3,
	}
	------ RUSSIA ------
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_g36/ene_akan_fbi_heavy_g36"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_medic_ak47_ass/ene_akan_medic_ak47_ass"):key()] = deep_clone(enemy_whitelist[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_medic_r870/ene_akan_medic_r870"):key()] = deep_clone(enemy_whitelist[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_cs_tazer_ak47_ass/ene_akan_cs_tazer_ak47_ass"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_tazer/ene_zeal_tazer"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_fbi_shield_dw_sr2_smg/ene_akan_fbi_shield_dw_sr2_smg"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_saiga/ene_akan_fbi_tank_saiga"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_fbi_spooc_asval_smg/ene_akan_fbi_spooc_asval_smg"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_cloaker/ene_zeal_cloaker"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_r870/ene_akan_fbi_tank_r870"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()])
	enemy_whitelist[("units/pd2_dlc_mad/characters/ene_akan_fbi_tank_rpk_lmg/ene_akan_fbi_tank_rpk_lmg"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()])
	------ ZOMBIE ------
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_swat_heavy_hvh_1/ene_swat_heavy_hvh_1"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_medic_hvh_m4/ene_medic_hvh_m4"):key()] = deep_clone(enemy_whitelist[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_medic_hvh_r870/ene_medic_hvh_r870"):key()] = deep_clone(enemy_whitelist[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_tazer_hvh_1/ene_tazer_hvh_1"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_tazer/ene_zeal_tazer"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_shield_hvh_1/ene_shield_hvh_1"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_1/ene_bulldozer_hvh_1"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_spook_hvh_1/ene_spook_hvh_1"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_cloaker/ene_zeal_cloaker"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_2/ene_bulldozer_hvh_2"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()])
	enemy_whitelist[("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_3/ene_bulldozer_hvh_3"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()])
	------ MURKYWATER ------
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_heavy/ene_murkywater_heavy"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_medic/ene_murkywater_medic"):key()] = deep_clone(enemy_whitelist[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_medic_r870/ene_murkywater_medic_r870"):key()] = deep_clone(enemy_whitelist[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_tazer/ene_murkywater_tazer"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_tazer/ene_zeal_tazer"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_shield/ene_murkywater_shield"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_2/ene_murkywater_bulldozer_2"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_cloaker/ene_murkywater_cloaker"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_cloaker/ene_zeal_cloaker"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_3/ene_murkywater_bulldozer_3"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_4/ene_murkywater_bulldozer_4"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()])
	enemy_whitelist[("units/pd2_dlc_bph/characters/ene_murkywater_bulldozer_medic/ene_murkywater_bulldozer_medic"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic"):key()])
	------ FEDERALES ------
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale/ene_swat_heavy_policia_federale"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale/ene_swat_medic_policia_federale"):key()] = deep_clone(enemy_whitelist[("units/payday2/characters/ene_medic_m4/ene_medic_m4"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_medic_policia_federale_r870/ene_swat_medic_policia_federale_r870"):key()] = deep_clone(enemy_whitelist[("units/payday2/characters/ene_medic_r870/ene_medic_r870"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_tazer_policia_federale/ene_swat_tazer_policia_federale"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_tazer/ene_zeal_tazer"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_shield_policia_federale_mp9/ene_swat_shield_policia_federale_mp9"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_saiga/ene_swat_dozer_policia_federale_saiga"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_cloaker_policia_federale/ene_swat_cloaker_policia_federale"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_cloaker/ene_zeal_cloaker"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_r870/ene_swat_dozer_policia_federale_r870"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_m249/ene_swat_dozer_policia_federale_m249"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3"):key()])
	enemy_whitelist[("units/pd2_dlc_bex/characters/ene_swat_dozer_medic_policia_federale/ene_swat_dozer_medic_policia_federale"):key()] = deep_clone(enemy_whitelist[("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic"):key()])
	local uni_name = unit:name()
	if enemy_whitelist[uni_name:key()] and enemy_whitelist[uni_name:key()][spawn_mul] and target_enemy_spawns and enemy_count <= (target_enemy_spawns * 0.99) then
		spawn_mul = enemy_whitelist[uni_name:key()][spawn_mul]
		if spawn_mul >= 1 then
			for i = 1, spawn_mul do
				local pos, rot = self:get_orientation()
				local _unit_objective = unit:brain() and unit:brain():objective() or nil
				call_on_next_update(function ()
					local unit_done = _spawn_enemy(grpai, uni_name, pos + _pos_offset(), rot, unit)
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
					if unit_done and _unit_objective then
						unit_done:brain():set_objective(_unit_objective)
					end
					table.insert(self._units, unit_done)
				end)
			end
		end
	end
	
end)