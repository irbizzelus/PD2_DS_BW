if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

-- prevent drama from goin over 95 so we never skip anticipation, except for very first wave. reason: longer breaks
-- also some track's anticipation music is 11/10, yet i almost never hear it because of this useless (gameplay wise) mechanic
-- also prevent drama from beeing too low to make fade last as long as possible, thanks to update 181, this is not exploitable and gives 1 minute of free time during fade at best
local orig_drama = GroupAIStateBase._add_drama
function GroupAIStateBase:_add_drama(amount)
	
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
		
		-- tracking info
		DS_BW.Assault_info.number = self._assault_number
		DS_BW.Assault_info.phase = (self._task_data and self._task_data.assault and self._task_data.assault.phase) or "unknown"
		DS_BW.Assault_info.is_infinite = self._hunt_mode
		
		-- update diff along with drama. in vanilla diff is only evaluated once, before wave starts.
		self:set_difficulty(1)
	end
	
	orig_drama(self, amount)
end

local orig_detonate_world_smoke_grenade = GroupAIStateBase.detonate_world_smoke_grenade
function GroupAIStateBase:detonate_world_smoke_grenade(id)
	-- disable smokes/flashbangs for the first wave, if heist is not 'fast paced'
	if DS_BW.DS_difficultycheck == true and not DS_BW.is_hard_heist() and self._assault_number <= 1 then
		return
	end
	orig_detonate_world_smoke_grenade(self,id)
end

