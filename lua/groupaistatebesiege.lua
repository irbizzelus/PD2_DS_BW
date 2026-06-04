if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

Hooks:PostHook(GroupAIStateBesiege, "init", "DS_BW_spawngroups", function(self)
	if not DS_BW.DS_difficultycheck then
		return
	end
	self._MAX_SIMULTANEOUS_SPAWNS = 6
end)

-- speed up enemy respawns globaly
local dsbw_orig_besiege_queue_police_upd_task = GroupAIStateBesiege._queue_police_upd_task
Hooks:OverrideFunction(GroupAIStateBesiege, "_queue_police_upd_task", function (self)
	
	if not (Network:is_server() and DS_BW.DS_difficultycheck) then
		dsbw_orig_besiege_queue_police_upd_task(self)
		return
	end
	
	-- ty
	self:DS_BW_updates()
	
	if not DS_BW.adu_running then
		DS_BW:ADU_Update()
	end
	
	local ADL_multipliers = {
		[0] = 0.25,
		[1] = 1,
		[2] = 0.8,
		[3] = 0.66,
		[4] = 0.5,
		[5] = 0.5,
	}
	local update_multiplier = ADL_multipliers[DS_BW._low_spawns_manager.level] or 1
	
	if DS_BW.Miniboss_info.is_alive then
		update_multiplier = update_multiplier * 0.7
	end
	if managers.groupai:state() and managers.groupai:state()._hunt_mode then
		update_multiplier = update_multiplier * 0.85
	end
	
	if not self._police_upd_task_queued then
		self._police_upd_task_queued = true

		managers.enemy:queue_task("GroupAIStateBesiege._upd_police_activity", self._upd_police_activity, self, self._t + (next(self._spawning_groups) and 0.5 or 2) * update_multiplier)
	end
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
				
				-- clear miniboss spawn locations table every few squad spawns, because sometiems heists may make certain spawn points inactive
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
				
				-- if cuurent phase is fade or pre-anticipation regroup force no spawns
				if self._assault_number and self._assault_number >= 1 then
					if not self._task_data.assault.phase or self._task_data.assault.phase == "fade" or sp.DSBW_temp_disabled then
						if sp.interval and sp.interval < 10 then
							sp.interval = 10
						end
						if sp.delay_t then
							sp.delay_t = sp.delay_t + 20
						end
					else -- otherwise no delays
						if sp.interval and sp.interval > 0 then
							sp.interval = 0
						end
						if sp.delay_t then
							sp.delay_t = 0
						end
					end
				end
			end
		end
	end
	
end)

