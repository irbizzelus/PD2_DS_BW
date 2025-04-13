if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

-- most heists will follow a rule where first assault is easier then 2nd and onward.
-- sometimes however, it makes no logicas sense to have 'recon' easy assaults at the begining because a heist could be a set up (like alaska)
-- in such cases we skip first assault. also aplies to heists that are in general slower paced at the start (like harvest and trustee branchbank)
local heists_without_1st_assault = {
	"branchbank",
	"rvd1", -- reserviour dogs
	"rvd2",
	"nail", -- haloween heists
	"hvh",
	"help",
	"firestarter_1", -- mhm
	"firestarter_2",
	"firestarter_3",
	"pex", -- breakfast in tihuana
	"bph", -- hell's island
	"vit", -- white house
	"hox_1", -- breakout
	"hox_2",
	"framing_frame_2", -- mhm
	"pines", -- vlad's white xmas
	"run", -- heat street
	"man", -- undercover
	"firestarter_3", -- mhm
	"mad", -- boil point
	"wwh", -- alaska
}

-- prevent drama from goin over 95 so we never skip anticipation, except for very first wave. reason: longer breaks
-- also some track's anticipation music is 11/10, yet i almost never hear it because of this useless (gameplay wise) mechanic
-- also prevent drama from beeing too low to make fade last as long as possible, thanks to update 181, this is not exploitable and gives 1 minute of free time during fade at best
local orig_drama = GroupAIStateBase._add_drama
function GroupAIStateBase:_add_drama(amount)
	-- tracking info
	DS_BW.Assault_info.number = self._assault_number
	DS_BW.Assault_info.phase = (self._task_data and self._task_data.assault and self._task_data.assault.phase) or "unknown"
	DS_BW.Assault_info.is_infinite = self._hunt_mode
	
	if DS_BW.DS_difficultycheck and Global.level_data and Global.level_data.level_id == "nmh" then
		-- make first 2 assauls on no mercy faster then other heists
		if self._assault_number <= 1 then
			if self._task_data and self._task_data.assault and self._task_data.assault.phase == "anticipation" and self._drama_data.amount ~= 0.999 then
				self._drama_data.amount = 0.999
				amount = 0
			elseif self._task_data and self._task_data.assault and self._task_data.assault.phase == "fade" and self._drama_data.amount ~= 0.01 then
				self._drama_data.amount = 0.01
				amount = 0
			end
		else
			if self._drama_data.amount + amount ~= 0.9 then
				self._drama_data.amount = 0.9
				amount = 0
			end
		end
	elseif DS_BW.DS_difficultycheck == true then
		if (not self._task_data.assault.phase or self._task_data.assault.phase == "anticipation") and self._assault_number == 0 then
			if self._drama_data.amount + amount ~= 0.99 then
				self._drama_data.amount = 0.99
				amount = 0
			end
		else
			if self._drama_data.amount + amount ~= 0.9 then
				self._drama_data.amount = 0.9
				amount = 0
			end
		end
	end
	orig_drama(self, amount)
	-- update diff along with drama. in vanilla diff is only evaluated once, before wave starts.
	if DS_BW and DS_BW.DS_difficultycheck then
		self:set_difficulty(1)
	end
end

local orig_detonate_world_smoke_grenade = GroupAIStateBase.detonate_world_smoke_grenade
function GroupAIStateBase:detonate_world_smoke_grenade(id)
	-- disable smokes/flashbangs for the first wave, if heist is not 'fast paced'
	if DS_BW.DS_difficultycheck == true and not (Global.level_data and Global.level_data.level_id and (table.contains(heists_without_1st_assault, Global.level_data.level_id))) and self._assault_number <= 1 then
		return
	end
	orig_detonate_world_smoke_grenade(self,id)
end

