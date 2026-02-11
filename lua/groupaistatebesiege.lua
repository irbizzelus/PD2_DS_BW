if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

GroupAIStateBesiege._DS_BW_dmg_reduction = false

-- respawn rate adjustments
Hooks:PostHook(GroupAIStateBesiege, "init", "DS_BW_spawngroups", function(self)
	if not DS_BW.DS_difficultycheck then
		return
	end
	self._MAX_SIMULTANEOUS_SPAWNS = 4
end)

local assault_task_updates = 0
Hooks:PostHook(GroupAIStateBesiege, "_upd_assault_task", "DS_BW_updassault", function(self, ...)
	
	if not Network:is_server() then
		return
	end
	
	if not DS_BW.DS_difficultycheck then
		return
	end
	
	if self._spawning_groups and #self._spawning_groups >= 1 then
		assault_task_updates = assault_task_updates + 1
		for i=1, #self._spawning_groups do
			for _, sp in ipairs(self._spawning_groups[i].spawn_group.spawn_pts) do
				-- if cuurent phase is fade or regroup (for some reason its just nil nowadays) force longer respawn times
				-- by setting spawn delay on enemy spawn points every function trigger
				
				-- clear the table every few squad spawns, because sometiems heists may make certain spawn points inactive
				-- like when you move through heat streat for example, spawns at the begining should no longer be active
				if assault_task_updates >= 15 then
					assault_task_updates = 0
					DS_BW.Miniboss_info.spawn_locations = {}
				end
				-- add latest used spawn poistions, without dupes
				for j=1, #self._spawning_groups[i].spawn_group.spawn_pts do
					if not table.contains(DS_BW.Miniboss_info.spawn_locations, self._spawning_groups[i].spawn_group.spawn_pts[j].pos) then
						table.insert(DS_BW.Miniboss_info.spawn_locations,self._spawning_groups[i].spawn_group.spawn_pts[j].pos)
					end
				end
				
				if self._assault_number and self._assault_number >= 1 then
					if self._hunt_mode or (self._hunt_mode and self._phalanx_spawn_group and self._phalanx_spawn_group.has_spawned and self._dsbw_new_winter_penalty_applied) then -- make cpt. Winters and scripted endless assaults more painful
						if sp.interval and sp.interval > 0.5 then
							sp.interval = 0.5
						end
						if sp.delay_t then
							sp.delay_t = 0
						end
					elseif Global.level_data and Global.level_data.level_id == "nmh" then -- and as always, its special
						if self._task_data.assault.phase == "anticipation" then
							if sp.interval and sp.interval > 0.75 then
								sp.interval = 0.75
							end
							if sp.delay_t then
								sp.delay_t = 0
							end
						else
							if sp.interval then
								if DS_BW.Miniboss_info.is_alive and sp.interval ~= 1.75 then
									sp.interval = 1.75
								elseif sp.interval ~= 4 then
									sp.interval = 4
								end
							end
						end
					elseif not self._task_data.assault.phase or self._task_data.assault.phase == "fade" then -- disable spawns during fade and pre-anticipation nil phases
						if sp.interval and sp.interval < 10 then
							sp.interval = 10
						end
						if sp.delay_t then
							sp.delay_t = sp.delay_t + 20
						end
					elseif self._task_data.assault.phase == "anticipation" then -- spawn as much stuff as we can during anticipation
						if sp.interval and sp.interval > 1 then
							sp.interval = 1
						end
						if sp.delay_t then
							sp.delay_t = 0
						end
					else -- otherwise spawn slighlty faster then vanila, and slightly slower then vanila when boss is present
						if sp.interval and not sp.DSBW_temp_disabled then
							if DS_BW.Miniboss_info.is_alive and sp.interval ~= 3 then
								sp.interval = 3
							elseif sp.interval ~= 6 then
								sp.interval = 6
							end
						end
					end
				end
			end
		end
	end
	
	if not self._DS_BW_dmg_reduction then
		self:apply_DS_BW_dmg_reduction_loop()
	end
	
end)