local previous_phase = ""
local updater_rate = -1
function GroupAIStateBesiege:DS_BW_updates()
	
	-- stealth is ignored
	if self:whisper_mode() then
		return
	end
	
	-- we dont need this function to update every frame, thx
	if not (Application:time() > (updater_rate + 0.02)) then
		return
	end
	updater_rate = Application:time()
	
	local LSM = DS_BW._low_spawns_manager
	
	-- on fade checks
	local was_AD_updated = false
	if self._task_data.assault.phase == "fade" then
		
		if LSM.current_wave_was_extended then
			LSM.current_wave_was_extended = nil
		end
		if LSM.prevent_total_pool_updates_this_wave then
			LSM.prevent_total_pool_updates_this_wave = nil
		end
		
		-- remember current ADL progression to reset it on new wave start, otherwise we'd get free progress during regroup phases
		if LSM.detected_low and not LSM.detected_low_to_remember then
			LSM.detected_low_to_remember = Application:time() - LSM.detected_low
		end
		if LSM.detected_high and not LSM.detected_high_to_remember then
			LSM.detected_high_to_remember = Application:time() - LSM.detected_high
		end
		
		-- if full wave is about to begin, force lvl 1
		if LSM.level == 0 and ((DS_BW.Assault_info.number == 1 and DS_BW:is_hard_heist()) or DS_BW.Assault_info.number >= 2) then
			LSM.detected_low = false
			LSM.detected_high = false
			LSM.adjustment_cooldown = Application:time()
			LSM.level = 1
			was_AD_updated = true
		end
		
		-- check if fade phase was triggered by empty'ing the spawn pool
		local force_pool = self:_get_difficulty_dependent_value(self._tweak_data.assault.force_pool) * self:_get_balancing_multiplier(self._tweak_data.assault.force_pool_balance_mul)
		local task_spawn_allowance = force_pool - ((self._hunt_mode and 0) or (self._task_data.assault.force_spawned or 0))
		if task_spawn_allowance <= 0 and not DS_BW.fade_started_prematurely then
			DS_BW.fade_started_prematurely = true
			if (self._dsbw_cap_spawned_at_wave or -69) ~= DS_BW.Assault_info.number and LSM.level <=2 then
				LSM.level = LSM.level + 1
				if LSM.level > 5 then
					LSM.level = 5
				end
				LSM.detected_low = false
				LSM.detected_high = false
				LSM.adjustment_cooldown = Application:time()
				LSM.detected_low_to_remember = nil -- prevent levels from immeidately going up or down after new assault begins
				LSM.detected_high_to_remember = nil
				was_AD_updated = true
			end
		end
		
		local wave_end_msg = false
		
		-- reset minibosss
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
			wave_end_msg = "[DS_BW] Assault is fading - devil duo and global damage resistance are now gone. Catch a break while you can."
		end
		
		-- reset winters penalties
		if DS_BW._dsbw_new_winter_penalty_applied then
			DS_BW._dsbw_new_winter_penalty_applied = nil
			DS_BW._dsbw_new_winter_penalty_applied_ang_going = nil
			tweak_data.group_ai.besiege.assault.force = DS_BW.base_groupaitweak_values.assault_force
			tweak_data.group_ai.special_unit_spawn_limits = DS_BW.base_groupaitweak_values.special_limits
		end
		DelayedCalls:Add("DS_BW_clear_winters_just_in_case", 0, function()
			-- clear a delayed call responsible for removing endless assault in case winters breaks somehow
		end)
		
		if previous_phase ~= "fade" then
			DelayedCalls:Add("DS_BW_despawn_captain_after_fade", 40, function()
				-- despawn cap if he hangs around for too long after fade
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
		
		-- assault end chat message
		if previous_phase ~= "fade" then
			if was_AD_updated then
				DS_BW:announce_adapt_diff("early_fade")
				if wave_end_msg then -- dont forget devil warning msg
					DS_BW.CM:public_chat_message("[DS_BW] Devil duo and global damage resistance are now gone.")
				end
			else
				if DS_BW.Assault_info.number >= 2 and not wave_end_msg then
					wave_end_msg = "[DS_BW] Assault is fading."
				end
				DS_BW.CM:public_chat_message(wave_end_msg)
			end
		end
		
	else
		DS_BW.fade_started_prematurely = false
	end
	
	previous_phase = self._task_data.assault.phase
	
	if self:is_AI_enabled() and self:enemy_weapons_hot() then
		-- add the damage reduction to make it active 24/7 regardless of factors that might disable it
		tweak_data.group_ai.phalanx.vip.damage_reduction.max = 0 -- if our wanted dmg reduction is higher then this variable, game will try to increase it automaticaly to the max as if winters is alive. but since he isnt, game crashes.
		local dmg_resist_amount = 0
		if DS_BW.Miniboss_info.is_alive or DS_BW._dsbw_new_winter_penalty_applied_ang_going then
			dmg_resist_amount = 0.49
			if DS_BW.Miniboss_info.is_alive and not DS_BW._dsbw_new_winter_penalty_applied_ang_going then
				if DS_BW.Miniboss_info.appearances == 1 then
					dmg_resist_amount = 0.33
				end
			end
			if DS_BW.kpm_tracker and DS_BW.kpm_tracker.penalties[1].is_perma then
				dmg_resist_amount = 0.75
			end
		end
		
		if dmg_resist_amount == 0 then -- if no cap/miniboss is present, check for ADL resistances
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
		
		-- make escape days perma-infinite
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
		if Global.level_data and table.contains(escapes, Global.level_data.level_id) then
			if not DS_BW.Assault_info.is_infinite then
				managers.groupai:state():set_wave_mode("hunt")
			end
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
			
			DelayedCalls:Add("DS_BW_Announce_Boss_Despawn", 5, function()
				local function should_notify()
					if not (DS_BW and DS_BW.CM) then
						return false
					end
					local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
					if not (hud and hud.panel:child("chat_panel")) then
						return false
					end
					if not (self._task_data and self._task_data.assault) then
						return false
					end
					if self._task_data.assault.is_first and self._task_data.assault.disabled then -- if game ends by restarting, these get reset to defaults
						return false
					end
					if DS_BW.end_stats_header_printed then -- game over screen
						return false
					end
					return true
				end
				
				if should_notify() then 
					DS_BW.CM:public_chat_message("[DS_BW] Devil duo is gone - global enemy damage resistance removed.")
				end
			end)
		end
	end
	
end

-- disallow captain spawn if devil duo is alive for the first 3 waves
local DSBW_orig_check_spawn_phalanx = GroupAIStateBesiege._check_spawn_phalanx
Hooks:OverrideFunction(GroupAIStateBesiege, "_check_spawn_phalanx", function (self)
	if DS_BW and DS_BW.Miniboss_info and DS_BW.Miniboss_info.is_alive and DS_BW.Assault_info and DS_BW.Assault_info.number < 4 then
		return
	end
	DSBW_orig_check_spawn_phalanx(self)
end)

-- new winters penalty enabler
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
		DS_BW._dsbw_new_winter_penalty_applied_ang_going = true
		for u_key, u_data in pairs(managers.enemy:all_enemies()) do
			local unit = u_data.unit
			if unit and alive(unit) and unit:base() and unit:base():char_tweak() and unit:base():char_tweak().tags and table.contains(unit:base():char_tweak().tags, "DS_BW_tag_reinforced_shield") then
				unit:contour():add("generic_interactable_selected", true)
			end
		end
		DS_BW.CM:public_chat_message("[DS_BW] Cpt. Winters has been present on the level for too long. Global enemy damage resistance of 50% is now in effect, enemies can now respawn much faster, and special enemies no longer have amount limits. Good luck.")
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
		-- prevent cap spawn untill the very end of an assault
		if DS_BW.Assault_info and ( DS_BW.Assault_info.phase ~= "sustain" or (self._task_data.assault.phase_end_t and (self._task_data.assault.phase_end_t - Application:time()) > 60) ) then
			return
		end
		
		-- prevent cap spawn if DSBW miniboss spawned this wave, but only for the first 3 waves, to make it a bit easier
		if DS_BW.Miniboss_info and DS_BW.Miniboss_info.has_spawned_this_wave and DS_BW.Assault_info.number <= 3 then
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

-- adjust individual enemy respawn speeds
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
			
			-- player based respawn delay mul, ignoring bots
			local player_mul = 1
			local nr_players = 0
			for u_key, u_data in pairs(self:all_player_criminals()) do
				if not u_data.status then
					nr_players = nr_players + 1
				end
			end
			
			if nr_players == 1 then
				player_mul = 3
			elseif nr_players == 2 then
				player_mul = 1.4
			end
			
			-- adaptive diff mul
			local adl_muls = {
				[1] = 1,
				[2] = 0.9,
				[3] = 0.75,
				[4] = 0.55,
				[5] = 0.3,
			}
			local adl_mul = adl_muls[DS_BW._low_spawns_manager.level] or 1
			
			-- individual squad spawn delays
			local squad_delays = {
				Squad_Light_1 = 0,
				Squad_Light_2 = 0,
				Squad_Light_3 = 0,
				tac_swat_rifle_flank = 0.5, -- Squad_Heavy_1
				Squad_Heavy_2 = 0.5,
				Squad_Heavy_3 = 0.5,
				tac_tazer_flanking = 6, -- Squad_Medic
				tac_shield_wall = 4, -- Squad_Shield
				tac_tazer_charge = 4, -- Squad_Tazer
				tac_bull_rush = 8, -- Squad_Tank
				Squad_Tank_Annoying = 12,
				FBI_spoocs = 7,
				single_spooc = 7,
			}
			local delay = squad_delays[tostring(candidate.group_type)] or 1
			self._spawn_group_timers[spawn_group_id(candidate.group)] = TimerManager:game():time() + delay * player_mul * adl_mul

			best_grp = candidate.group
			best_grp_type = candidate.group_type
			best_grp.delay_t = self._t + best_grp.interval

			break
		end
	end

	return best_grp, best_grp_type
end)

-- after smoke is used increase flash/smoke CD by 2x to reduce smoke spam, while keeping flashbang spam
local dsbw_orig_chk_group_use_smoke_grenade = GroupAIStateBesiege._chk_group_use_smoke_grenade
Hooks:OverrideFunction(GroupAIStateBesiege, "_chk_group_use_smoke_grenade", function (self, group, task_data, detonate_pos)
	local result = dsbw_orig_chk_group_use_smoke_grenade(self, group, task_data, detonate_pos)
	if result and DS_BW and DS_BW.DS_difficultycheck then
		task_data.use_smoke_timer = self._t + (math.lerp(tweak_data.group_ai.smoke_and_flash_grenade_timeout[1], tweak_data.group_ai.smoke_and_flash_grenade_timeout[2], math.rand(0, 1)^0.5) * 2)
	end
	return result
end)