local previous_phase = ""
local first_assault_update = false
local orig_diff = GroupAIStateBase.set_difficulty
function GroupAIStateBase:set_difficulty(value)
	if not DS_BW or not DS_BW.DS_difficultycheck then
		orig_diff(self, value)
		return
	end
	
	-- most heists have an easier starting first assault, that will also include easier difficulty units, to create a "easier units are scouting and getting rekt before badass guys enter" thing
	-- some heists where it logicaly makes no sense for there to be a lighter 'recon' assaul (for example alaska) will have no super easy first assault, but still a slightly easier one
	-- no mercy is 1 exception that uses ultra quick first 2 assaults to improve spawns
	
	-- _assault_number counter updates during the build phase, which comes right after anticipation
	-- this makes anticipation effectively the end of the previous wave, instead of being a begining of the new one
	
	local is_heist_without_1st_assault = false
	if Global.level_data and Global.level_data.level_id and table.contains(heists_without_1st_assault, Global.level_data.level_id) then
		is_heist_without_1st_assault = true
	end
	
	-- assault 0 is everything before first assault's build phase
	if self._assault_number == 0  then
		value = 0.05
	elseif self._assault_number == 1 and not self._hunt_mode and not is_heist_without_1st_assault then
		
		-- first 55 seconds of first assault have 0.1 diff, which spawns blue/green swats
		-- after 55 secs we spawn grey and lighter zeal swats untill 1st wave ends
		-- wave 2 and onward is full power
		if self._task_data.assault.phase == "sustain" and previous_phase == "build" then
			local diff_update_delay = 50
			-- why am i making this heist so special
			if Global.level_data and Global.level_data.level_id == "nmh" then
				diff_update_delay = 25
			end
			DelayedCalls:Add("DS_BW_update_first_assault_diff_value", diff_update_delay, function()
				first_assault_update = true
			end)
		end
		previous_phase = self._task_data.assault.phase
		
		if self._task_data.assault.phase ~= "anticipation" and not first_assault_update and value ~= 0.1 then
			value = 0.05
		elseif self._task_data.assault.phase ~= "anticipation" and first_assault_update and value ~= 0.5 then
			value = 0.5
		elseif self._task_data.assault.phase == "anticipation" and value ~= 1 then
			value = 1
		end
		
	else -- wave 2 and onward
		if self._task_data.assault.phase == "sustain" and previous_phase == "build" then
			-- miniboss has a 66.6% chance to spawn on first first full wave and then 100% on 3rd wave and onwards
			local boss_spawn_chance = 0.666
			local is_boss_roll_successful = math.random() <= boss_spawn_chance
			if (self._assault_number == 1 and self._hunt_mode or (is_boss_roll_successful and is_heist_without_1st_assault)) or (self._assault_number == 2 and is_boss_roll_successful) or self._assault_number >= 3 then
				DelayedCalls:Add("DS_BW_add_mid_wave_boss", math.random(45,60), function()
					if DS_BW.Miniboss_info.spawn_locations and #DS_BW.Miniboss_info.spawn_locations >= 1 then
						
						-- when boss is spawning, choose a random alive player, select an availabe boss spawn point closet to said player, and spawn the boss there
						
						-- add all alive player coords
						local alive_player_positions = {}
						for i=1,4 do
							local peer = managers.network and managers.network:session() and managers.network:session():peer(i)
							local unit = peer and peer:unit() or nil
							if (unit and alive(unit)) then
								table.insert(alive_player_positions, {id = i, pos = unit:position()})
							end
						end
						
						-- set default boss spawn point randomly, just in case. select a player randomly, then select closest spawn position for the boss
						local boss_spawn_point = DS_BW.Miniboss_info.spawn_locations[math.random(1,#DS_BW.Miniboss_info.spawn_locations)]
						local chosen_player = 1
						if #alive_player_positions >= 1 then
							chosen_player = math.floor(math.random(1,#alive_player_positions))
							local chosen_player_coords = alive_player_positions[chosen_player].pos -- math.random(1,4) should never have decimals values
							local lowest_distance = 999999
							for j=1, #DS_BW.Miniboss_info.spawn_locations do
								local dist = mvector3.distance(chosen_player_coords, DS_BW.Miniboss_info.spawn_locations[j])
								if dist < lowest_distance then
									lowest_distance = dist
									boss_spawn_point = DS_BW.Miniboss_info.spawn_locations[j]
								end
							end
						end
						
						local unit_str = Idstring("units/pd2_dlc_help/characters/ene_zeal_bulldozer_halloween/ene_zeal_bulldozer_halloween")
						local team = managers.groupai:state()._teams[tweak_data.levels:get_default_team_ID("combatant")]
						-- "highlight_character" - old
						local highlight_str = "generic_interactable_selected" -- all possible working options: "generic_interactable" - yellow; "generic_interactable_selected" - white; "vulnerable_character" - basic red
						local spawned_boss_1 = World:spawn_unit(unit_str, boss_spawn_point, Rotation(180 - (360 / 10) * 1, 0, 0))
						spawned_boss_1:movement():set_team(team)
						spawned_boss_1:contour():add(highlight_str , true)
						local spawned_boss_2 = World:spawn_unit(unit_str, boss_spawn_point, Rotation(180 - (360 / 10) * 1, 0, 0))
						spawned_boss_2:movement():set_team(team)
						spawned_boss_2:contour():add(highlight_str , true)
						
						if spawned_boss_1 and spawned_boss_2 and alive(spawned_boss_1) and alive(spawned_boss_2) then
							if Utils:IsInGameState() and not DS_BW.end_stats_header_printed and self._task_data and self._task_data.assault and self._task_data.assault.phase == "sustain" then
								
								DS_BW.Miniboss_info.is_alive = true
								
								local dmg_resist_str = "66.6"
								if Global.level_data and Global.level_data.level_id == "mad" then
									dmg_resist_str = "80"
								end
								
								-- only put full chat messages for first 2 appearances
								if DS_BW.Miniboss_info.appearances == 0 then
									DS_BW.CM:public_chat_message("[DS_BW] A new foe has appeared. Enemy damage resistance was increased to "..dmg_resist_str.."% until your foe is defeated. x_x")
									DS_BW.Miniboss_info.appearances = DS_BW.Miniboss_info.appearances + 1
								elseif DS_BW.Miniboss_info.appearances == 1 then
									DS_BW.CM:public_chat_message("[DS_BW] Devil duo has returned. "..dmg_resist_str.."% damage resistance is back x_x")
									DS_BW.Miniboss_info.appearances = DS_BW.Miniboss_info.appearances + 1
								elseif DS_BW.Miniboss_info.appearances >= 2 then
									DS_BW.CM:public_chat_message("[DS_BW] x_x")
									DS_BW.Miniboss_info.appearances = DS_BW.Miniboss_info.appearances + 1
								end
								
								-- make bosses attack chosen player's position.
								local target_id = alive_player_positions[chosen_player].id
								local target_loc = false
								if target_id == 1 and managers.player and managers.player:player_unit() and alive(managers.player:player_unit()) then
									target_loc = managers.player:player_unit():position()
								else
									local peer = managers.network and managers.network:session() and managers.network:session():peer(target_id)
									local unit = peer and peer:unit() or nil
									if (unit and alive(unit)) then
										target_loc = unit:position()
										target_id = i
									end
									-- backup
									if not target_loc then
										for i=2,4 do
											local peer = managers.network and managers.network:session() and managers.network:session():peer(i)
											local unit = peer and peer:unit() or nil
											if (unit and alive(unit)) then
												target_loc = unit:position()
												target_id = i
												break
											end
										end
									end
								end
								if target_loc then
									local tracker = managers.navigation:create_nav_tracker(target_loc)
									local fin_attack_pos = mvector3.copy(tracker:lost() and tracker:field_position() or tracker:position())
									managers.navigation:destroy_nav_tracker(tracker)
									local objective = {
										type = "free",
										haste = "run",
										pose = "stand",
										nav_seg = managers.navigation:get_nav_seg_from_pos(fin_attack_pos, true),
										pos = mvector3.copy(fin_attack_pos),
										forced = true,
										important = true
									}
									spawned_boss_1:brain():set_objective(objective)
									spawned_boss_1:brain():set_logic("attack")
									spawned_boss_2:brain():set_objective(objective)
									spawned_boss_2:brain():set_logic("attack")
								end
								self:DS_BW_update_boss_logic(spawned_boss_1,spawned_boss_2,target_id)
							end
						end
					end
				end)
			end
		end
		previous_phase = self._task_data.assault.phase
		-- make break in-between 1st and 2nd assault shorter if we are playing on heists without first easy assault, to make them a bit harder. this shortens enemy respawn delay by about 30sec
		if is_heist_without_1st_assault and self._assault_number == 1 and (self._task_data.assault.phase == "anticipation" or self._task_data.assault.phase == "fade") then
			value = 0.5
		elseif value ~= 1 then
			value = 1
		end
		if self._task_data.assault.phase == "fade" then
			if DS_BW.Miniboss_info.is_alive then
				DS_BW.Miniboss_info.is_alive = false
				DS_BW.Miniboss_info.kill_counter = 0
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
				local dmg_resist_str = "50"
				if Global.level_data and Global.level_data.level_id == "mad" then
					dmg_resist_str = "75"
				end
				DS_BW.CM:public_chat_message("[DS_BW] Assault is fading, enemy damage resistance reduced back to "..dmg_resist_str.."%. Duo is gone, for now.")
			end
		end
	end
	orig_diff(self, value)
end

-- update bosses AI every 10 secs to force them to chase a chosen player untill either player or boss dies.
-- if player dies, switch targets. this should prevent bosses from getting stuck in place sometimes.
function GroupAIStateBase:DS_BW_update_boss_logic(boss_1,boss_2,target_id)
	if boss_1 and boss_2 and target_id then
		local target_loc = false
		if target_id == 1 and managers.player and managers.player:player_unit() and alive(managers.player:player_unit()) then
			target_loc = managers.player:player_unit():position()
		elseif managers and managers.network and managers.network:session() and managers.network:session():peer(target_id) then
			local peer = managers.network:session():peer(target_id)
			local unit = peer and peer:unit() or nil
			if (unit and alive(unit)) then
				target_loc = unit:position()
			end
		else
			for i=1,4 do
				if managers and managers.network and managers.network:session() and managers.network:session():peer(i) then
					local peer = managers.network:session():peer(i)
					local unit = peer and peer:unit() or nil
					if (unit and alive(unit)) then
						target_loc = unit:position()
						target_id = i
						break
					end
				end
			end
		end
		
		local objective = false
		if target_loc then
			local tracker = managers.navigation:create_nav_tracker(target_loc)
			local fin_attack_pos = mvector3.copy(tracker:lost() and tracker:field_position() or tracker:position())
			managers.navigation:destroy_nav_tracker(tracker)
			objective = {
				type = "free",
				haste = "run",
				pose = "stand",
				nav_seg = managers.navigation:get_nav_seg_from_pos(fin_attack_pos, true),
				pos = mvector3.copy(fin_attack_pos),
				forced = true,
				important = true
			}
		end
		
		-- dont update logic if they are close enough to players, because AI seems to 'reset' their animation for a second whenever they accept a new forced objective.
		if alive(boss_1) and objective then
			local players = World:find_units_quick("sphere", boss_1:position(), 800, managers.slot:get_mask("players"))
			if not (players and #players >= 1) then
				boss_1:brain():set_objective(objective)
			end
		end
		
		if alive(boss_2) and objective then
			local players = World:find_units_quick("sphere", boss_2:position(), 800, managers.slot:get_mask("players"))
			if not (players and #players >= 1) then
				boss_2:brain():set_objective(objective)
			end
		end
		
	end
	
	-- end loop if boss dead
	if not DS_BW.Miniboss_info.is_alive then
		return
	end
	
	DelayedCalls:Add("DS_BW_boss_logic_updater", 10, function()
		self:DS_BW_update_boss_logic(boss_1,boss_2,target_id)
	end)
end