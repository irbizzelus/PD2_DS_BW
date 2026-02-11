if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

if not DS_BW.HotspotLogic then

	DS_BW.HotSpotLogic = {
		_updates_delay = 4, -- update cycle delay in secs
		_last_spot_id = 1, -- each spot has it's own id, keep track of latest for new id evaluation
		_hotSpotRadius = 650, -- used for collision checks when adding new hotspots, and for distance check for players within hotspot radius
		_maxCopsPerHotSpot = 4, -- at least a 3
		Defense_positions = {
			-- note: due to the way spiral formation is caclulating next position, make sure that maxrange/minrange returns a whole number, to avoid issues. also both numbers need to be dividable by 10 as well
			min_range = 90, -- min distance away from hotspot centre and units from each other. should always be at least 70, to avoid cops from going through walls 
			max_range = 450, -- range from sentre to edge of the coord vector matrix. wouldve been called a radius, but spots are added in a spiral formation, in a squared grid.
		},
		HotSpotList = {},
		HotSpotAssignedUnits = {},
		HotSpotActiveUnits = {},
	}
	
	local function tblsize(T)
		local count = 0
		for _ in pairs(T) do count = count + 1 end
		return count
	end

	-- Find out if 2 units are enemies - b should always be enemy/cop
	function DS_BW.HotSpotLogic:AreUnitsEnemies(unit_a, unit_b)
		if not unit_a or not unit_b or not unit_a:movement() or not unit_b:movement() or not unit_a:movement():team() or not unit_b:movement():team() then
			return false
		end

		if unit_b:brain()._current_logic_name == "trade" then
			return false
		end

		return unit_a:movement():team().foes[unit_b:movement():team().id] and true or false
	end
	
	-- Enable (if possible) an endless recursive loop to maintan hotspots
	local hotspot_engine_start = 0
	function DS_BW.HotSpotLogic:MaintainHotSpotUpdates()
		
		if Network and Network:is_server() and DS_BW.DS_difficultycheck and Utils:IsInGameState() then
			-- updater itself
			self:UpdateHotSpotList()
		else
			-- remove the loop if its confirmed that we are neither in game or on DS diff after 8 attempts. timer is needed to ensure no fuckery with loading screens, due to the way this file is loaded
			hotspot_engine_start = hotspot_engine_start + 1
			if hotspot_engine_start >= 8 then
				hotspot_engine_start = nil
				return
			end
		end
		
		DelayedCalls:Add("DS_BW_hotspot_updater_maintaince", DS_BW.HotSpotLogic._updates_delay, function()
			DS_BW.HotSpotLogic.MaintainHotSpotUpdates(DS_BW.HotSpotLogic)
		end)
		
	end
	DS_BW.HotSpotLogic.MaintainHotSpotUpdates()
	
	local HotSpot_update_cycle_num = 0
	-- update our hotspot list every few secons (determined in MaintainHotSpotUpdates). this includes heat evaluation, unit allocation, hotspot creation and cleanup
	function DS_BW.HotSpotLogic:UpdateHotSpotList()
	
		-- how many seconds to wait in-between adding player-location-based hotspots
		local desired_player_update_cycle = 72
		
		desired_player_update_cycle = desired_player_update_cycle / self._updates_delay
		
		-- needed for hotspot additions for player positions
		HotSpot_update_cycle_num = HotSpot_update_cycle_num + 1
		if HotSpot_update_cycle_num > desired_player_update_cycle then
			HotSpot_update_cycle_num = 0
		end
		
		-- add hotspots to where-ever players are currently located. only do that once in a few sycles to avoid rapidly adding spots
		if desired_player_update_cycle - HotSpot_update_cycle_num <= 1 then
			local player_loc_vectors = {}
			if managers.player:player_unit() and managers.player:player_unit():position() then
				table.insert(player_loc_vectors,managers.player:player_unit():position())
			end
			for i=2,4 do
				if managers and managers.network and managers.network:session() and managers.network:session():peer(i) then
					local peer = managers.network:session():peer(i)
					local unit = peer and peer:unit() or nil
					if unit and alive(unit) then
						table.insert(player_loc_vectors,unit:position())
					end
				end
			end
			self:AddPlayerHotSpots(player_loc_vectors)
		end
		
		-- if no spots were created yet, ignore further logic
		if tblsize(self.HotSpotList) < 1 then
			return
		end
		
		local hotest_spot_1 = {id = "", heat = 0}
		local hotest_spot_2 = {id = "", heat = 0}
		local hotest_spot_3 = {id = "", heat = 0}
		
		for hotspotID, hotspotData in pairs(self.HotSpotList) do
			-- every cycle add heat to hotspots if players are close enough
			local players = World:find_units_quick("sphere", hotspotData._location, self._hotSpotRadius * 1.2 , managers.slot:get_mask("players"))
			hotspotData._heat = hotspotData._heat + (#players * 20 or 0)
			-- every update decay all hotspots
			hotspotData._heat = hotspotData._heat - 16
			-- dont let heat get infinetly high to avoid cops being stuck on the other side of the map
			if hotspotData._heat > 400 then
				hotspotData._heat = 400
			end
			
			-- looks dumb af, is dumb af, but it works :) Sorts top 3 spots from the whole list based on heat
			if hotspotData._heat > hotest_spot_1.heat then
				
				hotest_spot_3.id = hotest_spot_2.id
				hotest_spot_3.heat = hotest_spot_2.heat
				
				hotest_spot_2.id = hotest_spot_1.id
				hotest_spot_2.heat = hotest_spot_1.heat
				
				hotest_spot_1.id = hotspotID
				hotest_spot_1.heat = hotspotData._heat
				
			elseif hotspotData._heat > hotest_spot_2.heat then
			
				hotest_spot_3.id = hotest_spot_2.id
				hotest_spot_3.heat = hotest_spot_2.heat
				
				hotest_spot_2.id = hotspotID
				hotest_spot_2.heat = hotspotData._heat
				
			elseif hotspotData._heat > hotest_spot_3.heat then
			
				hotest_spot_3.id = hotspotID
				hotest_spot_3.heat = hotspotData._heat
				
			end
			
			-- remove a hotspot if it wasnt visited for long enough
			if hotspotData._heat <= -30 then
				for id, unit in pairs(self.HotSpotList[hotspotID].assigned_units) do
					self.HotSpotAssignedUnits[id] = nil
					self.HotSpotActiveUnits[id] = nil
				end
				self.HotSpotList[hotspotID] = nil
			end
		end
		
		-- after every spot heat was evaluated, set hotspot priority based on said heat
		for hotspotID, hotspotData in pairs(self.HotSpotList) do
			if hotest_spot_1.id == hotspotID then
				self.HotSpotList[hotspotID]._priority = 3
			elseif hotest_spot_2.id == hotspotID then
				self.HotSpotList[hotspotID]._priority = 2
			elseif hotest_spot_3.id == hotspotID then
				self.HotSpotList[hotspotID]._priority = 1
			else
				self.HotSpotList[hotspotID]._priority = 0
			end
			
			-- after first loop above, most 'old' hotspots will be removed. if we still have too many hotspots however, remove them more agressively
			if tblsize(self.HotSpotList) > 6 then
				if hotspotData._heat <= -20 then
					for id, unit in pairs(self.HotSpotList[hotspotID].assigned_units) do
						self.HotSpotAssignedUnits[id] = nil
						self.HotSpotActiveUnits[id] = nil
					end
					self.HotSpotList[hotspotID] = nil
				end
			end
		end
		
		-- after hotspots were assigned with priority, force bots to move to the top 3, and disengage from other areas
		for hotspotID, hotspotData in pairs(self.HotSpotList) do
			-- always assgin units to our top 3 spots
			if (hotspotData._priority == 3 or hotspotData._priority == 2 or hotspotData._priority == 1) then
				self:UpdateHighPriorityHotSpot(self.HotSpotList[hotspotID])
			elseif hotspotData._priority == 0 and tblsize(hotspotData.assigned_units) > 0 then
				self:DiscardCopsFromHotSpotArea(self.HotSpotList[hotspotID])
			end
			
			-- same as before, remove as many hotspots as we can
			if tblsize(self.HotSpotList) > 6 then
				if hotspotData._heat <= -10 then
					for id, unit in pairs(self.HotSpotList[hotspotID].assigned_units) do
						self.HotSpotAssignedUnits[id] = nil
						self.HotSpotActiveUnits[id] = nil
					end
					self.HotSpotList[hotspotID] = nil
				end
			end
		end
		
	end
	
	-- Add a hotspot based on location of all alive players on the level
	function DS_BW.HotSpotLogic:AddPlayerHotSpots(coords_list)
		
		if coords_list and #coords_list >= 1 then
			
			-- if we are playing on brooklin 10-10, disable hotspots entirely for the first 2 waves,
			-- because sometimes, VERY rarely, cops from the outside that you need to kill while protecting sheeron
			-- may stray away from their objective to try and come to the hotspot, which might cause softlocks due to shitty cop pathing
			-- since i have no clue how to identify those cops, i'll just disable this system entirely
			-- since first room objective should be easily doable during the lengthy break after 2nd wave is over
			if Global.level_data and Global.level_data.level_id and Global.level_data.level_id == "spa" and DS_BW.Assault_info.number <= 2 then
				return
			end
			
			-- find hotspot with highest player count in the radius
			local biggest_group = 0
			local result = 1
			for i=1,#coords_list do
				local players = World:find_units_quick("sphere", coords_list[i], self._hotSpotRadius * 1.2 , managers.slot:get_mask("players"))
				if #players > biggest_group then
					biggest_group = #players
					result = i
				end
			end
			
			local hotspot_loc = coords_list[result]
			
			-- if newly wanted spot is too close to an already existing spot, ignore it
			if tblsize(self.HotSpotList) >= 1 then
				for hotspotID, hotspotData in pairs(self.HotSpotList) do
					if mvector3.distance(hotspot_loc, hotspotData._location) <= (self._hotSpotRadius * 0.9) then
						return
					end
				end
			end
			
			-- add heat based on player count within range
			local players = World:find_units_quick("sphere", hotspot_loc, self._hotSpotRadius * 1.2 , managers.slot:get_mask("players"))
			local heat = 0
			if #players >= 1 then
				heat = heat + #players * 20
			end
			
			-- if newly wanted player spot has higher heat then an already existing player spot, ignore it
			if tblsize(self.HotSpotList) >= 1 then
				for hotspotID, hotspotData in pairs(self.HotSpotList) do
					if hotspotData._reason == "Player_Area" and hotspotData._heat >= heat then
						return
					end
				end
			end
			
			-- try adding multiple defence poistions
			local def_positions = self:CreateDefensivePositions(hotspot_loc)
			local def_pos_hotspot_format = {}
			if def_positions then
				for i=1,#def_positions do
					table.insert(def_pos_hotspot_format,{location = def_positions[i], occupied = false})
				end
			end
			
			self.HotSpotList["HS_"..tostring(self._last_spot_id)] = {
				_reason = "Player_Area",
				_location = hotspot_loc,
				_heat = heat,
				defense_positions = def_pos_hotspot_format,
				_priority = 0, -- updated elsewhere
				assigned_units = {} -- updated elsewhere
			}
			
			self._last_spot_id = self._last_spot_id + 1
			
		end
		
	end
	
	-- Add a "default" hotspot
	function DS_BW.HotSpotLogic:AddHotSpot(coords, interaction)
		
		-- if we are playing on brooklin 10-10, disable hotspots entirely for the first 2 waves,
		-- because sometimes, VERY rarely, cops from the outside that you need to kill while protecting sheeron
		-- may stray away from their objective to try and come to the hotspot, which might cause softlocks due to shitty cop pathing
		-- since i have no clue how to identify those cops, i'll just disable this system entirely
		-- since first room objective should be easily doable during the lengthy break after 2nd wave is over
		if Global.level_data and Global.level_data.level_id and Global.level_data.level_id == "spa" and DS_BW.Assault_info.number <= 2 then
			return
		end
		
		local function interaction_value(int_str)
			
			-- hotspot's default heat level depends on the interaction that this spot was added from.
			local int_values = {
				ammo_bag = 240,
				take_ammo = 240, -- in-heist shelves
				doctor_bag = 240,
				grenade_briefcase = 120,
				grenade_crate = 120,
				drill = 400,
				drill_jammed = 400,
				drill_upgrade = 400,
				gen_pku_saw = 120, -- no mercy (at least, maybe more heists?) saw - pick up
				gen_int_saw = 400, -- install
				gen_int_saw_jammed = 400, -- repair
				hostage_stay = 400, -- telling hostage to stay here. kinda evil ngl
				apartment_saw = 400, -- panic room. also green bridge trucks cuz asset reusage is pretty good
				pick_lock_hard_no_skill = 240, -- good name
				pick_lock_easy_no_skill = 240,
				lockpick_locker = 120,
				zipline_mount = 120,
				security_station_keyboard = 120, -- computer hack
				hold_take_sample = 240, -- nmh
				lance = 400, -- drill but different
				lance_jammed = 400,
				lance_upgrade = 400,
				hack_ship_control = 240, -- bomb dockyard
				din_crane_control = 320, -- slaughterhouse, ending
				hack_suburbia_outline = 320, -- pc hack, seems to be multi-heist
				hack_suburbia_jammed_y = 320,
				thermite = 120, -- placing interaction (i think?)
				hold_pku_briefcase = 80,
				hold_circle_cutter = 180, -- brookln bank and (probably) alesso saws
				circle_cutter_jammed = 180,
				gen_pku_circle_cutter = 60, -- pickup
				mcm_laptop = 240,
				hold_search_fridge = 80, -- henry's rock
				hold_add_compound_a = 320,
				hold_add_compound_b = 320,
				hold_add_compound_c = 320,
				hold_add_compound_d = 320,
				hack_ipad = 180,
				hold_move_crane = 180,
				
				-- NEGATIVE - practically ignore these interacts, unless 4 players are around this objective, and stay there for long
				-- item pick up interacts, means bag will be moved
				pku_pig = -69,
				weapon_case = -69,
				take_weapons = -69,
				hold_take_gas_can = -69,
				carry_drop = -69, -- dropped bag
				pku_pig = -69,
				gen_pku_cocaine = -69,
				gen_pku_jewelry = -69,
				gen_pku_artifact = -69,
				hold_pku_disassemble_cro_loot = -69,
				hold_pickup_lance = -69,
				gold_pile = -69,
				money_wrap = -69,
				gen_pku_thermite_timer = -69,
				-- other
				crate_loot_crowbar = -69, -- crate opening
				hostage_trade = -69,
				hostage_move = -69,
				open_train_cargo_door = -69,
				shape_charge_plantable = -69,
				hold_open_bomb_case = -69, -- butcher bomb heists
				embassy_door = -69, -- heat street 1st door
				intimidate = -69, -- civs
				hostage_convert = -69,
				bodybags_bag = -69, -- stealth deployable
				sentry_gun = -69, -- pick up
				c4_bag = -69,
				c4_consume = -69,
				gage_assignment = -69, -- mod packs
				money_small = -69, --???
				c4 = -69,
				pry_open_door_elevator = -69,
				hold_open_hatch = -69,
				hold_cut_tarp = -69,
				hold_search_dumpster = -69,
				hold_search_toilet = -69,
				hold_search_documents = -69,
				cut_fence = -69,
			}
			
			if int_values[interaction] then
				return int_values[interaction]
			else
				----------------- yes this is how i added most of them, instead of going through a file that contains all interacts. dont judge me.
				-- these interacts are not as unimportant as door openings and bag pickups, but they are also not important enough to be more then 0
				local ignored_interacts = {
					"revive",
					"free",
					"first_aid_kit",
					"invisible_interaction_open",
					"din_hold_ignite_trap",
					"c4_bag_dynamic",
					"apply_thermite_paste_no_consume",
					"sentry_gun_revive", -- non vanilla option btw
					"disassemble_turret",
				}
				if not table.contains(ignored_interacts, int_str) then
					--log("[DS_BW] Unknown hotspot interaction: '"..interaction.."'")
				end
				----------------- debug
				return 0
			end
		end
		
		-- assign base value for hotspot's heat. value based on type of interaction
		local default_heat = 0
		if interaction then
			default_heat = interaction_value(interaction)
		end
		
		-- if newly wanted spot is too close to an already existing spot, ignore it
		if tblsize(self.HotSpotList) >= 1 then
			for hotspotID, hotspotData in pairs(self.HotSpotList) do
				if mvector3.distance(coords, hotspotData._location) <= self._hotSpotRadius then
					
					-- before exiting hotspot adding logic, we can add some heat to an allready existing hotspot at close location.
					-- only do that for objective stuff tho
					local obj_interacts = {
						drill = 200,
						drill_jammed = 200,
						drill_upgrade = 200,
						gen_pku_saw = 60, -- no mercy (at least, maybe more heists?) saw - pick up
						gen_int_saw = 200, -- install
						gen_int_saw_jammed = 200, -- repair
						apartment_saw = 200, -- panic room. also green bridge trucks cuz asset reusage is pretty good
						security_station_keyboard = 60, -- computer hack
						hold_take_sample = 120, -- nmh
						lance = 200, -- drill but different
						lance_jammed = 200,
						lance_upgrade = 200,
						hack_ship_control = 120, -- bomb dockyard
						hack_suburbia_outline = 160, -- pc hack, seems to be multi-heist
						hack_suburbia_jammed_y = 160,
						hold_circle_cutter = 90, -- brookln bank and (probably) alesso saws
						circle_cutter_jammed = 90,
						mcm_laptop = 120,
						hold_add_compound_a = 160,
						hold_add_compound_b = 160,
						hold_add_compound_c = 160,
						hold_add_compound_d = 160,
					}
					if obj_interacts[tostring(interaction)] then
						hotspotData._heat = hotspotData._heat + (obj_interacts[tostring(interaction)] or 0)
					end
					
					return
				end
			end
		end
		
		-- try adding multiple defence poistions
		local def_positions = self:CreateDefensivePositions(coords)
		local def_pos_hotspot_format = {}
		if def_positions then
			for i=1,#def_positions do
				table.insert(def_pos_hotspot_format,{location = def_positions[i], occupied = false})
			end
		end
		
		-- add heat based on player count within range
		local players = World:find_units_quick("sphere", coords, self._hotSpotRadius * 1.2 , managers.slot:get_mask("players"))
		if #players >= 1 then
			default_heat = default_heat + #players * 20
		end
		
		self.HotSpotList["HS_"..tostring(self._last_spot_id)] = {
			_reason = interaction,
			_location = coords,
			_heat = default_heat,
			defense_positions = def_pos_hotspot_format,
			_priority = 0, -- updated elsewhere
			assigned_units = {} -- updated elsewhere
		}
		
		self._last_spot_id = self._last_spot_id + 1
		
	end
	
	-- find and create valid positions in space where hotspot guards can stand
	-- returns list with found locations
	function DS_BW.HotSpotLogic:CreateDefensivePositions(coords)
		
		if not coords then
			log("[DS_BW] Critical error warning: hotspot defensive positions were not established, because hotspot coordinates are missing.")
			return
		end
		
		-- always default at least 1 position to hotspot origin
		local final_positions = {}
		table.insert(final_positions,coords)
		
		local function is_position_valid(attempting_pos)
			-- draw a ray in the attempting direction (slighlty elavate vertical position (z) to avoid floor cliping in rare cases)
			-- ray is drawn from hotspot centre, into attempting direction, checking for walls.
			local ray_dir = attempting_pos
			local wallhit = World:raycast("ray", Vector3(coords.x, coords.y, coords.z+20), ray_dir, "slot_mask", managers.slot:get_mask("bullet_impact_targets"))
			-- if no walls hit, proceed
			if not wallhit then
				-- draw a ray straight down untill floor is hit, to finalize the vector
				local vertical_ray = ray_dir + Vector3(0,0,-500)
				local floorhit = World:raycast("ray", ray_dir, vertical_ray, "slot_mask", managers.slot:get_mask("bullet_impact_targets"))
				-- if floor hit was too far from original position, disregard this attempt
				if floorhit and (math.abs(floorhit.hit_position.z - ray_dir.z) <= 70) then
					ray_dir = Vector3(ray_dir.x, ray_dir.y, floorhit.hit_position.z)
					-- make sure position is not too close to hotspot centre
					local dist = mvector3.distance(final_positions[1], ray_dir)
					if dist >= self.Defense_positions.min_range then
						-- if final position is valid till this point, make sure there is enough room around it, so that our cop friends would be comfortable here
						local comf_raycast_1 = World:raycast("ray", ray_dir + Vector3(40,40,10), ray_dir + Vector3(-40,-40,10), "slot_mask", managers.slot:get_mask("bullet_impact_targets"))
						local comf_raycast_2 = World:raycast("ray", ray_dir + Vector3(-40,40,10), ray_dir + Vector3(40,-40,10), "slot_mask", managers.slot:get_mask("bullet_impact_targets"))
						if not comf_raycast_1 and not comf_raycast_2 then
							local tracker = managers.navigation:create_nav_tracker(ray_dir)
							local fin_def_pos = mvector3.copy(tracker:lost() and tracker:field_position() or tracker:position())
							managers.navigation:destroy_nav_tracker(tracker)
							return fin_def_pos
						end
					end
				end
			end
			return false
		end
		
		-- goes through coordinates in a spiral formation - right, top, left, bottom, repeat.
		-- every minimal step (aka min distance from centre and between guards) check if position is valid
		local function check_positions_in_spiral(max_range, min_step)
			-- coords are reduced by 10 to make calculations easier, before finalizing they return to full
			min_step = min_step/10
			local x = 0
			local y = 0
			local dx = 0
			local dy = -min_step
			local lx = 0
			local ly = 0
			local matrix_border_length = max_range * 0.2
			for i=0, matrix_border_length^2, min_step do
				if (-matrix_border_length/2 < x and x <= matrix_border_length/2) and (-matrix_border_length/2 < y and y <= matrix_border_length/2) then
					if not (lx==x and ly==y) then
						-- if new adjustment was made across y axis, go across y from last to new, while trying to add a position on this line.
						-- if successfull, break, and continue moving
						if lx==x then
							local negat = 1
							if y - ly < 0 then negat=-1 end
							for j=ly,y,1*negat do
								local attempting_pos = coords + Vector3(x*10, y*10, 0)
								local valid_vector = is_position_valid(attempting_pos)
								if valid_vector then
									table.insert(final_positions, valid_vector)
									break
								end
							end
						elseif ly==y then -- same across x
							local negat = 1
							if x - lx < 0 then negat=-1 end
							for j=lx,x,1*negat do
								local attempting_pos = coords + Vector3(x*10, y*10, 0)
								local valid_vector = is_position_valid(attempting_pos)
								if valid_vector then
									table.insert(final_positions, valid_vector)
									break
								end
							end
						end
					end
					if #final_positions >= (self._maxCopsPerHotSpot + 1) then -- if enough, break matrix scan loop
						break
					end
					lx = x
					ly = y
				end
				if x == y or (x < 0 and x == -y) or (x > 0 and x == min_step-y) then
					dx, dy = -1*dy, dx
				end
				x, y = x+dx, y+dy
			end
		end
		check_positions_in_spiral(self.Defense_positions.max_range, self.Defense_positions.min_range)
		
		return final_positions
	end
	
	-- stop cops when they are done walking to defense spot
	function DS_BW.HotSpotLogic:OnCopArrivedAtHotSpot(clbk_data)
		
		if Network and Network:is_client() then
			return
		end
		
		local cop = clbk_data.cop
		local hotspot = clbk_data.hotspot
		if not alive(cop) or cop:character_damage():dead() then
			hotspot.assigned_units[tostring(cop:id())] = nil
			self.HotSpotAssignedUnits[tostring(cop:id())] = nil
			self.HotSpotActiveUnits[tostring(cop:id())] = nil
			for i=1, #hotspot.defense_positions do
				if hotspot.defense_positions[i].occupied and hotspot.defense_positions[i].occupied == tostring(cop:id()) then
					hotspot.defense_positions[i].occupied = false
				end
			end
			return
		end
		
		-- on arival add this unit to active units table. enemies in this table are never allowed to walk in copmovement.lua file, thus leting them actualy guard the hotspot
		-- i spend too much time trying to figure out how to make them stand the fuck still by altering their behaviour logic, so this much simpler solution will have to do.
		self.HotSpotActiveUnits[tostring(cop:id())] = true
		--cop:contour():add("generic_interactable_selected" , true) -- debug
	end
	
	-- assign cops to hotspots, or update already assigned cops.
	function DS_BW.HotSpotLogic:UpdateHighPriorityHotSpot(hotspot)
		
		if Network and Network:is_client() then
			return
		end

		if managers.groupai:state():whisper_mode() then
			return
		end
		
		-- highest priority gets max, then -1, then -2, to avoid huge groups from being wasted on such tasks
		local function get_max_cop_amount(hotspot)
			local max_cops = self._maxCopsPerHotSpot
			if hotspot._priority == 2 then
				max_cops = max_cops - 1
			elseif hotspot._priority == 1 then
				max_cops = max_cops - 2
			elseif hotspot._priority ~= 3 then
				log("[DS_BW] High priority hotspot updater got a request from a non-high priority hotspot. wtf?")
			end
			return max_cops
		end
		
		-- later we need to check if enemy is actualy an enemy when compared to players, for that we would need to grab a player unit
		local player_unit
		if managers.player and managers.player:player_unit() and alive(managers.player:player_unit()) then
			-- host
			player_unit = managers.player:player_unit()
		else
			-- if host is dead compare to another player in the lobby. if no player is found, all players are dead, so hotspot assignment is not needed. areunitsenemies func has sanity checks to avoid crashes
			for i=2,4 do
				if managers and managers.network and managers.network:session() then
					local peer = managers.network:session():peer(i)
					local unit = peer and peer:unit() or nil
					if (unit and alive(unit)) then
						player_unit = managers.network:session():peer(i):unit()
						break
					end
				end
			end
		end
			
		-- update cops assigned to the hotspot
		if player_unit then
			for id, unit in pairs(hotspot.assigned_units) do
				if not alive(unit) or unit:character_damage():dead() then -- death check
					hotspot.assigned_units[id] = nil
					self.HotSpotAssignedUnits[id] = nil
					self.HotSpotActiveUnits[id] = nil
					for i=1, #hotspot.defense_positions do
						if hotspot.defense_positions[i].occupied and hotspot.defense_positions[i].occupied == id then
							hotspot.defense_positions[i].occupied = false
						end
					end
				else -- check if hotspot guard is still an enemy. if converted, remove him
					if not self:AreUnitsEnemies(player_unit, unit) then
						hotspot.assigned_units[id] = nil
						self.HotSpotAssignedUnits[id] = nil
						self.HotSpotActiveUnits[id] = nil
						for i=1, #hotspot.defense_positions do
							if hotspot.defense_positions[i].occupied and hotspot.defense_positions[i].occupied == id then
								hotspot.defense_positions[i].occupied = false
							end
						end
					end
				end
			end
		end
		
		if player_unit and #hotspot.assigned_units < get_max_cop_amount(hotspot) then -- add more
			
			local max_enemy_range = 2000
			if Global and Global.level_data then
				local big_maps = {
					peta = 6000,
					crojob3 = 7500,
					crojob3_night = 7500,
					arm_for = 3500,
					corp = 3500,
					red2 = 2500,
					traip = 3500,
					ranc = 3500,
					kenaz = 3500,
					chca = 4000,
					alex_3 = 5000,
					watchdogs_1 = 3500,
					watchdogs_1_night = 3500,
					pbr2 = 3500,
					jolly = 3500,
				}
				if big_maps[Global.level_data.level_id] then
					max_enemy_range = big_maps[Global.level_data.level_id]
				end
			end
			
			local hotspot_position = hotspot._location
			
			local enemies = World:find_units_quick("sphere", hotspot_position, max_enemy_range, managers.slot:get_mask("enemies"))
			if enemies and #enemies >= 1 then
				
				-- temp objective to check if unit can do it. afterwards we assign them same objective but with a slightly different destination coords and a complete callback
				local objective = {
					type = "free",
					haste = "run",
					pose = "stand",
					nav_seg = managers.navigation:get_nav_seg_from_pos(hotspot_position, true),
					pos = mvector3.copy(hotspot_position),
					important = true
				}
				
				-- Check every enemy in 20m radius, make sure its a valid enemy for the task, and assign them to attack a hotspot
				local enemies_to_assign = get_max_cop_amount(hotspot) - tblsize(hotspot.assigned_units)
				for i, enemy in pairs(enemies) do
					local ignored_logics = {
						inactive = true,
						intimidated = true,
					}
					if self:AreUnitsEnemies(player_unit, enemy) and not ignored_logics[enemy:brain()._current_logic_name] then
						local enemy_chartweak = enemy:base():char_tweak()
						-- avoid snipers from ditching their sniper spots (ngl if was pretty funny tho), and some other units from attacking hotspots
						if enemy_chartweak.access and enemy_chartweak.access ~= "tank" and enemy_chartweak.access ~= "gangster" and enemy_chartweak.access ~= "sniper" and enemy_chartweak.access ~= "spooc" and enemy_chartweak.tags and not table.contains(enemy_chartweak.tags, "phalanx_vip") and not table.contains(enemy_chartweak.tags, "DS_BW_tag_reinforced_shield") and not table.contains(enemy_chartweak.tags, "DS_BW_tag_miniboss") then
							-- make sure cop doesnt belong to another hotspot already
							if enemies_to_assign > 0 and not self.HotSpotAssignedUnits[tostring(enemy:id())] and enemy:brain():is_available_for_assignment(objective) then
								enemies_to_assign = enemies_to_assign - 1
								-- default to centre of the hotspot
								local pos_to_defend = hotspot._location
								if #hotspot.defense_positions >= 2 then
									for j=2,#hotspot.defense_positions do
										if not hotspot.defense_positions[j].occupied then
											pos_to_defend = hotspot.defense_positions[j].location
											hotspot.defense_positions[j].occupied = tostring(enemy:id())
											break
										end
									end
								end
								-- if last cop that was assigned couldnt find a better position then hotspot centre, that means we dont have anymore room for him
								-- so we quit this loop early, to avoid cops sitting inside of each other
								if pos_to_defend == hotspot._location then
									if hotspot.defense_positions[1] and not hotspot.defense_positions[1].occupied then
										hotspot.defense_positions[1].occupied = tostring(enemy:id())
										enemies_to_assign = 0
									else
										enemies_to_assign = 0
										return
									end
								end
								objective = {
									type = "free",
									haste = "run",
									pose = "stand",
									nav_seg = managers.navigation:get_nav_seg_from_pos(pos_to_defend, true),
									pos = mvector3.copy(pos_to_defend),
									forced = true,
									complete_clbk = callback(self, self, 'OnCopArrivedAtHotSpot', {obj_pos = pos_to_defend, hotspot = hotspot,cop = enemy}),
									important = true
								}
								enemy:brain():set_objective(objective)
								hotspot.assigned_units[tostring(enemy:id())] = enemy
								self.HotSpotAssignedUnits[tostring(enemy:id())] = true
							end
						end
					end
				end
			end
		
		end
		
	end
	
	-- if hotspot is abandoned, force hotspot guards to attack player's position
	function DS_BW.HotSpotLogic:DiscardCopsFromHotSpotArea(hotspot)
		
		if Network and Network:is_client() then
			return
		end

		if managers.groupai:state():whisper_mode() then
			return
		end
		
		for id, unit in pairs(hotspot.assigned_units) do
			
			self.HotSpotAssignedUnits[id] = nil
			self.HotSpotActiveUnits[id] = nil
			
			for i=1, #hotspot.defense_positions do
				if hotspot.defense_positions[i].occupied and hotspot.defense_positions[i].occupied == id then
					hotspot.defense_positions[i].occupied = false
				end
			end
			
			if alive(unit) and not unit:character_damage():dead() then
				
				-- try moving them to players
				local players = World:find_units_quick("sphere", unit:position(), 30000, managers.slot:get_mask("players"))
				local target = 0
				
				if #players >=1 then
					target = players[1]:position()
				end
				
				if target ~= 0 then
					local objective = {
						type = "assault_area",
						haste = "run",
						pose = "stand",
						nav_seg = managers.navigation:get_nav_seg_from_pos(target, true),
						pos = mvector3.copy(target),
						forced = true,
						important = true
					}
					unit:brain():set_objective(objective)
				end
				
			end
			
		end
		hotspot.assigned_units = {}
		
	end
	
end