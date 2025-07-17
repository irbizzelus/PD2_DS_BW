-- self-explanatory - prevents a crash when info is missing
-- in DS_BW this should only occur when we force a boss unit spawn
Hooks:PreHook(CopMovement, "team", "DS_BW_setcopteamifnoteam", function(self)
	if not self._team then
		self:set_team(managers.groupai:state()._teams[tweak_data.levels:get_default_team_ID(self._unit:base():char_tweak().access == "gangster" and "gangster" or "combatant")])
	end
end)

-- prevent hotspot guards from moving
local ds_bw_action_request_orig = CopMovement.action_request
function CopMovement:action_request(action_desc)
	if DS_BW and DS_BW.HotSpotLogic and DS_BW.HotSpotLogic.HotSpotActiveUnits and DS_BW.HotSpotLogic.HotSpotActiveUnits[tostring(self._unit:id())] and action_desc.type == "walk" then
		return
	end
	return ds_bw_action_request_orig(self,action_desc)
end

function DS_BW.highlight_medics_when_boss_is_active(npc)
	if not npc then
		return
	end
	if not alive(npc._unit) then
		return
	end
	-- this one stops highlight loop if enemy is dead, since alive func above checks if unit itself is alive, and a dead body is still an alive unit
	if not npc:can_request_actions() then
		return
	end
	
	npc._unit:contour():add( "mark_enemy_damage_bonus_distance" , true )
	
	-- loop highlight addition every 2 seconds
	DelayedCalls:Add("ContinueHighlightForSniper_"..tostring(npc._unit:id()), 2, function()
		if DS_BW and DS_BW.Miniboss_info.is_alive then
			DS_BW.highlight_medics_when_boss_is_active(npc)
		end
	end)
end

-- whenver miniboss becomes active, highlight all medic units on the level to try to minimize frustrations with bossess getting healed, since i dont want to make them un-healable
Hooks:PostHook(CopMovement, "action_request", "DS_BW_add_medic_highlight_for_boss" , function(self,action_desc)
	
	if not Network:is_server() then
		return
	end
	
	if not DS_BW then
		return
	end
	
	-- idk, some check if unit is busy or something? ask Undeadsewer, that's his code
	if self._unit:base().mic_is_being_moved then
		return
	end
	
	if managers.enemy:is_civilian(self._unit) then
		return
	end
	
	-- include both normal and dozer medics
	-- highlight itself looks like a standard red highlight without damage skills, but it doesnt decay after a few seconds and stays on forever.
	if DS_BW.Miniboss_info.is_alive then
		if self._unit:base() and self._unit:base():char_tweak() and self._unit:base():char_tweak().tags and table.contains(self._unit:base():char_tweak().tags, "medic") then
			DS_BW.highlight_medics_when_boss_is_active(self)
		end
	end
	
end)