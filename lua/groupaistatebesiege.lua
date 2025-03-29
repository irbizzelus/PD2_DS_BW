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

Hooks:PostHook(GroupAIStateBesiege, "_upd_assault_task", "DS_BW_updassault", function(self, ...)
	
	if not DS_BW.DS_difficultycheck then
		return
	end
	
	if self._spawning_groups and #self._spawning_groups >= 1 then
		for i=1, #self._spawning_groups do
			for _, sp in ipairs(self._spawning_groups[i].spawn_group.spawn_pts) do
				-- if cuurent phase is fade or regroup (for some reason its just nil nowadays) force longer respawn times
				-- by setting spawn delay on enemy spawn points every function trigger
				
				-- clear (or create) the table every time new tank squad spawns in, because sometiems heists may make certain spawn points inactive
				-- like when you move through heat streat for example, spawns at the begining should no longer be active
				DS_BW.Miniboss_info.spawn_locations = {}
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
								if DS_BW.Miniboss_info.is_alive and sp.interval ~= 2.5 then
									sp.interval = 2.5
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
							if DS_BW.Miniboss_info.is_alive and sp.interval ~= 5 then
								sp.interval = 5
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
		self:apply_DSBW_dmg_reduction_loop()
	end
	
end)

-- add the 50% damage reduction every 10 seconds. this makes it active 24/7 regardless of other factors that might disable it
function GroupAIStateBesiege:apply_DSBW_dmg_reduction_loop()
	
	-- stealth is ignored
	if managers.groupai:state():whisper_mode() then
		return
	end
	
	if not self._DS_BW_dmg_reduction then
		self._DS_BW_dmg_reduction = true
	end
	
	-- if this value is higher then our current dmg reduction, game will try to increase it automaticaly as if winters is alive. but since he is not alive, game crashes.
	tweak_data.group_ai.phalanx.vip.damage_reduction.max = 0.49
	-- values slightly lower then 0.5 and 0.666 to avoid accidental damage breakpoint fuckery for everyone invloved, in case base games calculations round damage weirdly
	local dmg_resist_amount = 0.49
	-- because this map only has 1 unit that can have DS levels of damage, we set it to 75%, since that unit has 40 hp. also disable boss there
	if Global.level_data and Global.level_data.level_id == "mad" then
		dmg_resist_amount = 0.74
	elseif DS_BW.Miniboss_info.is_alive then
		dmg_resist_amount = 0.66
	end
	
	self:set_phalanx_damage_reduction_buff(dmg_resist_amount)
	
	-- for some reason, sometimes, mid-match, surrender values get reset to their defaults (hope its not one of my other mods)
	-- to avoid making player's life too easy we will make sure it does not happen, by making this check along with winter's dmg resist
	if tweak_data.character.zeal_swat.surrender.base_chance ~= 0.25 then
		DS_BW:update_surrender_tweak_data()
	end
	
	DelayedCalls:Add("DS_BW_reapply_dmg_reduction", 5, function()
		self:apply_DSBW_dmg_reduction_loop()
	end)
end