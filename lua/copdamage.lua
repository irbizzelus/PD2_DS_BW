-- make enemies and civs ignore damage coming from the flashbang fire trap (yes, civs are handled here as well)
local ds_bw_orig_damage_fire = CopDamage.damage_fire
function CopDamage:damage_fire(attack_data)
	if attack_data.DS_BW_cop_molotov then
		return
	end
	return ds_bw_orig_damage_fire(self, attack_data)
end

-- miniboss deathtracker
Hooks:PostHook(CopDamage, "die", "DS_BW_miniboss_deathtracker", function(self,attack_data)
	if self._unit:base():char_tweak().tags and table.contains(self._unit:base():char_tweak().tags, "DSBW_tag_miniboss") then
		self._unit:contour():remove("generic_interactable_selected", true)
		local boss = DS_BW.Miniboss_info
		if boss.is_alive then
			boss.kill_counter = boss.kill_counter + 1
			if boss.kill_counter == 1 and boss.appearances <= 2 then
				DS_BW.CM:public_chat_message("[DS_BW] 1 down, 1 to go.") -- print 'guide' message to let players know that there are 2 bosses total. only for first 2 appearances
			end
			if boss.kill_counter == 2 then
				DS_BW.CM:public_chat_message("[DS_BW] Duo defeated, damage resistance reduced back to 50%. Well done.")
				boss.is_alive = false
				boss.kill_counter = 0
			end
		end
	end
end)