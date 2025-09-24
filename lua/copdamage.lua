-- make enemies and civs ignore damage coming from the flashbang fire trap (yes, civs are handled here as well)
local ds_bw_orig_damage_fire = CopDamage.damage_fire
function CopDamage:damage_fire(attack_data)
	if attack_data.DS_BW_cop_molotov then
		return
	end
	return ds_bw_orig_damage_fire(self, attack_data)
end

Hooks:PreHook(CopDamage, "die", "DS_BW_CopDamage_die_pre", function(self,attack_data)
	
	-- clear medic's red highlight that they get during miniboss phase
	if self._unit:base():char_tweak().tags and table.contains(self._unit:base():char_tweak().tags, "medic") then
		self._unit:contour():remove("mark_enemy_damage_bonus_distance", true)
	end
	
	if self._unit:base():char_tweak().tags and table.contains(self._unit:base():char_tweak().tags, "DS_BW_tag_reinforced_shield") then
		if self._unit:contour() and self._unit:contour()._contour_list and #self._unit:contour()._contour_list >= 1  then
			for i=1, #self._unit:contour()._contour_list do
				if self._unit:contour()._contour_list[i] and self._unit:contour()._contour_list[i].type and self._unit:contour()._contour_list[i].type == "generic_interactable_selected" then
					self._unit:contour():remove( "generic_interactable_selected" , true ) 
				end
			end
		end
	end
	
	-- miniboss deathtracker
	if self._unit:base():char_tweak().tags and table.contains(self._unit:base():char_tweak().tags, "DS_BW_tag_miniboss") then
		self._unit:contour():remove("generic_interactable_selected", true)
		local boss = DS_BW.Miniboss_info
		if boss.is_alive then
			boss.kill_counter = boss.kill_counter + 1
			if boss.kill_counter == 1 and boss.appearances <= 1 then
				DS_BW.CM:public_chat_message("[DS_BW] 1 down, 2 to go.") -- print 'guide' message to let players know that there are 2 bosses total. only for first 2 appearances
			end
			if boss.kill_counter == 2 and boss.appearances <= 1 then
				DS_BW.CM:public_chat_message("[DS_BW] 2 down, 1 to go.") -- print 'guide' message to let players know that there are 2 bosses total. only for first 2 appearances
			end
			if boss.kill_counter == 3 then
				if boss.appearances <= 1 then
					DS_BW.CM:public_chat_message("[DS_BW] Trio defeated and global enemy damage resistance is now gone. Well done.")
				else
					DS_BW.CM:public_chat_message("[DS_BW] Trio was defeated. For now.")
				end
				boss.is_alive = false
				boss.kill_counter = 0
			end
		end
	end
	
end)

Hooks:PostHook(CopDamage, "_on_damage_received", "DS_BW_CopDamage_on_damage_received_post", function(self, attack_data)
	
	if not (Network:is_server() and DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	
	if self._dead then
		
		local killer_unit = attack_data.attacker_unit
		if alive(killer_unit) and killer_unit:base() then
			if killer_unit:base().thrower_unit then
				killer_unit = killer_unit:base():thrower_unit()
			elseif killer_unit:base().sentry_gun then
				killer_unit = killer_unit:base():get_owner()
			elseif killer_unit:character_damage()._converted then
				for u_key, u_data in pairs(managers.groupai:state():all_player_criminals()) do
					if u_data.minions then
						for bot_key, bot_data in pairs(u_data.minions) do
							if killer_unit == bot_data.unit then
								killer_unit = u_data.unit
							end
						end
					end
				end
			end
		end
		
		function DS_BW:update_kpm_stats()
			if Application:time() > DS_BW.kpm_tracker.update_after then
				if DS_BW.Assault_info and (DS_BW.Assault_info.phase == "build" or DS_BW.Assault_info.phase == "sustain") then
					DS_BW.kpm_tracker.update_after = Application:time() + 40
					for i=1,4 do
						if DS_BW.kpm_tracker.kills[i] > 0 then
							DS_BW.kpm_tracker.kpm[i] = DS_BW.kpm_tracker.kills[i] * 1.5
						else
							DS_BW.kpm_tracker.kpm[i] = 0
						end
					end
					DS_BW.kpm_tracker.kills = {0,0,0,0}
				end
			end
			DelayedCalls:Add("DS_BW_kpm_updater", 0.05, function()
				DS_BW:update_kpm_stats()
			end)
		end
		
		if killer_unit and not CopDamage.is_civilian(self._unit:base()._tweak_table) then
			local killer_id = managers.network:session():peer_by_unit(killer_unit) and managers.network:session():peer_by_unit(killer_unit):id()
			if killer_id and DS_BW.Assault_info and (DS_BW.Assault_info.phase == "build" or DS_BW.Assault_info.phase == "sustain") then
				DS_BW.kpm_tracker.kills[killer_id] = DS_BW.kpm_tracker.kills[killer_id]+1
			end
			DS_BW:update_kpm_stats()
		end
		
	end
	
end)

Hooks:PreHook(CopDamage, "damage_bullet", "DS_BW_CopDamage_damage_bullet_pre", function(self,attack_data)
	
	if not (Network:is_server() and DS_BW and DS_BW.DS_difficultycheck) then
		return
	end
	
	-- if host does not have dmg reduction penalties, apply those penalties to friendly ai bullets anyway:
	-- normaly when host has a penalty active, all friendly ai that host usualy handles deals reduced damage based on the penalty. so if the host is not the one with an active penalty
	-- all friendly ai should still deal less damage at higher up-spawn levels
	local function reduce_friendly_ai_dmg()
		
		local attacker_unit = attack_data.attacker_unit
		
		-- if attacker_unit is either a thrower_unit or damage_bullet is targeted at a friendly converted AI, dont reduce dmg
		if alive(attacker_unit) and attacker_unit:base() and attacker_unit:base().thrower_unit then
			return false
		elseif self._unit:character_damage()._converted then
			return false
		end
		
		-- dont reduce bullet dmg for host
		if attacker_unit == managers.player:player_unit() then
			return false
		end
		if DS_BW._low_spawns_manager and DS_BW._low_spawns_manager.level >= 3 and DS_BW.kpm_tracker.penalties[1].amount == 0 then
			if DS_BW._low_spawns_manager.level == 3 then
				return 0.8
			else
				return 0.67
			end
		end
	end
	
	local reduction = reduce_friendly_ai_dmg()
	if reduction and reduction > 0 then
		attack_data.damage = attack_data.damage * reduction
	end
	
end)