-- add the 50% damage reduction every 10 seconds. this makes it active 24/7 regardless of other factors that might disable it
function GroupAIStateBesiege:apply_DS_BW_dmg_reduction_loop()
	
	-- stealth is ignored
	if managers.groupai:state():whisper_mode() then
		return
	end
	
	if not self._DS_BW_dmg_reduction then
		self._DS_BW_dmg_reduction = true
	end
	
	local force_pool = self:_get_difficulty_dependent_value(self._tweak_data.assault.force_pool) * self:_get_balancing_multiplier(self._tweak_data.assault.force_pool_balance_mul)
	local task_spawn_allowance = force_pool - ((self._hunt_mode and 0) or (self._task_data.assault.force_spawned or 0))
	if self._task_data.assault.phase == "fade" and task_spawn_allowance <= 0 then
		if not DS_BW.fade_started_prematurely and DS_BW._low_spawns_manager then
			DS_BW.fade_started_prematurely = true
			if (self._dsbw_cap_spawned_at_wave or -69) ~= DS_BW.Assault_info.number and DS_BW._low_spawns_manager.level <=2 then
				DS_BW._low_spawns_manager.level = DS_BW._low_spawns_manager.level + 1
				if DS_BW._low_spawns_manager.level > 5 then
					DS_BW._low_spawns_manager.level = 5
				end
				DS_BW._low_spawns_manager.detected_low = false
				DS_BW._low_spawns_manager.detected_high = false
				DS_BW._low_spawns_manager.adjustment_cooldown = Application:time()
				DS_BW.announce_adapt_diff()
			end
		end
	elseif self._task_data.assault.phase ~= "fade" then
		DS_BW.fade_started_prematurely = false
	end
	
	if self._task_data.assault.phase == "fade" then
		DelayedCalls:Add("DS_BW_despawn_captain_after_fade", 40, function()
			-- despawn cap if he hangs around for too long
			for u_key, u_data in pairs(managers.enemy:all_enemies()) do
				local unit = u_data.unit
				if unit and alive(unit) and unit:base() and unit:base():char_tweak() and unit:base():char_tweak().tags and table.contains(unit:base():char_tweak().tags, "DS_BW_tag_reinforced_shield_VIP") then
					World:delete_unit(unit)
					self:phalanx_despawned()
					log("[DS_BW] Despawned captain after fade, cause he hanged around for too long.")
					break
				end
			end
		end)
	end
	
	-- if our wanted dmg reduction is higher then this variable, game will try to increase it automaticaly to the max as if winters is alive. but since he isnt, game crashes.
	tweak_data.group_ai.phalanx.vip.damage_reduction.max = 0
	-- values slightly lower then 0.5 and 0.666 to avoid accidental damage breakpoint fuckery for everyone invloved, in case base games calculations round damage weirdly
	local dmg_resist_amount = 0
	if DS_BW.Miniboss_info.is_alive or DS_BW._dsbw_new_winter_penalty_applied_ang_going then
		dmg_resist_amount = 0.49
		if DS_BW.Miniboss_info.is_alive and not DS_BW._dsbw_new_winter_penalty_applied_ang_going then
			-- if DS_BW.Miniboss_info.appearances == 1 then
				-- dmg_resist_amount = 0.25
			-- end
			if DS_BW.Miniboss_info.appearances == 1 then
				dmg_resist_amount = 0.33
			end
		end
		if DS_BW.kpm_tracker and DS_BW.kpm_tracker.penalties[1].is_perma then
			dmg_resist_amount = 0.75
		end
	end
	
	if DS_BW._low_spawns_manager and DS_BW._low_spawns_manager.level and not DS_BW._dsbw_new_winter_penalty_applied_ang_going then
		-- max on the map
		tweak_data.group_ai.besiege.assault.force_balance_mul = {
			1 + DS_BW._low_spawns_manager.level * 0.25,
			1 + DS_BW._low_spawns_manager.level * 0.25,
			1 + DS_BW._low_spawns_manager.level * 0.25,
			1 + DS_BW._low_spawns_manager.level * 0.25
		}
		self._task_data.assault.force = math.ceil(self:_get_difficulty_dependent_value(self._tweak_data.assault.force) * self:_get_balancing_multiplier(self._tweak_data.assault.force_balance_mul))
		-- total per wave
		tweak_data.group_ai.besiege.assault.force_pool_balance_mul = {
			1 + DS_BW._low_spawns_manager.level * 0.15,
			1 + DS_BW._low_spawns_manager.level * 0.15,
			1 + DS_BW._low_spawns_manager.level * 0.15,
			1 + DS_BW._low_spawns_manager.level * 0.15
		}
		self._task_data.assault.force_pool = math.ceil(self:_get_difficulty_dependent_value(self._tweak_data.assault.force_pool) * self:_get_balancing_multiplier(self._tweak_data.assault.force_pool_balance_mul))
	end
	
	if dmg_resist_amount == 0 and DS_BW.kpm_tracker then
		-- host
		local law1team = self:_get_law1_team()
		local damage_reduction = DS_BW.kpm_tracker.penalties[1].amount or -1
		if law1team then
			if damage_reduction > 0 then
				law1team.damage_reduction = damage_reduction
			else
				law1team.damage_reduction = nil
			end
			self:set_damage_reduction_buff_hud()
		end
		if DS_BW.kpm_tracker.penalties[1].amount ~= DS_BW.kpm_tracker.penalties[1].was_notified_of then
			DS_BW.kpm_tracker.penalties[1].was_notified_of = DS_BW.kpm_tracker.penalties[1].amount
			local msg = "Your performance was just re-evaluated. All enemies now have "..tostring(DS_BW.kpm_tracker.penalties[1].amount * 100).."% damage resistance against you personally: /dmg"
			if DS_BW.kpm_tracker.penalties[1].amount == 0 then
				msg = "Your performance was just re-evaluated. Enemies no longer have any personal damage resistance against you."
			end
			DS_BW.CM:private_chat_message(1, msg)
		end
		-- clients
		for i=2,4 do
			local peer = managers.network:session() and managers.network:session():peer(i)
			if peer then
				peer:send_queued_sync("sync_damage_reduction_buff", DS_BW.kpm_tracker.penalties[i].amount)
				if DS_BW.kpm_tracker.penalties[i].amount ~= DS_BW.kpm_tracker.penalties[i].was_notified_of then
					DS_BW.kpm_tracker.penalties[i].was_notified_of = DS_BW.kpm_tracker.penalties[i].amount
					local msg = "[DSBW-Private message] Your performance was just re-evaluated. All enemies now have "..tostring(DS_BW.kpm_tracker.penalties[i].amount * 100).."% damage resistance against you personally: /dmg"
					if DS_BW.kpm_tracker.penalties[i].amount == 0 then
						msg = "[DSBW-Private message] Your performance was just re-evaluated. Enemies no longer have any personal damage resistance against you."
					end
					DS_BW.CM:private_chat_message(i, msg)
				end
			end
		end
	elseif dmg_resist_amount > 0 then
		self:set_phalanx_damage_reduction_buff(dmg_resist_amount)
	end
	
	-- for some reason, sometimes, mid-match, surrender values get reset to their defaults (hope its not one of my other mods)
	-- to avoid making player's life too easy we will make sure it does not happen, by making this check along with winter's dmg resist
	if tweak_data.character.zeal_swat.surrender.base_chance ~= 0.25 then
		DS_BW:update_surrender_tweak_data()
	end
	
	local escapes = {
		"escape_overpass",
		"escape_overpass_night",
		"escape_park",
		"escape_park_day",
		"escape_cafe",
		"escape_cafe_day",
		"escape_garage",
		"escape_street",
	}
	
	if Global.level_data and table.contains(escapes, Global.level_data.level_id)  then
		if not DS_BW.Assault_info.is_infinite then
			managers.groupai:state():set_wave_mode("hunt")
		end
	end
	
	-- if boss unit was not found while its supposed to be active, pop a message and update vars related to them.
	-- could happen during mission scripts that kill all enemies, for example beneeath the mountatin after going up the elevator zip line
	if DS_BW.Miniboss_info.is_alive then
		local is_boss_unit_found = false
		for u_key, u_data in pairs(managers.enemy:all_enemies()) do
			if u_data.unit:base():char_tweak().tags and table.contains(u_data.unit:base():char_tweak().tags, "DS_BW_tag_miniboss") then
				is_boss_unit_found = true
			end
		end
		if not is_boss_unit_found then
			DS_BW.Miniboss_info.is_alive = false
			DS_BW.Miniboss_info.kill_counter = 0
			self:set_phalanx_damage_reduction_buff(0)
			if not DS_BW.end_stats_header_printed then -- if bosses dissapear but we are at the game over screen, dont send messages
				DS_BW.CM:public_chat_message("[DS_BW] Devil duo is gone, global enemy damage resistance removed.")
			end
		end
	end
	
	DelayedCalls:Add("DS_BW_reapply_dmg_reduction", 3, function()
		self:apply_DS_BW_dmg_reduction_loop()
	end)
