DS_BW.ASC = {
	units_watchlist = {}
}

function DS_BW.ASC:give_unit_invuln(unit)
	
	if unit:contour() then
		
		local function should_apply_contour(unit)
			if unit:contour()._contour_list and #unit:contour()._contour_list >= 1  then
				for i=1, #unit:contour()._contour_list do
					if unit:contour()._contour_list[i] and unit:contour()._contour_list[i].type and unit:contour()._contour_list[i].type == "tmp_invulnerable" then
						return false
					end
				end
			end
			return true
		end
		
		if should_apply_contour(unit) then
			unit:contour():add("tmp_invulnerable", true, 9, nil, false)
			unit:contour():flash("tmp_invulnerable", 0.1)
		end
	end
	
	unit:character_damage():set_invulnerable_tmp(0.5)
	unit:character_damage():set_immortal(true)
	unit:network():send("set_unit_invulnerable", true, true)
	
	-- auto-remove invuln as a safety measure
	DelayedCalls:Add("DS_BW_clear_invulnerabibility_for_unit_"..tostring(unit:id()), 0.5, function()
		if unit and alive(unit) then
			for i=1,3 do -- for whatever reason un-invuln sometimes does not register properly immediately for clients but only after a short delay, yet spamming it this way makes enemies un-invulned instantly, so we keep this "fix"
				unit:network():send("set_unit_invulnerable", false, false)
				i = i + 1
			end
			unit:character_damage():_clbk_temp_invulnerability_off()
			unit:character_damage():set_immortal(false)
		end
	end)
end

function DS_BW.ASC:remove_unit_invuln(unit)
	unit:character_damage():_clbk_temp_invulnerability_off()
	unit:character_damage():set_immortal(false)
	
	for i=1,3 do
		unit:network():send("set_unit_invulnerable", false, false)
		i = i + 1
	end
	
	if unit:contour() then
		unit:contour():remove("tmp_invulnerable", true)
	end
end

-- give teammates from the spawn killed unit's squad invlun if they are doing vaulting anims
function DS_BW.ASC:triggered(unit, spawn_time)
	local data = unit:brain()._logic_data
	if data.group and data.group.has_spawned and data.group.initial_size > 1 then
		for u_key, u_data in pairs(data.group.units) do
			if u_key ~= data.key and mvector3.distance_sq(data.m_pos, u_data.m_pos) < 640000 then
				if u_data.unit:anim_data().act then
					DS_BW.ASC:give_unit_invuln(u_data.unit)
				end
				self.units_watchlist[u_data.unit] = spawn_time
			end
		end
	end
end

-- decide how long after spawning should bots still be protected based on the map
function DS_BW.ASC:get_map_based_ASC_timer()
	local level_balance_data = {
		dinner = 13,
		nmh = 5,
	}
	return level_balance_data[Global and Global.level_data and Global.level_data.level_id] or 10
end

function DS_BW.ASC:manage_watchlist()
	if next(self.units_watchlist) ~= nil then -- check if !table_empty
		for unit, timer in pairs(self.units_watchlist) do
			if unit and alive(unit) then
				if unit:character_damage():dead() then -- if dead ignore all other checks
					DS_BW.ASC:remove_unit_invuln(unit)
				elseif not unit:anim_data().act then -- remove invlun if enemy is not "acting" aka doing vaulting animations
					DS_BW.ASC:remove_unit_invuln(unit)
				elseif (timer + self:get_map_based_ASC_timer()) > Application:time() and unit:anim_data().act then -- if within x seconds of spawn unit begins to "act", give them invlun
					DS_BW.ASC:give_unit_invuln(unit)
				elseif (timer + self:get_map_based_ASC_timer()) < Application:time() then -- clear everything if timer is done, regardless of if unit is acting
					DS_BW.ASC:remove_unit_invuln(unit)
				end
			else
				self.units_watchlist[unit] = nil -- clear on unit removal
			end
		end
	end
	-- infinite loop
	DelayedCalls:Add("DS_BW_ASC_watchlist_manager", 0.01, function()
		DS_BW.ASC:manage_watchlist()
	end)
end
DS_BW.ASC:manage_watchlist()