function GroupAIStateBase:_DSBW_try_spawn_miniboss()
	
	if not (DS_BW and DS_BW.Assault_info) then
		return
	end
	
	local function is_boss_spawn_allowed()
		local result = false
		local assault_num = DS_BW.Assault_info.number
		
		-- always spawn if first assault is endless. begin to gamble on 1st assault if its a fast heist, otherwise start to gamble on 2nd
		if assault_num == 1 and self._hunt_mode then
			return true
		elseif Global.level_data and Global.level_data.level_id and DS_BW.is_hard_heist() then
			if assault_num >= 2 then
				result = true
			end
		else
			if assault_num >= 3 then
				result = true
			end
		end
		
		if result then
			if DS_BW._low_spawns_manager and DS_BW._low_spawns_manager.level then
				DS_BW.Miniboss_info.spawn_chance.current = DS_BW.Miniboss_info.spawn_chance.current + (DS_BW._low_spawns_manager.level * 0.05) -- adapt. diff level increase always goes through
			end
			if DS_BW.Miniboss_info.spawn_chance.current > 0.9 then
				DS_BW.Miniboss_info.spawn_chance.current = 0.9
			end
			local rng_success = math.random() <= DS_BW.Miniboss_info.spawn_chance.current
			log("[DS_BW] Rolled boss spawn chance against: "..tostring(DS_BW.Miniboss_info.spawn_chance.current * 100).."%, success: "..tostring(rng_success))
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
			local spawned_boss_3 = false
			DelayedCalls:Add("DS_BW_add_2nd_mid_wave_boss", 0.3, function()
				
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
				
				DelayedCalls:Add("DS_BW_add_3rd_mid_wave_boss", 0.3, function()
					
					-- local plrs = managers.groupai:state():all_player_criminals()
					-- if plrs then
						-- local boss_target = plrs[table.random_key(plrs)]
						-- if boss_target and boss_target.unit and alive(boss_target.unit) then
							-- chosen_player.unit = boss_target.unit
							-- chosen_player.coords = boss_target.unit:position()
						-- end
					-- end
					-- spawned_boss_3 = spawn_singular_boss(get_boss_spawn_point(), chosen_player.unit)
					
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
								-- elseif DS_BW.Miniboss_info.appearances == 1 then
									-- dmg_resist_str = "33"
									-- DS_BW.CM:public_chat_message("[DS_BW] Devil trio has returned with "..dmg_resist_str.."% global enemy damage resistance this time x_x")
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
				
			end)
			
		end
	end
end

-- adjust the "diff": controls assault pace and chosen squads and their spawn chances using groupaitweakdata vars
local previous_phase = ""
local first_assault_update = false
local orig_diff = GroupAIStateBase.set_difficulty
function GroupAIStateBase:set_difficulty(value)
	
	if not (DS_BW and DS_BW.DS_difficultycheck) then
		orig_diff(self, value)
		return
	end
	
	-- most heists have an easier starting first assault, that will also include easier difficulty units, to create a "easier units are scouting and getting rekt before badass guys enter" thing
	-- some heists where it logicaly makes no sense for there to be a lighter 'recon' assaul (for example alaska) will have no super easy first assault, but still a slightly easier one
	-- no mercy is 1 exception that uses ultra quick first 2 assaults to improve spawns
	
	-- _assault_number counter updates during the build phase, which comes right after anticipation
	-- this makes anticipation effectively the end of the previous wave, instead of being a begining of the new one
	
	local heist_without_recon_1st_wave = false
	if DS_BW.is_hard_heist() then
		heist_without_recon_1st_wave = true
	end
	
	-- track build phase start time for cpt. winters
	if self._task_data and self._task_data.assault and (self._task_data.assault.phase == "build" or (self._task_data.assault.phase == "sustain" and previous_phase == "build")) then
		DS_BW.Assault_info.latest_starting_time = Application:time()
	end
	
	-- assault 0 is everything before first assault's build phase
	if self._assault_number == 0  then
		value = 0.05
	elseif self._assault_number == 1 and not self._hunt_mode and not heist_without_recon_1st_wave then
		
		-- first assault of a standard heist
		
		-- first x seconds of first assault have 0.1 diff, which spawns blue/green swats
		-- after x secs we spawn grey and lighter zeal swats untill 1st wave ends
		-- wave 2 and onward is full power
		if self._task_data.assault.phase == "sustain" and previous_phase == "build" then
			local diff_update_delay = 25
			-- why am i making this heist so special
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
				self:_DSBW_try_spawn_miniboss()
			end)
		end
		-- make break in-between 1st and 2nd assault shorter if we are playing on heists without first easy assault, to make them a bit harder. this shortens enemy respawn delay by about 30sec
		if heist_without_recon_1st_wave and self._assault_number == 1 and (self._task_data.assault.phase == "anticipation" or self._task_data.assault.phase == "fade") then
			value = 0.5
		elseif value ~= 1 then
			value = 1
		end
	end
	
	if self._task_data and self._task_data.assault and self._task_data.assault.phase then
		if self._task_data.assault.phase == "fade" then
			-- clear minigboss info on fade
			DS_BW.Miniboss_info.has_spawned_this_wave = false -- only used for cpt. Winters check, so clearing at fade is safe, adjust later if needed
			if DS_BW.Miniboss_info.is_alive then
				DS_BW.Miniboss_info.is_alive = false
				DS_BW.Miniboss_info.kill_counter = 0
				managers.groupai:state():set_phalanx_damage_reduction_buff(0)
				for u_key, u_data in pairs(managers.enemy:all_enemies()) do
					if u_data.unit:base():char_tweak().tags and table.contains(u_data.unit:base():char_tweak().tags, "DS_BW_tag_miniboss") then
						if u_data.unit:character_damage().damage_mission then
							u_data.unit:character_damage():damage_mission({
								forced = true,
								col_ray = {}
							})
						end
					end
				end
				DS_BW.CM:public_chat_message("[DS_BW] Assault is fading - devil duo and global damage resistance are now gone. Catch a break while you can.")
			else
				if previous_phase ~= "fade" and DS_BW.Assault_info.number >= 2 then
					DS_BW.CM:public_chat_message("[DS_BW] Assault is fading - clear and move up.")
				end
			end
			-- whenever winters "dies" assault fades, so we reset his penalties
			if DS_BW._dsbw_new_winter_penalty_applied then
				DS_BW._dsbw_new_winter_penalty_applied = nil
				DS_BW._dsbw_new_winter_penalty_applied_ang_going = nil
				tweak_data.group_ai.besiege.assault.force = DS_BW.base_groupaitweak_values.assault_force
				tweak_data.group_ai.special_unit_spawn_limits = DS_BW.base_groupaitweak_values.special_limits
			end
			-- clear a delayed call responsible for removing endless assault in case winters breaks somehow. normally its activated 3-4 minutes after cap spawns
			-- and checks if he is still existent, and if not, disables endless assault if its currently endless. problem is that some maps have scripted endless waves
			-- and they dont seem to have different flags, so this should hopefuly prevent scripted endless assaults getting stopped by this safety call
			DelayedCalls:Add("DS_BW_clear_winters_just_in_case", 0, function()
				-- nada
			end)
		end
		previous_phase = self._task_data.assault.phase
	end
	orig_diff(self, value)
