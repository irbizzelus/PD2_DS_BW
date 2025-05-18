if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

GroupAIStateBesiege._DS_BW_dmg_reduction = false

-- respawn rate adjustments
Hooks:PostHook(GroupAIStateBesiege, "init", "DS_BW_spawngroups", function(self)
	if not DS_BW.DS_difficultycheck then
		return
	end
	self._MAX_SIMULTANEOUS_SPAWNS = 2
end)

local assault_task_updates = 0
Hooks:PostHook(GroupAIStateBesiege, "_upd_assault_task", "DS_BW_updassault", function(self, ...)
	
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
					if self._hunt_mode then -- make cpt. Winters and scripted endless assaults more painful
						if sp.interval and sp.interval > 1 then
							sp.interval = 1
						end
						if sp.delay_t then
							sp.delay_t = 0
						end
					elseif Global.level_data and Global.level_data.level_id == "nmh" then -- and as always, its special
						if self._task_data.assault.phase == "anticipation" then
							if sp.interval and sp.interval > 1 then
								sp.interval = 1
							end
							if sp.delay_t then
								sp.delay_t = 0
							end
						else
							if sp.interval then
								if DS_BW.Miniboss_info.is_alive and sp.interval ~= 0.75 then
									sp.interval = 0.75
								elseif sp.interval ~= 1.5 then
									sp.interval = 1.5
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
						if sp.interval then
							if DS_BW.Miniboss_info.is_alive and sp.interval ~= 1.5 then
								sp.interval = 1.5
							elseif sp.interval ~= 3 then
								sp.interval = 3
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
	
	-- if our wanted dmg reduction is higher then this variable, game will try to increase it automaticaly to the max as if winters is alive. but since he isnt, game crashes.
	tweak_data.group_ai.phalanx.vip.damage_reduction.max = 0.49
	-- values slightly lower then 0.5 and 0.666 to avoid accidental damage breakpoint fuckery for everyone invloved, in case base games calculations round damage weirdly
	local dmg_resist_amount = 0.49
	-- because this map only has 1 unit that can have DS levels of damage, we set it to 75%, since that unit has 40 hp
	if Global.level_data and Global.level_data.level_id == "mad" then
		dmg_resist_amount = 0.74
	end
	if DS_BW.Miniboss_info.is_alive then
		if Global.level_data and Global.level_data.level_id == "mad" then
			dmg_resist_amount = 0.79
		else
			dmg_resist_amount = 0.66
		end
	end
	
	self:set_phalanx_damage_reduction_buff(dmg_resist_amount)
	
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
			if not DS_BW.end_stats_header_printed then -- if bosses dissapear but we are at the game over screen, dont send messages
				local dmg_resist_str = "50"
				if Global.level_data and Global.level_data.level_id == "mad" then
					dmg_resist_str = "75"
				end
				DS_BW.CM:public_chat_message("[DS_BW] Devil duo is gone, enemy damage resistance reduced back to "..dmg_resist_str.."%.")
			end
		end
	end
	
	DelayedCalls:Add("DS_BW_reapply_dmg_reduction", 5, function()
		self:apply_DS_BW_dmg_reduction_loop()
	end)
end