end

-- disallow captain spawn if devil duo is present for the first 3 waves
local DSBW_orig_check_spawn_phalanx = GroupAIStateBesiege._check_spawn_phalanx
Hooks:OverrideFunction(GroupAIStateBesiege, "_check_spawn_phalanx", function (self)
	if DS_BW and DS_BW.Miniboss_info and DS_BW.Miniboss_info.is_alive and DS_BW.Assault_info and DS_BW.Assault_info.number < 4 then
		return
	end
	DSBW_orig_check_spawn_phalanx(self)
end)

-- triggers new winters penalty after he reaches his position
Hooks:PostHook(GroupAIStateBesiege, "_upd_police_activity", "DS_BW_upd_police_activity_post", function(self)
	
	if not (DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	
	if self._phalanx_spawn_group and self._phalanx_spawn_group.has_spawned then
		local phalanx_vip = self:phalanx_vip()
		if phalanx_vip and alive(phalanx_vip) then
			self._winters_might_have_dissapeared_at = nil
			local dist = mvector3.distance(phalanx_vip:position(), self._phalanx_center_pos)
			if dist < 500 then
				local phalanx_minion_count = managers.groupai:state():get_phalanx_minion_count()
				local min_count_minions = tweak_data.group_ai.phalanx.minions.min_count
				if phalanx_minion_count > 0 and phalanx_minion_count > min_count_minions then
					self:DS_BW_new_winters_penalty(Application:time())
				else
					managers.groupai:state():unregister_phalanx_vip()
					managers.groupai:state():set_assault_endless(false)
				end
			end
		else
			-- for some reason self:phalanx_vip() does not report on winter's unit untill he gets close enough to his objective, so we make manual scans instead
			local winters_found = false
			for u_key, u_data in pairs(managers.enemy:all_enemies()) do
				local unit = u_data.unit
				if unit and alive(unit) and unit:base() and unit:base():char_tweak() and unit:base():char_tweak().tags and table.contains(unit:base():char_tweak().tags, "DS_BW_tag_reinforced_shield_VIP") then
					winters_found = true
				end
			end
			if not winters_found then
				if not self._winters_might_have_dissapeared_at then
					self._winters_might_have_dissapeared_at = Application:time()
				end
				if Application:time() - self._winters_might_have_dissapeared_at > 30 then
					-- remove endless assault if no vip is present. seems to happen sometimes on maps where cap doesnt normally appear
					log("[DS_BW] Force ended cpt. Winters' endless assault, because his unit was not detected during the \"_upd_police_activity\" function update.")
					managers.groupai:state():unregister_phalanx_vip()
					managers.groupai:state():set_assault_endless(false)
					self._winters_might_have_dissapeared_at = nil
				end
			end
		end
	else
		self._winters_might_have_dissapeared_at = nil
	end
end)

-- assign request time for the penalty, and activate it's loop
function GroupAIStateBesiege:DS_BW_new_winters_penalty(request_time)
	if not DS_BW._dsbw_new_winter_penalty_applied then
		DS_BW._dsbw_new_winter_penalty_applied = request_time
		self:DS_BW_new_winters_penalty_loop()
	end
end

-- runs 20 times a second. plays a voice line to remind of his presense every 15 seconds, untill his new penalty is in place.
function GroupAIStateBesiege:DS_BW_new_winters_penalty_loop()
	
	local phalanx_vip = self:phalanx_vip()
	if not (phalanx_vip and alive(phalanx_vip)) or (self._task_data and self._task_data.assault and (self._task_data.assault.phase ~= "build" and self._task_data.assault.phase ~= "sustain")) then
		managers.groupai:state():unregister_phalanx_vip()
		managers.groupai:state():set_assault_endless(false)
		return
	end
	
	local main_penalty_delay = 61
	if DS_BW._dsbw_new_winter_penalty_applied and (Application:time() - DS_BW._dsbw_new_winter_penalty_applied) > main_penalty_delay then
		tweak_data.group_ai.besiege.assault.force = {130,130,130}
		self._task_data.assault.force = math.ceil(self:_get_difficulty_dependent_value(self._tweak_data.assault.force) * self:_get_balancing_multiplier(self._tweak_data.assault.force_balance_mul))
		tweak_data.group_ai.special_unit_spawn_limits = {
			shield = 99,
			medic = 99,
			taser = 99,
			tank = 99,
			spooc = 99
		}
		for u_key, u_data in pairs(managers.enemy:all_enemies()) do
			local unit = u_data.unit
			if unit and alive(unit) and unit:base() and unit:base():char_tweak() and unit:base():char_tweak().tags and table.contains(unit:base():char_tweak().tags, "DS_BW_tag_reinforced_shield") then
				unit:contour():add("generic_interactable_selected", true)
			end
		end
		DS_BW.CM:public_chat_message("[DS_BW] Cpt. Winters has been present on the level for too long. Global enemy damage resistance of 50% is now in effect, enemies can now respawn much faster, and special enemies no longer have amount limits. Good luck.")
		DS_BW._dsbw_new_winter_penalty_applied_ang_going = true
		return
	end
	
	self._dsbw_cap_shouting_time = self._dsbw_cap_shouting_time or Application:time() + 15
	if Application:time() > self._dsbw_cap_shouting_time then
		phalanx_vip:sound():say("cpw_a01", true, true)
		self._dsbw_cap_shouting_time = Application:time() + 15
	end
	
	DelayedCalls:Add("DS_BW_winters_penalty_loop", 0.05, function()
		self:DS_BW_new_winters_penalty_loop()
	end)
end

-- define cap def position for maps that usualy dont spawn him
Hooks:PreHook(GroupAIStateBesiege, "_check_spawn_phalanx", "DS_BW_check_spawn_phalanx_post", function(self)
	if not self._phalanx_center_pos and DS_BW and DS_BW.DS_difficultycheck then
		local new_cap_pos, vailla_cap_map = DS_BW:_new_captain_winters_position()
		if new_cap_pos and not vailla_cap_map then
			self._phalanx_center_pos = new_cap_pos
		end
	end
end)

-- if current map normally doesnt spawn cpt. Winters, use new-ish logic to spawn him at newly created positions, if they are defined.
-- for heists that normally do spawn cap, and have new def positions for him, use vanilla logic
local dsbw_orig_besiege_phalanx_spawn = GroupAIStateBesiege._spawn_phalanx
Hooks:OverrideFunction(GroupAIStateBesiege, "_spawn_phalanx", function (self)
	if DS_BW and DS_BW.DS_difficultycheck then
		-- prevent cap spawn for the first x seconds of an assault
		if DS_BW.Assault_info and (DS_BW.Assault_info.phase ~= "sustain" or DS_BW.Assault_info.latest_starting_time + 180 > Application:time()) then
			return
		end
		
		-- prevent cap spawn if DSBW miniboss spawned this wave, but only for the first 2 waves, to make it a bit easier
		if DS_BW.Miniboss_info and DS_BW.Miniboss_info.has_spawned_this_wave and DS_BW.Assault_info.number <= 2 then
			return
		end
		
		local new_cap_pos, vailla_cap_map = DS_BW:_new_captain_winters_position()
		if new_cap_pos and not vailla_cap_map then
			
			if DS_BW:_new_captain_winters_spawn_should_be_prevented() then
				return
			end
			
			local phalanx_center_pos = self._phalanx_center_pos
			local phalanx_center_nav_seg = managers.navigation:get_nav_seg_from_pos(phalanx_center_pos)
			local phalanx_area = self:get_area_from_nav_seg_id(phalanx_center_nav_seg)
			local phalanx_group = {
				tac_shield_wall = {
					1,
					1,
					1
				}
			}

			if not phalanx_area then
				return
			end

			local spawn_group, spawn_group_type = self:_find_spawn_group_near_area(phalanx_area, phalanx_group, nil, nil, nil)

			if not spawn_group then
				return
			end
			
			spawn_group_type = "Phalanx"

			if spawn_group.spawn_pts[1] and spawn_group.spawn_pts[1].pos then
				local spawn_pos = spawn_group.spawn_pts[1].pos 
				local spawn_nav_seg = managers.navigation:get_nav_seg_from_pos(spawn_pos)
				local spawn_area = self:get_area_from_nav_seg_id(spawn_nav_seg)

				if spawn_group then
					local grp_objective = {
						type = "defend_area",
						area = spawn_area,
						nav_seg = spawn_nav_seg
					}

					self._phalanx_spawn_group = self:_spawn_in_group(spawn_group, spawn_group_type, grp_objective, nil)

					self:set_assault_endless(true)
					managers.game_play_central:announcer_say("cpa_a02_01")
					managers.network:session():send_to_peers_synched("group_ai_event", self:get_sync_event_id("phalanx_spawned"), 0)
					
					-- warn
					DS_BW.CM:public_chat_message("[DS_BW] Welcome, Cpt. Winters.")
					-- in case new spawns somehow break captain, disable endless wave few minutes after spawn
					self._dsbw_cap_spawned_at_wave = DS_BW.Assault_info.number
					DelayedCalls:Add("DS_BW_clear_winters_just_in_case", 240, function()
						if not DS_BW._dsbw_new_winter_penalty_applied_ang_going and DS_BW.Assault_info.number == self._dsbw_cap_spawned_at_wave and DS_BW.Assault_info.phase ~= nil and DS_BW.Assault_info.phase ~= "anticipation" then
							local mgs = managers.groupai:state()
							local phalanx_minion_count = mgs:get_phalanx_minion_count()
							local min_count_minions = tweak_data.group_ai.phalanx.minions.min_count
							if phalanx_minion_count > 0 and phalanx_minion_count <= min_count_minions then
								log("[DS_BW] Cleared captain's spawn via _spawn_phalanx DelayedCalls.")
								mgs:unregister_phalanx_vip()
								mgs:set_assault_endless(false)
							elseif phalanx_minion_count and phalanx_minion_count == 0 then
								log("[DS_BW] Cleared captain's spawn via _spawn_phalanx DelayedCalls.")
								mgs:unregister_phalanx_vip()
								mgs:set_assault_endless(false)
							end
							if not self:phalanx_vip() then
								log("[DS_BW] Cleared captain's spawn via _spawn_phalanx DelayedCalls.")
								mgs:unregister_phalanx_vip()
								mgs:set_assault_endless(false)
							end
						end
					end)
				end
			end
		else
			dsbw_orig_besiege_phalanx_spawn(self)
			if DS_BW and DS_BW.DS_difficultycheck then
				-- in case new spawns somehow break captain, disable endless wave few minutes after spawn
				self._dsbw_cap_spawned_at_wave = DS_BW.Assault_info.number
				DelayedCalls:Add("DS_BW_clear_winters_just_in_case", 180, function()
					if not DS_BW._dsbw_new_winter_penalty_applied_ang_going and DS_BW.Assault_info.number == self._dsbw_cap_spawned_at_wave and DS_BW.Assault_info.phase ~= nil and DS_BW.Assault_info.phase ~= "anticipation" then
						local mgs = managers.groupai:state()
						local phalanx_minion_count = mgs:get_phalanx_minion_count()
						local min_count_minions = tweak_data.group_ai.phalanx.minions.min_count
						if phalanx_minion_count > 0 and phalanx_minion_count <= min_count_minions then
							log("[DS_BW] Cleared captain's spawn via _spawn_phalanx DelayedCalls.")
							mgs:unregister_phalanx_vip()
							mgs:set_assault_endless(false)
						elseif phalanx_minion_count and phalanx_minion_count == 0 then
							log("[DS_BW] Cleared captain's spawn via _spawn_phalanx DelayedCalls.")
							mgs:unregister_phalanx_vip()
							mgs:set_assault_endless(false)
						end
						if not self:phalanx_vip() then
							log("[DS_BW] Cleared captain's spawn via _spawn_phalanx DelayedCalls.")
							mgs:unregister_phalanx_vip()
							mgs:set_assault_endless(false)
						end
					end
				end)
			end
		end
	else
		dsbw_orig_besiege_phalanx_spawn(self)
	end
end)

local function spawn_group_id(spawn_group)
	return spawn_group.mission_element:id()
end

local dsbw_orig_choose_group = GroupAIStateBesiege._choose_best_group
Hooks:OverrideFunction(GroupAIStateBesiege, "_choose_best_group", function (self, best_groups, total_weight)
	
	if not (DS_BW and DS_BW.DS_difficultycheck) then
		local res1, res2 = dsbw_orig_choose_group(self, best_groups, total_weight)
		return res1, res2
	end
	
	local rand_wgt = total_weight * math.random()
	local best_grp, best_grp_type = nil

	for i, candidate in ipairs(best_groups) do
		rand_wgt = rand_wgt - candidate.wght

		if rand_wgt <= 0 then
			
			-- player based respawn delays, ignoring bots. will most likely not feel extremely impactful due to other changes to enemy spawns in the mod,
			-- but making it a tad easier for 1-2 players was kinda needed
			local delay = 3
			local nr_players = 0
			for u_key, u_data in pairs(self:all_player_criminals()) do
				if not u_data.status then
					nr_players = nr_players + 1
				end
			end
			if nr_players <= 2 then
				if nr_players == 1 then
					delay = 8
				else
					delay = 5
				end
			end
			
			self._spawn_group_timers[spawn_group_id(candidate.group)] = TimerManager:game():time() + delay

			best_grp = candidate.group
			best_grp_type = candidate.group_type
			best_grp.delay_t = self._t + best_grp.interval

			break
		end
	end

	return best_grp, best_grp_type
end)