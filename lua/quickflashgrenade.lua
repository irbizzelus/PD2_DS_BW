-- activate firetrap on flashbang explosion - main part
-- update function is called in about 20 times a second, but we need to only role our nade chance once, so track them
local DS_BW_flashbang_roll_tracker = {}
local orig_update = QuickFlashGrenade.update
function QuickFlashGrenade:update(unit, t, dt)
	
	if (Network and not Network:is_server()) or (Network:is_server() and not DS_BW.DS_difficultycheck) then
		orig_update(self, unit, t, dt)
		return
	end
	
	if not DS_BW_flashbang_roll_tracker[self._unit:id()] then
		DS_BW_flashbang_roll_tracker[self._unit:id()] = "about_to_explode"
	end
	
	-- if in last stage, with a short timer, wasnt proccessed yet, and is still alive, try swaping for firetrap
	if self._state == 3 and self:timer() <= 0.05 and DS_BW_flashbang_roll_tracker[self._unit:id()] == "about_to_explode" and not self._destroyed then
		DS_BW_flashbang_roll_tracker[self._unit:id()] = "exploded"
		if math.random() <= 0.75 then -- chance to replace flashbang with new fire/explosive trap
			if math.random() <= 0.4 then -- chance for explosive, otherwise fire
				-- explosive
					
				-- find a valid player to give owndership of the projectile to
				local alive_player = 0
				if managers.player and managers.player:player_unit() and alive(managers.player:player_unit()) then
					alive_player = 1
				else
					for i=2,4 do
						if managers and managers.network and managers.network:session() then
							local peer = managers.network:session():peer(i)
							local unit = peer and peer:unit() or nil
							if (unit and alive(unit)) then
								alive_player = i
								break
							end
						end
					end
				end
				
				-- if valid player was not found, this part is skipped, flash is never destroyed, and we fall back on orig func
				if alive_player > 0 then
					-- destroy og flash
					if self and self._unit and alive(self._unit) then
						self:on_flashbang_destroyed()
					end
					
					local owner_id = managers.network:session():peer(alive_player):id()

					DS_BW._creating_explosive_flashbang_trap = true
					
					-- rocket from a 1300 grenade launcher
					local projectile_str = "launcher_frag_m32"
					if math.random() <= 0.25 then
						-- 10% chance for the scarface pack rocket
						projectile_str = "rocket_ray_frag"
					end
					
					-- spawn nade
					local nade = ProjectileBase.throw_projectile(projectile_str, self._unit:position() + Vector3(0, 0, 1), Vector3(0, 0, 0), owner_id)
					if nade then
						if not DS_BW.explosive_trap_ids then
							DS_BW.explosive_trap_ids = {}
						end
						DS_BW.explosive_trap_ids[nade:id()] = true
					end
				end
			else
				-- fire
				
				-- its impossible to spawn a 'standard' fire projectile (one that can properly sync) without an owner
				-- this way has a flaw: credit for this projectile damage will go to the assigned player - this includes killed civilians
				-- to prevent this - solutions were added to files copdamage.lua, firemanager.lua and enveffecttweakdata.lua, because thankfully,
				-- most projectiles are fully handled by the host, so even if projectile owner will be a different player, it will still not give them penalties for killing civs
				
				-- find a valid player to give owndership of the projectile to
				local alive_player = 0
				if managers.player and managers.player:player_unit() and alive(managers.player:player_unit()) then
					alive_player = 1
				else
					for i=2,4 do
						if managers and managers.network and managers.network:session() then
							local peer = managers.network:session():peer(i)
							local unit = peer and peer:unit() or nil
							if (unit and alive(unit)) then
								alive_player = i
								break
							end
						end
					end
				end
				
				-- if valid player was not found, this part is skipped, flash is never destroyed, and we fall back on orig func
				if alive_player > 0 then
					-- destroy og flash
					if self and self._unit and alive(self._unit) then
						self:on_flashbang_destroyed()
					end
					
					local owner_id = managers.network:session():peer(alive_player):id()

					DS_BW._creating_fire_trap = true

					-- spawn nade
					local nade = ProjectileBase.throw_projectile("launcher_incendiary_m32", self._unit:position() + Vector3(0, 0, 1), Vector3(0, 0, 0), owner_id)
					if nade then
						if not DS_BW.firetrap_ids then
							DS_BW.firetrap_ids = {}
						end
						DS_BW.firetrap_ids[nade:id()] = true
					end
				end
			end
		end
	end
	
	orig_update(self, unit, t, dt)
end