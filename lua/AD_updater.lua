-- killwhoring adjustment system, if enemy amounts were too low for long enough, their spawn rates are increased
-- same in the opposite direction, but only if we already have higher than base level respawns
function DS_BW:ADU_Update()
	
	local function can_proceed()
		if not (DS_BW and DS_BW.DS_difficultycheck) then
			return false
		end
		if not (Network and Network:is_server()) then
			return false
		end
		if not managers.groupai or not managers.groupai:state() then
			return false
		end
		local grpai = managers.groupai:state()
		if not grpai or not grpai:is_AI_enabled() or not grpai:enemy_weapons_hot() or grpai:whisper_mode() then
			return false
		end
		return true
	end
	
	if not can_proceed() then
		DS_BW.adu_running = false
		return nil
	else
		DS_BW.adu_running = true
	end
	
	local LSM = DS_BW._low_spawns_manager
	local KPM = DS_BW.kpm_tracker
	
	local enemy_count = managers.enemy._enemy_data.nr_units or 0
	local target_enemy_spawns = managers.groupai:state()._task_data.assault.active and managers.groupai:state()._task_data.assault.force
	
	local function spawn_adjustment_allowed()
		if not (DS_BW.Assault_info.phase == "sustain" or DS_BW.Assault_info.phase == "build") then
			return false
		end
		if DS_BW._dsbw_new_winter_penalty_applied_ang_going then
			return false
		end
		local CD_per_level = {
			[0] = 10, -- failsafe
			[1] = 10,
			[2] = 50,
			[3] = 75,
			[4] = 100,
			[5] = 130,
			[6] = 130, -- failsafe
		}
		if not ((Application:time() - LSM.adjustment_cooldown) > CD_per_level[LSM.level]) then
			return false
		end
		return true
	end
	
	local level_floor_limit = DS_BW.settings.starting_adapt_diff - 1 -- lua starts at 1 :)
	if level_floor_limit > 0 and LSM.level < level_floor_limit then
		LSM.level = level_floor_limit
		LSM.detected_low = false
		LSM.detected_high = false
		LSM.adjustment_cooldown = Application:time()
		DS_BW:announce_adapt_diff()
	end
	
	-- if lvl 1 is ever reached, never drop bellow it
	if LSM.level == 1 then
		level_floor_limit = 1
	end
	
	local og_level = LSM.level
	if spawn_adjustment_allowed() then
		
		local function kpm_threshold_check()
			local hkpm = -1
			local avg_kpm = 0
			for i=1,4 do
				avg_kpm = avg_kpm + KPM.kpm[i]
				if KPM.kpm[i] > hkpm then
					hkpm = KPM.kpm[i]
				end
			end
			avg_kpm = avg_kpm / (managers.groupai:state():num_alive_players() or 4)
			if LSM.level < 5 and hkpm >= KPM.thresholds[LSM.level+1] and avg_kpm >= (KPM.thresholds[LSM.level+1] * 0.6) then
				return "over" -- allows to go up
			elseif LSM.level >= 1 and hkpm < KPM.thresholds[LSM.level] then
				return "under" -- forces to go down
			else
				return "stable"
			end
		end
		
		if target_enemy_spawns and enemy_count <= (target_enemy_spawns * 0.96) and kpm_threshold_check() ~= "under" then
			if not LSM.detected_high then
				LSM.gracing = nil
				if not LSM.detected_low then
					LSM.detected_low = Application:time()
				end
				-- if fade is reached, remember detected low progress and reset it on new wave, otherwise we would get free progress during fade/anticipation
				if LSM.detected_low_to_remember then
					LSM.detected_low = Application:time() - LSM.detected_low_to_remember
					LSM.detected_low_to_remember = nil
				end
				-- if spawns are too low, but our kpm is not high enough, delay level increases until kpm reaches the target
				if kpm_threshold_check() == "stable" then
					LSM.detected_low = LSM.detected_low + 0.01 -- based on "update rate" of this delayed-call-loop
				end
				local required_sustain_duration = { -- sustain requirements for x seconds to reach this level
					[1] = 35,
					[2] = 50,
					[3] = 75,
					[4] = 110,
					[5] = 160,
				}
				if LSM.level <= 4 and (Application:time() - LSM.detected_low) > required_sustain_duration[LSM.level + 1] then
					LSM.level = LSM.level + 1
					if LSM.level > 5 then
						LSM.level = 5
					end
					LSM.detected_low = false
					LSM.detected_high = false
					LSM.adjustment_cooldown = Application:time()
				end
			else -- if performance is too good, but it was too bad recently, wait out a grace period before trying to go up
				if not LSM.gracing then
					LSM.gracing = Application:time()
				else
					if (LSM.gracing + 10) < Application:time() then
						LSM.detected_high = false
						LSM.gracing = nil
					end
				end
			end
		elseif (target_enemy_spawns and enemy_count > (target_enemy_spawns * 0.96)) or kpm_threshold_check() == "under" then
			if not LSM.detected_low then
				LSM.gracing = nil
				if LSM.level > 0 and not LSM.detected_high then
					LSM.detected_high = Application:time()
				end
				-- if fade is reached, remember detected high progress and reset it on new wave, otherwise we would get free progress during fade/anticipation
				if LSM.detected_high_to_remember then
					LSM.detected_high = Application:time() - LSM.detected_high_to_remember
					LSM.detected_high_to_remember = nil
				end
				local required_sustain_duration = { -- sustain requirements for x seconds to drop from this level
					[1] = 140,
					[2] = 140,
					[3] = 180,
					[4] = 240,
					[5] = 300,
				}
				if LSM.level > 0 and (Application:time() - LSM.detected_high) > required_sustain_duration[LSM.level] and (LSM.level > level_floor_limit) then
					LSM.level = LSM.level - 1
					if LSM.level < 0 then
						LSM.level = 0
					end
					LSM.detected_low = false
					LSM.detected_high = false
					LSM.adjustment_cooldown = Application:time()
				end
			else -- if performance is too bad, but it was too good recently, wait out a grace period before trying to go down
				if not LSM.gracing then
					LSM.gracing = Application:time()
				else
					if (LSM.gracing + 10) < Application:time() then
						LSM.detected_low = false
						LSM.gracing = nil
					end
				end
			end
		end
		
		-- add delay to DR penalty application, and also update player-based DR's only once every x seconds
		local function should_add_DR()
			if DS_BW.Assault_info.phase ~= "sustain" then -- reset delay during non-sutain phases
				KPM.update_cooldown = -1
			end
			if KPM.update_cooldown > 0 and Application:time() > KPM.update_cooldown then
				KPM.update_cooldown = -1
				return true
			else
				if KPM.update_cooldown < 0 then
					local DR_delay = {
						[4] = 90,
						[5] = 140,
					}
					KPM.update_cooldown = Application:time() + (DR_delay[LSM.level] or 30)
				end
			end
			return false
		end
		
		if LSM.level <= og_level and LSM.level <= 3 then -- remove penalties if dropped to lvl <=3 and not permanent
			KPM.update_cooldown = -1
			for i=1,4 do
				if KPM.penalties[i].amount > 0 and not KPM.penalties[i].is_perma then
					KPM.penalties[i].amount = 0
				end
			end
		elseif LSM.level == 4 and should_add_DR() then -- add lvl 4 penalties
			for i=1,4 do
				if not KPM.penalties[i].is_perma then
					if KPM.kpm[i] >= KPM.thresholds[4] then
						KPM.penalties[i].amount = 0.25
					else
						KPM.penalties[i].amount = 0.1
					end
				end
			end
		elseif LSM.level == 5 and should_add_DR() then -- 5
			if not KPM.penalties[1].is_perma then
				DS_BW.CM:public_chat_message("[DS_BW] Team performance was re-evaluated and deemed way too effective. Congrautlations. All enemies now have a permanent 20-33% damage resistance against all players, scaling based on your performance. Good luck.")
			end
			for i=1,4 do
				if not KPM.penalties[i].is_perma then
					KPM.penalties[i].is_perma = true
				end
			end
		end
		
		-- keep lvl 5 DR's up to date, even if level was dropped
		if KPM.penalties[1].is_perma then
			for i=1,4 do
				if KPM.kpm[i] >= KPM.thresholds[5] then
					KPM.penalties[i].amount = 0.33
				else
					KPM.penalties[i].amount = 0.2
				end
			end
		end
		
		-- extend current assault duration if lvl goes up, only once per wave
		if og_level ~= LSM.level then
			if LSM.level > og_level and (DS_BW.Assault_info.number >= 2 or DS_BW:is_hard_heist()) and not LSM.current_wave_was_extended then
				managers.groupai:state()._task_data.assault.phase_end_t = managers.groupai:state()._task_data.assault.phase_end_t + 180
				managers.groupai:state()._task_data.assault.force_spawned = -500 -- force the wave end to be reached by time out instead of outkilling. unless players are THAT good
				LSM.current_wave_was_extended = true
				DS_BW:announce_adapt_diff("wave_extended")
			else
				DS_BW:announce_adapt_diff()
			end
			KPM.update_cooldown = -1
		end
		
	else
		LSM.detected_low = false
		LSM.detected_high = false
	end
	
	-- enemy presence updates
	local grpai = managers.groupai:state()
	if DS_BW._dsbw_new_winter_penalty_applied_ang_going then
		tweak_data.group_ai.besiege.assault.force_balance_mul = {4.5,4.5,4.5,4.5}
		grpai._task_data.assault.force = math.ceil(grpai:_get_difficulty_dependent_value(grpai._tweak_data.assault.force) * grpai:_get_balancing_multiplier(grpai._tweak_data.assault.force_balance_mul))
		tweak_data.group_ai.special_unit_spawn_limits = {
			shield = 99,
			medic = 99,
			taser = 99,
			tank = 99,
			spooc = 99
		}
	else
		-- max on the map
		local pool_muls = {
			[1] = 1.25,
			[2] = 1.4,
			[3] = 1.7,
			[4] = 2,
			[5] = 2.5,
		}
		local mul = pool_muls[LSM.level] or 1
		tweak_data.group_ai.besiege.assault.force_balance_mul = {
			mul,
			mul,
			mul,
			mul
		}
		grpai._task_data.assault.force = math.ceil(grpai:_get_difficulty_dependent_value(grpai._tweak_data.assault.force) * grpai:_get_balancing_multiplier(grpai._tweak_data.assault.force_balance_mul))
		
		-- total per wave
		local function should_update_total_pool()
			if og_level > LSM.level then -- dont update the pool until fade to avoid instant wave end on ADL going down
				LSM.prevent_total_pool_updates_this_wave = true
				return false
			end
			if LSM.prevent_total_pool_updates_this_wave then
				return false
			end
			if og_level < LSM.level and LSM.prevent_total_pool_updates_this_wave then -- remove preventions on ADL going up
				LSM.prevent_total_pool_updates_this_wave = nil
			end
			return true
		end
		if should_update_total_pool() then
			local total_spawns_muls = {
				[1] = 1.2,
				[2] = 1.5,
				[3] = 1.8,
				[4] = 2.5,
				[5] = 3.5,
			}
			local total_mul = total_spawns_muls[LSM.level] or 1
			tweak_data.group_ai.besiege.assault.force_pool_balance_mul = {
				total_mul,
				total_mul,
				total_mul,
				total_mul
			}
			grpai._task_data.assault.force_pool = math.ceil(grpai:_get_difficulty_dependent_value(grpai._tweak_data.assault.force_pool) * grpai:_get_balancing_multiplier(grpai._tweak_data.assault.force_pool_balance_mul))
		end
		
		-- duration muls
		local dur_muls = {
			[0] = 0.5,
			[1] = 0.8,
			[2] = 1,
			[3] = 1.1,
			[4] = 1.2,
			[5] = 1.2,
		}
		local mul = dur_muls[LSM.level] or 1
		grpai._tweak_data.assault.sustain_duration_balance_mul = {
			mul,
			mul,
			mul,
			mul
		}
		
		-- increase squad specific spawn chances
		local enemy_muls = {
			[1] = 1,
			[2] = 1.15,
			[3] = 1.3,
			[4] = 1.5,
			[5] = 2,
		}
		local enemy_mul = enemy_muls[LSM.level] or 1
		grpai._tweak_data.assault.groups.tac_bull_rush = {
			DS_BW.base_groupaitweak_values.assault_groups.tac_bull_rush[1] * enemy_mul,
			DS_BW.base_groupaitweak_values.assault_groups.tac_bull_rush[2] * enemy_mul,
			DS_BW.base_groupaitweak_values.assault_groups.tac_bull_rush[3] * enemy_mul,
		}
		grpai._tweak_data.assault.groups.Squad_Tank_Annoying = {
			DS_BW.base_groupaitweak_values.assault_groups.Squad_Tank_Annoying[1] * enemy_mul,
			DS_BW.base_groupaitweak_values.assault_groups.Squad_Tank_Annoying[2] * enemy_mul,
			DS_BW.base_groupaitweak_values.assault_groups.Squad_Tank_Annoying[3] * enemy_mul,
		}
		
	end
	
	DelayedCalls:Add("DS_BW_AD_updater", 0.01, function()
		DS_BW:ADU_Update()
	end)
end

function DS_BW:announce_adapt_diff(reason)
	local lvl_str = tostring(DS_BW._low_spawns_manager.level) or "0"
	local msg = "Adaptive difficulty level updated to "..lvl_str.." - /adl"
	if reason == "early_fade" then
		msg = "Assault is fading. Adaptive difficulty level increased to "..lvl_str.." - /adl"
	elseif reason == "wave_extended" then
		msg = "Adaptive difficulty level increased to "..lvl_str..". Current assault duration was extended by 180 seconds - /adl"
	end
	if DS_BW.settings.ADL_announcements then
		if Network:is_server() and DS_BW and DS_BW.DS_difficultycheck then
			DS_BW.CM:public_chat_message("[DS_BW] "..msg)
		end
	else
		-- if option is disabled still print stuff into logs
		if Network:is_server() and DS_BW and DS_BW.DS_difficultycheck then
			log("[DS_BW] "..msg)
		end
	end
end