end

-- returns 2 vars, first is the new position, and the second is reporting if the map has cpt in vanilla or not
function DS_BW:_new_captain_winters_position()
	-- new location for cpt.winters for maps that by default spawn cap
	local new_vanilla_phalanx_positions = {
		alex_1 = { -- Hector: Rats 1
			Vector3(421, -1194, 869),
		},
		rat = { -- Bain: Cook off
			Vector3(421, -1194, 869),
		},
		wwh = { -- Locke: alaska
			Vector3(6010, -1125, 1352),
			Vector3(5055, 5660, 1223),
		},
		big = { -- Dentist: big bank
			Vector3(1155, 2031, 227),
		},
		pal = { -- Classics: counterfeit
			Vector3(-101, 10.8, 23),
			Vector3(-6017, 5072, 41),
		},
		mus = { -- Dentist: diamond
			Vector3(-4729, -944, -994),
			Vector3(-4415, 2693.5, -940.5),
		},
		mia_1 = { -- Dentist: hotline miami day 1
			Vector3(-3389.5, -3234, 2),
		},
		branchbank = { -- Bain: bank (all of em)
			Vector3(-7207.5, -3980.5, -7),
		},
		family = { -- Bain: diamond store
			Vector3(-622, 3783, -17.5),
			Vector3(-2929, -3753, -18),
		},
		election_day_1 = { -- Elephant
			Vector3(4853.3, -3006.8, 2),
			Vector3(5466.6, 2822.9, 102),
			Vector3(60.4, -1827.9, 2),
		},
		welcome_to_the_jungle_1 = { -- Elephant: big oil 1
			Vector3(46629.5, -7538.8, -20),
			Vector3(7210.8, -2220, -20),
		},
		welcome_to_the_jungle_2 = { -- Elephant: big oil 2
			Vector3(-5226.5, -2667.5, -3),
			Vector3(-5560.5, 5066.8, 68),
		},
	}
	-- positions for cap for maps that normally don't spawn him
	local new_phalanx_positions = {
		roberts = { -- go bank
			Vector3(2184, -4525, -64),
		},
		red2 = { -- FWB
			Vector3(-4271, -2011, -123),
		},
		glace = { -- Green bridge
			Vector3(-1323, -17519, 5804),
		},
		nmh = { -- No Mercy
			Vector3(2829, 427, 2),
		},
		brb = { -- Brooklyn bank
			Vector3(4200, -3090, -16),
			Vector3(-298, 418, 7),
		},
		dah = { -- Classics: diamonds
			Vector3(-1095, -420, 777),
		},
		flat = { -- Classics: panic room
			Vector3(-3288, -36, -22),
		},
		man = { -- Classics: undercover
			Vector3(-837, -794, 1709),
		},
		run = { -- Classics: heat street
			Vector3(-8293, -4926, 40),
		},
		mia_2 = { -- Dentist: hotline miami day 2
			Vector3(140, -101, -5),
		},
		rvd1 = { -- Bain: Reserviour dogs day 1 (canonical 2nd)
			Vector3(-9, 3168.5, 2),
		},
		rvd2 = { -- Bain: Reserviour dogs day 2 (canonical 1st)
			Vector3(963, 4925.5, -18),
		},
		trai = { -- McShay: Train
			Vector3(3145, -126, -9),
		},
		watchdogs_2 = { -- Hector
			Vector3(-2503.5, 168.8, 2),
		},
		watchdogs_2_day = { -- Hector
			Vector3(-2503.5, 168.8, 2),
		},
		sah = { -- Locke: auction
			Vector3(1459.2, -2260.6, -95),
			Vector3(-2318.9, -608.6, -143),
		},
		born = { -- Dentist: biker heist 1
			Vector3(1248.5, 2589.5, 2),
		},
		arm_for = { -- Bain: transport: train
			Vector3(-3961.7, -7422.1, -887),
		},
		friend = { -- Butcher: sosa
			Vector3(8245.2, -3133.6, -775),
			Vector3(3600.8, 5207.5, -147),
		},
		crojob3 = { -- Butcher: forest
			Vector3(6426.1, -11229.2, 1419),
			Vector3(1452.7, 6982, 5243),
		},
		kenaz = { -- Dentist: grin casino
			Vector3(1554, -10124, -395),
			Vector3(-4285.5, -4785.3, -98),
		},
		chca = { -- Vlad: Black cat
			Vector3(-9310, 16997.3, 102),
		},
		four_stores = { -- Vlad
			Vector3(2772.1, -1541.4, 27),
		},
		mallcrasher = { -- Vlad
			Vector3(2594, 1746.8, -413),
		},
		nightclub = { -- Vlad
			Vector3(-1340.1, -3204.5, 7),
		},
		-- NON AMERICAN FACTION: game force despawns captain W, but not his shields, whenever his spawn is triggered on these maps. if i adjust this, these maps can be re-enabled
		-- bex = { -- Vlad: san martin
			-- Vector3(-0.4, 3102.3, -11),
			-- Vector3(-2444.2, -1327.2, -11),
		-- },
		-- des = { -- Locke: henry's crock
			-- Vector3(-968.8, 726, 2),
		-- },
		-- fex = { -- Vlad: Buluc
			-- Vector3(414.5, -3454.5, -189),
		-- },
	}
	
	if Global and Global.level_data and new_vanilla_phalanx_positions[Global.level_data.level_id] then
		return new_vanilla_phalanx_positions[Global.level_data.level_id][math.random(1,#new_vanilla_phalanx_positions[Global.level_data.level_id])], true
	elseif Global and Global.level_data and new_phalanx_positions[Global.level_data.level_id] then
		return new_phalanx_positions[Global.level_data.level_id][math.random(1,#new_phalanx_positions[Global.level_data.level_id])], false
	else
		return nil, nil
	end
end

-- check for whatever preventions maps with custom winters spawns may have. currently only limits by wave number
function DS_BW:_new_captain_winters_spawn_should_be_prevented()
	
	-- min wave number at which he can spawn
	local min_assault_number = {
		run = 2,
		mia_2 = 2,
		des = 2,
	}
	
	if Global and Global.level_data and min_assault_number[Global.level_data.level_id] then
		return min_assault_number[Global.level_data.level_id] > DS_BW.Assault_info.number
	else
		return false
	end
end

-- add more or change defeault cpt winters defense position
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
				if u_data and u_data._DSBW_unit_spawned_at and (Application:time() - u_data._DSBW_unit_spawned_at) < 10 then
					return true
				else
					return false
				end
			end
			if mvector3.distance(spawn_pos, u_pos) < 500 and math.abs(spawn_pos.z - u_pos.z) < 300 and spawned_recently_enough() then
				for area_id, area_data in pairs(self._area_data) do
					local area_spawn_groups = area_data.spawn_groups
					if area_spawn_groups then
						for _, sg_data in ipairs(area_spawn_groups) do
							if sg_data.spawn_pts then
								local spawn_point_id = spawn_point._id
								for _, sp in ipairs(sg_data.spawn_pts) do
									if sp.mission_element._id == spawn_point_id then
										local point_delay = 10.5
										if Global.level_data and Global.level_data.level_id == "nmh" then
											point_delay = 4
										end
										if Global.level_data and Global.level_data.level_id == "flat" then
											point_delay = 7
										end
										local delay_t = self._t + point_delay
										if delay_t > sg_data.delay_t and not sg_data.DSBW_temp_disabled then -- if SP is already blocked, dont block it again, cuz otherwise players would be able to manipulate delays for up to 20ish seconds if timed well enough. prob wouldnt be that broken in general, but some map's spawn points are just fucked beyond reason
											sg_data.delay_t = delay_t
											sg_data.DSBW_temp_disabled = true
											DelayedCalls:Add("DS_BW_reenable_sp_"..tostring(sg_data), point_delay + 0.5, function()
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
					end
				end
			end
		end
	end
	
end)