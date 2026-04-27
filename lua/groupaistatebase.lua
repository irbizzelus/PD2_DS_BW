if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

function GroupAIStateBase:try_spawn_DSBW_miniboss()
	
	if not (DS_BW and DS_BW.Assault_info) then
		return
	end
	
	local function is_boss_spawn_allowed()
		local result = false
		local assault_num = DS_BW.Assault_info.number
		
		-- base requirements
		if assault_num == 1 and self._hunt_mode then
			return true
		elseif Global.level_data and Global.level_data.level_id and DS_BW:is_hard_heist() then
			if assault_num >= 2 then
				result = true
			end
		else
			if assault_num >= 3 then
				result = true
			end
		end
		
		-- rng
		if result then
			if DS_BW._low_spawns_manager and DS_BW._low_spawns_manager.level then
				DS_BW.Miniboss_info.spawn_chance.current = DS_BW.Miniboss_info.spawn_chance.current + (DS_BW._low_spawns_manager.level * 0.05) -- adapt. diff level increase always goes through
			end
			if DS_BW.Miniboss_info.spawn_chance.current > 0.9 then
				DS_BW.Miniboss_info.spawn_chance.current = 0.9
			end
			local rng_success = math.random() <= DS_BW.Miniboss_info.spawn_chance.current
			log("[DS_BW] Tried to spawn minibosses with "..tostring(DS_BW.Miniboss_info.spawn_chance.current * 100).."% chance.")
			if not rng_success then -- default increase only goes through if boss did not spawn
				DS_BW.Miniboss_info.spawn_chance.current = DS_BW.Miniboss_info.spawn_chance.current + DS_BW.Miniboss_info.spawn_chance.increase
			end
			return rng_success
		else
			return result
		end
	end
	
	-- choose a random alive player, select an availabe spawn point closet to said player, and spawn the boss there. prevent if winters is on level
	if is_boss_spawn_allowed() then
		if DS_BW.Miniboss_info.spawn_locations and #DS_BW.Miniboss_info.spawn_locations >= 1 and not (self._phalanx_spawn_group and self._phalanx_spawn_group.has_spawned) then
			
			local chosen_player = {}
			local players = self:all_player_criminals()
			if players then
				local boss_target = players[table.random_key(players)]
				if boss_target and boss_target.unit and alive(boss_target.unit) then
					chosen_player.unit = boss_target.unit
					chosen_player.coords = boss_target.unit:position()
				end
			end
			
			-- try to find enemy special units around chosen player pos, to spawn boss at that location,
			-- to hopefuly prevent bosses from getting stuck in default spawn locations, and to get them closer to players quickly
			local specials_found = {}
			local function SP_dist_check(coords)
				local res = true
				for _, player in pairs(self:all_player_criminals()) do
					if mvector3.distance(player.unit:position(), coords) < 1200 then
						res = false
					end
				end
				return res
			end
			if chosen_player.unit and chosen_player.coords then
				local enemies = World:find_units_quick(chosen_player.unit, "sphere", chosen_player.coords, 6000, managers.slot:get_mask("enemies"))
				if enemies and #enemies > 0 then
					for i, enemy in pairs(enemies) do
						local enemy_chartweak = enemy:base():char_tweak()
						if enemy_chartweak.access == "tank" then
							if SP_dist_check(enemy:position()) then
								specials_found.tank = specials_found.tank or {}
								table.insert(specials_found.tank, enemy:position())
							end
						end
						if enemy_chartweak.access == "shield" then
							if SP_dist_check(enemy:position()) then
								specials_found.shield = specials_found.shield or {}
								table.insert(specials_found.shield, enemy:position())
							end
						end
						if enemy_chartweak.access == "spooc" then
							if SP_dist_check(enemy:position()) then
								specials_found.spooc = specials_found.spooc or {}
								table.insert(specials_found.spooc, enemy:position())
							end
						end
						if enemy_chartweak.access == "taser" then
							if SP_dist_check(enemy:position()) then
								specials_found.taser = specials_found.taser or {}
								table.insert(specials_found.taser, enemy:position())
							end
						end
					end
				end
			end
			
			-- pick a position from nearby special positions, or the default spot. if used a nearby special, remove that position and try another, to avoid them spawning inside of one another
			local function get_boss_spawn_point()
				local boss_spawn_point = DS_BW.Miniboss_info.spawn_locations[math.random(1,#DS_BW.Miniboss_info.spawn_locations)]
				local boss_position_found = false
				
				if specials_found.tank and #specials_found.tank >= 1 then
					local new_sp = specials_found.tank[math.random(1,#specials_found.tank)]
					boss_spawn_point = Vector3(new_sp.x,new_sp.y,new_sp.z)
					boss_position_found = true
					table.delete(specials_found.tank, boss_spawn_point)
				elseif specials_found.taser and #specials_found.taser >= 1 then
					local new_sp = specials_found.taser[math.random(1,#specials_found.taser)]
					boss_spawn_point = Vector3(new_sp.x,new_sp.y,new_sp.z)
					boss_position_found = true
					table.delete(specials_found.taser, boss_spawn_point)
				elseif specials_found.shield and #specials_found.shield >= 1 then
					local new_sp = specials_found.shield[math.random(1,#specials_found.shield)]
					boss_spawn_point = Vector3(new_sp.x,new_sp.y,new_sp.z)
					boss_position_found = true
					table.delete(specials_found.shield, boss_spawn_point)
				elseif specials_found.spooc and #specials_found.spooc >= 1 then
					local new_sp = specials_found.spooc[math.random(1,#specials_found.spooc)]
					boss_spawn_point = Vector3(new_sp.x,new_sp.y,new_sp.z)
					boss_position_found = true
					table.delete(specials_found.spooc, boss_spawn_point)
				end
				
				-- if no "on-enemy" position was found, fall back to original spawn point logic
				if not boss_position_found then
					local lowest_distance = 999999
						for j=1, #DS_BW.Miniboss_info.spawn_locations do
						local dist = mvector3.distance(chosen_player.coords, DS_BW.Miniboss_info.spawn_locations[j])
						if dist < lowest_distance then
							lowest_distance = dist
							boss_spawn_point = DS_BW.Miniboss_info.spawn_locations[j]
						end
					end
				end
				
				return boss_spawn_point
			end
			
			local function spawn_singular_boss(spawn_pos, target_unit)
				
				if not (spawn_pos and target_unit and alive(target_unit)) then
					log("[DS_BW] Did not spawn in a miniboss due to missing parameters! spawn_pos: "..tostring(spawn_pos)..", target_unit: "..tostring(target_unit))
					return false
				end
				
				local unit_str = Idstring("units/pd2_dlc_help/characters/ene_zeal_bulldozer_halloween/ene_zeal_bulldozer_halloween")
				local team = managers.groupai:state()._teams[tweak_data.levels:get_default_team_ID("combatant")]
				-- all possible highlight options: "generic_interactable" - yellow; "generic_interactable_selected" - white; "vulnerable_character" - basic red; "highlight_character" - used before, yellow
				local highlight_str = "generic_interactable_selected"
				
				local spawned_boss = World:spawn_unit(unit_str, spawn_pos, Rotation(180 - (360 / 10) * 1, 0, 0))
				
				spawned_boss:movement():set_team(team)
				spawned_boss:brain():set_logic("attack")
				spawned_boss:contour():add(highlight_str , true)
				
				local objective = {
					type = "follow",
					follow_unit = target_unit,
					scan = true,
					is_default = true,
					haste = "run",
					pose = "stand",
					forced = true,
					important = true,
				}
				spawned_boss:brain():set_objective(objective)
				
				return spawned_boss
			end
			
			-- spawn additional bosses with a tiny delay to avoid some potential spawn issues
			local spawned_boss_1 = spawn_singular_boss(get_boss_spawn_point(), chosen_player.unit)
			local spawned_boss_2 = false
			DelayedCalls:Add("DS_BW_add_2nd_mid_wave_boss", 0.1, function()
				
				-- re-roll target player for additional boss
				local plyrs = managers.groupai:state():all_player_criminals()
				if plyrs then
					local boss_target = plyrs[table.random_key(plyrs)]
					if boss_target and boss_target.unit and alive(boss_target.unit) then
						chosen_player.unit = boss_target.unit
						chosen_player.coords = boss_target.unit:position()
					end
				end
				spawned_boss_2 = spawn_singular_boss(get_boss_spawn_point(), chosen_player.unit)
				
				if spawned_boss_1 and spawned_boss_2 and alive(spawned_boss_1) and alive(spawned_boss_2) then
					if Utils:IsInGameState() and not DS_BW.end_stats_header_printed and self._task_data and self._task_data.assault and self._task_data.assault.phase == "sustain" then
						
						DS_BW.Miniboss_info.is_alive = true
						DS_BW.Miniboss_info.has_spawned_this_wave = true
						
						local dmg_resist_str = "50"
						
						-- only put full chat messages for first few appearances
						
						DS_BW.Miniboss_info.appearances = DS_BW.Miniboss_info.appearances + 1
						
						if DS_BW.kpm_tracker and DS_BW.kpm_tracker.penalties[1].is_perma then
							DS_BW.CM:public_chat_message("[DS_BW] Devil duo has arrived. Enjoy 75% global damage resistance x_x")
						else
							if DS_BW.Miniboss_info.appearances == 1 then
								dmg_resist_str = "33"
								DS_BW.CM:public_chat_message("[DS_BW] A new foe has appeared. Global enemy damage resistance of "..dmg_resist_str.."% is now in effect, until your foe is defeated. x_x")
							elseif DS_BW.Miniboss_info.appearances == 2 then
								DS_BW.CM:public_chat_message("[DS_BW] Devil duo has returned with "..dmg_resist_str.."% global enemy damage resistance this time x_x")
							elseif DS_BW.Miniboss_info.appearances == 3 then
								DS_BW.CM:public_chat_message("[DS_BW] Devil duo has returned. "..dmg_resist_str.."% global damage resistance is back x_x")
							elseif DS_BW.Miniboss_info.appearances >= 4 then
								DS_BW.CM:public_chat_message("[DS_BW] x_x")
							end
						end
						
					end
				end
				
			end)
			
		end
	end
end

-- adjust the "drama": controls assault pace:
-- prevent from going too high to almost never skip anticipation
-- prevent from going too low to make fade last as long as possible
local orig_drama = GroupAIStateBase._add_drama
Hooks:OverrideFunction(GroupAIStateBase, "_add_drama", function (self, amount)
	
	if DS_BW and DS_BW.DS_difficultycheck and self._task_data and self._task_data.assault then
		
		if Global.level_data and Global.level_data.level_id == "nmh" then
			
			-- make first 2 assauls on no mercy faster then other heists
			if self._assault_number <= 2 then
				if self._task_data.assault.phase == "anticipation" and self._drama_data.amount ~= 0.999 then
					self._drama_data.amount = 0.999
					amount = 0
				elseif self._task_data.assault.phase == "fade" and self._drama_data.amount ~= 0.01 then
					self._drama_data.amount = 0.01
					amount = 0
				elseif self._drama_data.amount + amount ~= 0.9 then
					self._drama_data.amount = 0.9
					amount = 0
				end
			else
				if self._task_data.assault.phase == "fade" and DS_BW.fade_started_prematurely then
					self._drama_data.amount = 0.01
					amount = 0
				elseif self._drama_data.amount + amount ~= 0.9 then
					self._drama_data.amount = 0.9
					amount = 0
				end
			end
			
		else
		
			if (not self._task_data.assault.phase or self._task_data.assault.phase == "anticipation") and self._assault_number == 0 then
				if self._drama_data.amount + amount ~= 0.99 then
					self._drama_data.amount = 0.99
					amount = 0
				end
			else
				if self._task_data.assault.phase == "fade" then
					if DS_BW.fade_started_prematurely or self._assault_number <= 1 then
						self._drama_data.amount = 0.01
						amount = 0
					else
						if self._drama_data.amount + amount ~= 0.9 then
							self._drama_data.amount = 0.9
							amount = 0
						end
					end
				elseif self._drama_data.amount + amount ~= 0.9 then
					self._drama_data.amount = 0.9
					amount = 0
				end
			end
			
		end
		
		-- update diff along with drama. in vanilla diff is only evaluated once, before wave starts.
		self:set_difficulty(1)
	end
	
	orig_drama(self, amount)
end)

-- disable smokes/flashbangs for the first wave, if heist is not 'fast paced'
local orig_detonate_world_smoke_grenade = GroupAIStateBase.detonate_world_smoke_grenade
Hooks:OverrideFunction(GroupAIStateBase, "detonate_world_smoke_grenade", function (self, id)
	if Network:is_server() and DS_BW.DS_difficultycheck and not DS_BW:is_hard_heist() and self._assault_number <= 1 then
		return
	end
	orig_detonate_world_smoke_grenade(self,id)
end)

-- adjust the "diff": controls chosen squads and their spawn chances using groupaitweakdata vars
local previous_phase = ""
local first_assault_update = false
local orig_diff = GroupAIStateBase.set_difficulty
Hooks:OverrideFunction(GroupAIStateBase, "set_difficulty", function (self, value)
	
	if not (DS_BW and DS_BW.DS_difficultycheck) then
		orig_diff(self, value)
		return
	end
	
	local heist_without_recon_1st_wave = DS_BW:is_hard_heist() or false
	
	-- assault 0 is everything before first assault's build phase
	if self._assault_number == 0  then
		value = 0.05
	elseif self._assault_number == 1 and not self._hunt_mode and not heist_without_recon_1st_wave then
		-- first x seconds of first assault have 0.1 diff, which spawns blue/green swats, after x secs we spawn grey and lighter zeal swats untill 1st wave ends
		if self._task_data.assault.phase == "sustain" and previous_phase == "build" then
			local diff_update_delay = 25
			if Global.level_data and Global.level_data.level_id == "nmh" then
				diff_update_delay = 15
			end
			DelayedCalls:Add("DS_BW_update_first_assault_diff_value", diff_update_delay, function()
				first_assault_update = true
			end)
		end
		
		if self._task_data.assault.phase ~= "anticipation" and not first_assault_update and value ~= 0.1 then
			value = 0.05
		elseif self._task_data.assault.phase ~= "anticipation" and first_assault_update and value ~= 0.5 then
			value = 0.5
		elseif self._task_data.assault.phase == "anticipation" and value ~= 1 then
			value = 1
		end
		
	else -- wave 2 and onward
		if self._task_data.assault.phase == "sustain" and previous_phase == "build" then
			DelayedCalls:Add("DS_BW_miniboss_spawn_delay", math.random(15,25), function()
				self:try_spawn_DSBW_miniboss()
			end)
		end
		-- make break in-between 1st and 2nd assault shorter if we are playing on heists without first easy assault, to make them a bit harder
		if heist_without_recon_1st_wave and self._assault_number == 1 and (self._task_data.assault.phase == "anticipation" or self._task_data.assault.phase == "fade") then
			value = 0.5
		elseif value ~= 1 then
			value = 1
		end
	end
	
	if self._task_data and self._task_data.assault and self._task_data.assault.phase then
		previous_phase = self._task_data.assault.phase
	end
	
	orig_diff(self, value)
end)

-- info tracking
Hooks:PostHook(GroupAIStateBase, "update", "DS_BW_GroupAIStateBase_update_post", function(self, t, dt)
	if DS_BW and DS_BW.DS_difficultycheck and self._task_data and self._task_data.assault then
		DS_BW.Assault_info.number = self._assault_number
		DS_BW.Assault_info.phase = (self._task_data and self._task_data.assault and self._task_data.assault.phase) or "unknown"
		DS_BW.Assault_info.is_infinite = self._hunt_mode
	end
end)

-- add more or change defeault cpt winters defense position(s)
Hooks:PostHook(GroupAIStateBase, "add_special_objective", "DS_BW_add_special_objective_post", function(self, id, objective_data)
	if objective_data.objective.type == "phalanx" and DS_BW and DS_BW.DS_difficultycheck then
		local new_cap_pos, vailla_cap_map = DS_BW:_new_captain_winters_position()
		if vailla_cap_map and new_cap_pos then
			self._phalanx_center_pos = new_cap_pos
		end
	end
end)

-- try to make cap shields be more agressive after he is gone
Hooks:PostHook(GroupAIStateBase, "unregister_phalanx_vip", "DS_BW_force_cap_shield_obj", function(self)
	
	if not (DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	
	--send every shield to player positions at random time intervals to be slighltly less annoying, and to try and avoid shield wall scenarios
	for u_key, u_data in pairs(managers.enemy:all_enemies()) do
		local unit = u_data.unit
		if unit and alive(unit) and unit:base() and unit:base():char_tweak() and unit:base():char_tweak().tags and table.contains(unit:base():char_tweak().tags, "DS_BW_tag_reinforced_shield") then
			unit:contour():remove("generic_interactable_selected", true) 
			DelayedCalls:Add("DS_BW_send_cap_shield_"..tostring(unit:id()).."_towards_player", math.random(1,45), function()
				if unit and alive(unit) and unit:brain() then
					unit:brain():set_logic("attack")
				end
			end)
		end
	end
	
end)

-- tracking for ASC
Hooks:PostHook(GroupAIStateBase, "on_enemy_registered", "DS_BW_GroupAIStateBase_on_enemy_registered_post", function(self, unit)
	
	if not (Network:is_server() and DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	
	if unit and unit:unit_data() then
		if not unit:unit_data()._DSBW_unit_spawned_at then
			unit:unit_data()._DSBW_unit_spawned_at = Application:time()
		end
	end
	
end)

-- ASC trigger
Hooks:PostHook(GroupAIStateBase, "on_enemy_unregistered", "DS_BW_GroupAIStateBase_on_enemy_unregistered_post", function(self, unit)
	
	if not (Network:is_server() and DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	
	-- if enemy is killed close enough to it's spawn point, disable it for a few secs
	local e_data = self._police[unit:key()]
	if e_data.assigned_area and unit:character_damage():dead() then
		local u_data = unit:unit_data()
		local spawn_point = u_data.mission_element
		if spawn_point then
			local spawn_pos = spawn_point:value('position')
			local u_pos = e_data.m_pos
			local function spawned_recently_enough() -- in case bots didnt move away from their spawn point quickly enough for some reason
				if u_data and u_data._DSBW_unit_spawned_at and (Application:time() - u_data._DSBW_unit_spawned_at) < 6 then
					return true
				else
					return false
				end
			end
			
			if mvector3.distance(spawn_pos, u_pos) < 1200 and math.abs(spawn_pos.z - u_pos.z) < 1000 and spawned_recently_enough() then
				DS_BW.ASC:triggered(unit, u_data._DSBW_unit_spawned_at) -- @ another file
				for area_id, area_data in pairs(self._area_data) do
					local area_spawn_groups = area_data.spawn_groups
					if area_spawn_groups then
						for _, sg_data in ipairs(area_spawn_groups) do
							if sg_data.spawn_pts then
								local spawn_point_id = spawn_point._id
								for _, sp in ipairs(sg_data.spawn_pts) do
									if sp.mission_element._id == spawn_point_id then
										local point_delay = 11
										if Global and Global.level_data and Global.level_data.level_id then
											 local SP_lockout_duration = {
												nmh = 3,
												flat = 6,
												bph = 3,
												man = 8,
												glace = 8,
												mia_2 = 8,
												chew = 5,
												nightclub = 9,
											 }
											 point_delay = SP_lockout_duration[Global.level_data.level_id] or 11
										end
										local delay_t = self._t + point_delay
										if delay_t > sg_data.delay_t and not sg_data.DSBW_temp_disabled then -- if SP is already blocked, dont block it again, cuz otherwise players would be able to manipulate delays for up to 20ish seconds if timed well enough. prob wouldnt be that broken in general, but some map's spawn points are just fucked beyond reason
											sg_data.delay_t = delay_t
											sg_data.DSBW_temp_disabled = true
											DelayedCalls:Add("DS_BW_reenable_sp_"..tostring(sg_data), point_delay + 1, function()
												if sg_data and sg_data.DSBW_temp_disabled then
													sg_data.DSBW_temp_disabled = nil
												end
											end)
										end
										return
									end
								end
							end
						end
					end -- arent loops fun?
				end
			end
		end
	end
	
end)