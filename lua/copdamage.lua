-- make enemies and civs ignore damage coming from the flashbang fire trap (yes, civs are handled here as well)
local ds_bw_orig_damage_fire = CopDamage.damage_fire
function CopDamage:damage_fire(attack_data)
	if attack_data.DS_BW_cop_molotov then
		return
	end
	return ds_bw_orig_damage_fire(self, attack_data)
end

-- miniboss deathtracker
Hooks:PreHook(CopDamage, "die", "DS_BW_miniboss_deathtracker", function(self,attack_data)
	
	-- try to clear medic's red highlight from miniboss's phase on death. doesnt work for some reason, need to test further
	if self._unit:base():char_tweak().tags and table.contains(self._unit:base():char_tweak().tags, "medic") then
		self._unit:contour():remove("mark_enemy_damage_bonus_distance", true)
	end
	
	if self._unit:base():char_tweak().tags and table.contains(self._unit:base():char_tweak().tags, "DS_BW_tag_miniboss") then
		self._unit:contour():remove("generic_interactable_selected", true)
		local boss = DS_BW.Miniboss_info
		if boss.is_alive then
			boss.kill_counter = boss.kill_counter + 1
			if boss.kill_counter == 1 and boss.appearances <= 2 then
				DS_BW.CM:public_chat_message("[DS_BW] 1 down, 1 to go.") -- print 'guide' message to let players know that there are 2 bosses total. only for first 2 appearances
			end
			if boss.kill_counter == 2 then
				local dmg_resist_str = "50"
				if Global.level_data and Global.level_data.level_id == "mad" then
					dmg_resist_str = "75"
				end
				DS_BW.CM:public_chat_message("[DS_BW] Duo defeated, damage resistance reduced back to "..dmg_resist_str.."%. Well done.")
				boss.is_alive = false
				boss.kill_counter = 0
			end
		end
	end
end)