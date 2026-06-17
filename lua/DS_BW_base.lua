-- Main global vars, default settings and utility functions
-- Death Sentence, But Worse. Title is WIP but i prob wont change it cuz im not creative enough.
if not DS_BW then
    _G.DS_BW = {}
	DS_BW._path = ModPath
    DS_BW.DS_difficultycheck = false
	DS_BW.version = "1.5.12" -- this one is used for the welcoming message mainly. if you update DSBW's code to your liking, please update this value to something like "HOMEBREW" :)
	DS_BW.version_num = 1.51 -- this one is used for comparing to the current save file. only update if the pop up changelog message with important patch info needs to appear
	DS_BW.settings = {
		-- gameplay
		always_hard_heists = false,
		starting_adapt_diff = 1,
		ADL_announcements = true,
		tasks_per_min_mul = 1,
		-- info msg
		skills_showcase = 2,
		hourinfo = true,
		infamy = true,
		-- end score
		endstats_enabled = true,
		endstats_public = true,
		endstats_specials = true,
		endstats_headshots = false,
		endstats_accuracy = false,
		-- misc
		lobbyname = true,	
    }
	DS_BW.Assault_info = {
		phase = "breachingbreeches",
		number = -1,
		is_infinite = false
    }
	DS_BW.Miniboss_info = {
		kill_counter = 0,
		appearances = 0,
		is_alive = false,
		has_spawned_this_wave = false,
		spawn_chance = {current = 0.1, increase = 0.1}, -- uses current as base, because it's never resest
		spawn_locations = {}
    }
	DS_BW.players = {}
	for i=1,4 do
		DS_BW.players[i] = {
			skills_shown = false,
			hours_shown = false,
			welcome_msg1_shown = false,
			welcome_msg2_shown = false,
			requested_mods_1 = false,
			requested_mods_2 = false,
		}
	end
	DS_BW._low_spawns_manager = {
		level = 0,
		detected_low = false,
		detected_high = false,
		adjustment_cooldown = -999
	}
	DS_BW.kpm_tracker = {
		DR_update_cooldown = -1,
		update_after = -999,
		kills = {0,0,0,0},
		kpm = {0,0,0,0},
		downed_this_update = {false,false,false,false},
		penalties = {
			{is_perma = false, amount = 0, was_notified_of = 0},
			{is_perma = false, amount = 0, was_notified_of = 0},
			{is_perma = false, amount = 0, was_notified_of = 0},
			{is_perma = false, amount = 0, was_notified_of = 0}
		},
		thresholds = {
			[1] = 12,
			[2] = 16,
			[3] = 24,
			[4] = 35,
			[5] = 48,
		},
		down_adjustmets_per_lvl = {
			[0] = 4,
			[1] = 4,
			[2] = 5,
			[3] = 7,
			[4] = 10,
			[5] = 14,
		}
	}
	DS_BW.color = Color(255,240,140,35) / 255
	DS_BW.end_stats_printed = false
	DS_BW.peers_with_mod = {}

    function DS_BW:Save()
        local file = io.open(SavePath .. 'DS_BW_save.txt', 'w+')
        if file then
            file:write(json.encode(DS_BW.settings))
            file:close()
        end
    end
    
    function DS_BW:Load()
        local file = io.open(SavePath .. 'DS_BW_save.txt', 'r')
        if file then
            for k, v in pairs(json.decode(file:read('*all')) or {}) do
                DS_BW.settings[k] = v
            end
            file:close()
        end
    end
    
    -- Load the config in a pcall to prevent any corrupt config issues.
    local configResult = pcall(function()
        DS_BW:Load()
    end)

    -- Notify the user if something went wrong
    if not configResult then
        Hooks:Add("MenuManagerOnOpenMenu", "DS_BW_configcorrupted", function(menu_manager, nodes)            
            QuickMenu:new("DS_BW Error", "Your 'Death Sentence, But Worse' options file was corrupted, all the mod options have been reset to defaults.", {
                [1] = {
                    text = "OK",
                    is_cancel_button = true
                }
            }):show()
        end)
    end

    -- Generate save data even if nobody ever touches the mod options menu.
    -- This also regenerates a "fresh" config if it's corrupted.
    DS_BW:Save()

	function DS_BW.change_lobby_name(is_DS)
		if managers.network.matchmake._lobby_attributes and managers.network.matchmake.lobby_handler then
			local cur_name = tostring(managers.network.matchmake._lobby_attributes.owner_name)
			local new_name = "DS, but Worse ("..managers.network.account:username()..")"
			if not is_DS then
				new_name = managers.network.account:username()
			end
			if cur_name ~= new_name then
				managers.network.matchmake._lobby_attributes.owner_name = new_name
				managers.network.matchmake.lobby_handler:set_lobby_data(managers.network.matchmake._lobby_attributes)
			end
		end
	end
	
	function DS_BW:update_kpm_stats()
		if Application:time() > DS_BW.kpm_tracker.update_after then
			if DS_BW.Assault_info and (DS_BW.Assault_info.phase == "build" or DS_BW.Assault_info.phase == "sustain") then
				DS_BW.kpm_tracker.update_after = Application:time() + 30
				for i=1,4 do
					if DS_BW.kpm_tracker.kills[i] > 0 then
						DS_BW.kpm_tracker.kpm[i] = DS_BW.kpm_tracker.kills[i] * 2
					else
						DS_BW.kpm_tracker.kpm[i] = 0
					end
					if not DS_BW.kpm_tracker.downed_this_update[i] then
						DS_BW.kpm_tracker.kills[i] = DS_BW.kpm_tracker.kills[i] + DS_BW.kpm_tracker.down_adjustmets_per_lvl[DS_BW._low_spawns_manager.level] * 0.5
					end
				end
				DS_BW.kpm_tracker.kills = {0,0,0,0}
				DS_BW.kpm_tracker.downed_this_update = {false,false,false,false}
			end
		end
		DelayedCalls:Add("DS_BW_kpm_updater", 0.05, function()
			DS_BW.kpm_updating = true
			DS_BW:update_kpm_stats()
		end)
	end
	
	function DS_BW:is_hard_heist()
		-- most heists will follow a rule where first assault is easier then 2nd and onward.
		-- sometimes however, it makes no logicas sense to have 'recon' easy assaults at the begining because a heist could be a set up (like alaska)
		-- in such cases we skip first assault. also aplies to heists that are in general slower paced at the start (like harvest and trustee branchbank)
		local heists = {
			"branchbank",
			"rvd1", -- reserviour dogs
			"rvd2",
			"nail", -- haloween heists
			"hvh",
			"help",
			"firestarter_1", -- mhm
			"firestarter_2",
			"firestarter_3",
			"watchdogs_1_night",
			"watchdogs_1",
			"watchdogs_2",
			"watchdogs_2_day",
			"alex_3", -- rats 3
			"pex", -- breakfast in tihuana
			"bph", -- hell's island
			"brb", -- Brooklyn bank
			"vit", -- white house
			"hox_1", -- breakout
			"hox_2",
			"framing_frame_2", -- mhm
			"chew", -- biker heist day 2
			"pines", -- vlad's white xmas
			"run", -- heat street
			"man", -- undercover
			"pal", -- counterfeit, cause its too short
			"firestarter_3", -- mhm
			"mad", -- boil point
			"wwh", -- alaska
			"mallcrasher", -- alaska, trust me bro
			"peta2", -- goats
			"escape_overpass",
			"escape_overpass_night",
			"escape_park",
			"escape_park_day",
			"escape_cafe",
			"escape_cafe_day",
			"escape_street",
			"escape_garage",
			"chill_combat", -- safe house defense
			-- custom heists, cause why not
			"ArmsRace",
		}
		
		if DS_BW.settings.always_hard_heists then
			return true
		elseif Global.level_data and Global.level_data.level_id and (table.contains(heists, Global.level_data.level_id)) then
			return true
		else
			return false
		end
	end
	
	-- returns 2 vars, first is the new position, and the second is reporting if the map has cpt in vanilla or not
	function DS_BW:_new_captain_winters_position()
		-- new location for cpt.winters for maps that by default spawn cap
		local new_vanilla_phalanx_positions = {
			alex_1 = { -- Hector: Rats 1
				Vector3(421, -1194, 869),
			},
			rat = { -- Bain: Cook off
				Vector3(421, -1194, 869),
			},
			wwh = { -- Locke: alaska
				Vector3(6010, -1125, 1352),
				Vector3(5055, 5660, 1223),
			},
			big = { -- Dentist: big bank
				Vector3(1155, 2031, 227),
			},
			pal = { -- Classics: counterfeit
				Vector3(-101, 10.8, 23),
				Vector3(-6017, 5072, 41),
			},
			mus = { -- Dentist: diamond
				Vector3(-4729, -944, -994),
				Vector3(-4415, 2693.5, -940.5),
			},
			mia_1 = { -- Dentist: hotline miami day 1
				Vector3(-3389.5, -3234, 2),
			},
			branchbank = { -- Bain: bank (all of em)
				Vector3(-7207.5, -3980.5, -7),
			},
			family = { -- Bain: diamond store
				Vector3(-622, 3783, -17.5),
				Vector3(-2929, -3753, -18),
			},
			election_day_1 = { -- Elephant
				Vector3(4853.3, -3006.8, 2),
				Vector3(5466.6, 2822.9, 102),
				Vector3(60.4, -1827.9, 2),
			},
			welcome_to_the_jungle_1 = { -- Elephant: big oil 1
				Vector3(46629.5, -7538.8, -20),
				Vector3(7210.8, -2220, -20),
			},
			welcome_to_the_jungle_2 = { -- Elephant: big oil 2
				Vector3(-5226.5, -2667.5, -3),
				Vector3(-5560.5, 5066.8, 68),
			},
		}
		-- positions for cap for maps that normally don't spawn him
		local new_phalanx_positions = {
			roberts = { -- go bank
				Vector3(2184, -4525, -64),
			},
			red2 = { -- FWB
				Vector3(-4271, -2011, -123),
			},
			glace = { -- Green bridge
				Vector3(-1323, -17519, 5804),
			},
			nmh = { -- No Mercy
				Vector3(2829, 427, 2),
			},
			brb = { -- Brooklyn bank
				Vector3(4200, -3090, -16),
				Vector3(-298, 418, 7),
			},
			dah = { -- Classics: diamonds
				Vector3(-1095, -420, 777),
			},
			flat = { -- Classics: panic room
				Vector3(-3288, -36, -22),
			},
			man = { -- Classics: undercover
				Vector3(-837, -794, 1709),
			},
			run = { -- Classics: heat street
				Vector3(-8293, -4926, 40),
			},
			mia_2 = { -- Dentist: hotline miami day 2
				Vector3(140, -101, -5),
			},
			rvd1 = { -- Bain: Reserviour dogs day 1 (canonical 2nd)
				Vector3(-9, 3168.5, 2),
			},
			rvd2 = { -- Bain: Reserviour dogs day 2 (canonical 1st)
				Vector3(963, 4925.5, -18),
			},
			trai = { -- McShay: Train
				Vector3(3145, -126, -9),
			},
			watchdogs_2 = { -- Hector
				Vector3(-2503.5, 168.8, 2),
			},
			watchdogs_2_day = { -- Hector
				Vector3(-2503.5, 168.8, 2),
			},
			sah = { -- Locke: auction
				Vector3(1459.2, -2260.6, -95),
				Vector3(-2318.9, -608.6, -143),
			},
			born = { -- Dentist: biker heist 1
				Vector3(1248.5, 2589.5, 2),
			},
			arm_for = { -- Bain: transport: train
				Vector3(-3961.7, -7422.1, -887),
			},
			friend = { -- Butcher: sosa
				Vector3(8245.2, -3133.6, -775),
				Vector3(3600.8, 5207.5, -147),
			},
			crojob3 = { -- Butcher: forest
				Vector3(6426.1, -11229.2, 1419),
				Vector3(1452.7, 6982, 5243),
			},
			kenaz = { -- Dentist: grin casino
				Vector3(1554, -10124, -395),
				Vector3(-4285.5, -4785.3, -98),
			},
			chca = { -- Vlad: Black cat
				Vector3(-9310, 16997.3, 102),
			},
			four_stores = { -- Vlad
				Vector3(2772.1, -1541.4, 27),
			},
			mallcrasher = { -- Vlad
				Vector3(2594, 1746.8, -413),
			},
			nightclub = { -- Vlad
				Vector3(-1340.1, -3204.5, 7),
			},
		}
		
		if Global and Global.level_data and new_vanilla_phalanx_positions[Global.level_data.level_id] then
			return new_vanilla_phalanx_positions[Global.level_data.level_id][math.random(1,#new_vanilla_phalanx_positions[Global.level_data.level_id])], true
		elseif Global and Global.level_data and new_phalanx_positions[Global.level_data.level_id] then
			return new_phalanx_positions[Global.level_data.level_id][math.random(1,#new_phalanx_positions[Global.level_data.level_id])], false
		else
			return nil, nil
		end
	end

	-- check for whatever preventions maps with custom winters spawns may have. currently only limits by wave number
	function DS_BW:_new_captain_winters_spawn_should_be_prevented()
		-- min wave number at which he can spawn
		local min_assault_number = {
			run = 2,
			mia_2 = 2,
			des = 2,
		}
		
		if Global and Global.level_data and min_assault_number[Global.level_data.level_id] then
			return min_assault_number[Global.level_data.level_id] > DS_BW.Assault_info.number
		else
			return false
		end
	end
	
	dofile(ModPath .. "lua/coputils_cuffing.lua")
	dofile(ModPath .. "lua/coputils_hotspots.lua")
	dofile(ModPath .. "lua/AD_updater.lua")
	dofile(ModPath .. "lua/Anti_spawncamp.lua")

	-- Change the surrender presets to harder ones
	function DS_BW:update_surrender_tweak_data()
		-- avoid crashes if tweak_data global wasnt created by the game yet by waiting until it loads. if it never does, we have bigger problems then creating a semi infinite loop
		if not tweak_data then
			DelayedCalls:Add("updateDomsAfterTweakdataHasLoaded", 0.5, function()
				DS_BW:update_surrender_tweak_data()
			end)
		else
			if not Network:is_server() then
				return
			end
			-- Easy (aka instant) surrender preset, used for guards and cops
			local surrender_preset_easy = {
				base_chance = 1,
				significant_chance = 0,
				reasons = {
					health = {
						[1] = 0,
						[0.99] = 0
					},
					weapon_down = 0,
					pants_down = 0,
					isolated = 0
				},
				factors = {
					flanked = 0,
					unaware_of_aggressor = 0,
					enemy_weap_cold = 0,
					aggressor_dis = {
						[1000] = 0,
						[300] = 0
					}
				}
			}
			-- Normal preset, used for light swats
			local surrender_preset_normal = {
				base_chance = 0.15,
				significant_chance = 0,
				reasons = {
					health = {
						[0.33] = 0.15,
						[0] = 0.15
					},
					weapon_down = 0,
					pants_down = 0
				},
				factors = {
					isolated = 0,
					flanked = 0,
					unaware_of_aggressor = 0,
					enemy_weap_cold = 0,
					aggressor_dis = {
						[500] = 0,
						[150] = 0
					}
				}
			}
			-- Hardest preset, used for heavy swats
			local surrender_preset_hard = {
				base_chance = 0.1,
				significant_chance = 0,
				reasons = {
					health = {
						[0.33] = 0.1,
						[0] = 0.1,
					},
					weapon_down = 0,
					pants_down = 0
				},
				factors = {
					isolated = 0,
					flanked = 0,
					unaware_of_aggressor = 0,
					enemy_weap_cold = 0,
					aggressor_dis = {
						[500] = 0,
						[150] = 0
					}
				}
			}
			-- Give the guards and light cops an "easy" preset
			tweak_data.character.security.surrender = surrender_preset_easy
			tweak_data.character.cop.surrender = surrender_preset_easy
			tweak_data.character.fbi.surrender = surrender_preset_easy
			
			-- Give most assault units the "normal" preset
			tweak_data.character.fbi_swat.surrender = surrender_preset_normal
			tweak_data.character.swat.surrender = surrender_preset_normal
			tweak_data.character.city_swat.surrender = surrender_preset_normal
			tweak_data.character.zeal_swat.surrender = surrender_preset_normal
			
			-- Give heavy assault units the "hard" preset
			tweak_data.character.heavy_swat.surrender = surrender_preset_hard
			tweak_data.character.fbi_heavy_swat.surrender = surrender_preset_hard
			tweak_data.character.zeal_heavy_swat.surrender = surrender_preset_hard
			
			tweak_data.weapon.swat_van_turret_module.AUTO_REPAIR = false
			tweak_data.weapon.aa_turret_module.AUTO_REPAIR = false
			tweak_data.weapon.crate_turret_module.AUTO_REPAIR = false
			
			-- units on boiling point that can deal DS levels of damage are considered to be cops.
			if Global.level_data and Global.level_data.level_id == "mad" then
				tweak_data.character.cop.surrender = surrender_preset_hard
				tweak_data.character.heavy_swat.surrender = surrender_preset_normal
				tweak_data.character.fbi_heavy_swat.surrender = surrender_preset_normal
				tweak_data.character.zeal_heavy_swat.surrender = surrender_preset_normal
			end
			
		end
	end
	
	function DS_BW:linkchangelog()
		managers.network.account:overlay_activate("url", "https://github.com/irbizzelus/PD2_DS_BW/releases")
	end
	
	-- only pops up once in the main menu
	function DS_BW:changelog_popup()
		if not DS_BW.settings.changelog_msg_shown or DS_BW.settings.changelog_msg_shown < DS_BW.version_num then
			DelayedCalls:Add("DS_BW_showchangelogmsg_delayed", 1, function()
				local menu_options = {}
				menu_options[#menu_options+1] ={text = "Check full changelog", data = nil, callback = DS_BW.linkchangelog}
				menu_options[#menu_options+1] = {text = "Cancel", is_cancel_button = true}
				local message = tostring(DS_BW.version).." Changelog:\n\nThis patch updates: ADL, ECMs, Handcuffing, Hotspots, Assault pacing, Enemy spawns, and more. Important bits:\n\n- Fixed issues with enemy spawn logic preventing intended spawning quantities\n- Flashbangs can now be replaced with teargas\n- Handcuffing no longer works if only 1 player is left alive\n\nHandcuffing is now applied to Team AI during revives\n\nTo keep yourself up to date, check the changelog."
				local menu = QuickMenu:new("Death Sentence, but Worse.", message, menu_options)
				menu:Show()
				DS_BW.settings.changelog_msg_shown = DS_BW.version_num
				DS_BW:Save()
			end)
		end
	end
	
	function DS_BW:welcomemsg1(peer_id) -- welcome message for clients
		if Network:is_server() and DS_BW.DS_difficultycheck == true then
			LuaNetworking:SendToPeer(peer_id, "DS_BW_sync", "Hello_"..tostring(DS_BW.version))
			if DS_BW._low_spawns_manager.level >= 1 and DS_BW.settings.ADL_announcements then
				local lvl_str = tostring(DS_BW._low_spawns_manager.level) or "0"
				LuaNetworking:SendToPeer(peer_id, "DS_BW_sync", "ADU_"..tostring(lvl_str))
			end
			DelayedCalls:Add("DS_BW:welcomemsg1topeer_" .. tostring(peer_id), 1.2, function()
				local peer = managers.network:session():peer(peer_id)
				
				if peer == managers.network:session():local_peer() then
					DS_BW.players[peer_id].welcome_msg1_shown = true
					return
				end
				
				if not DS_BW.players[peer_id].welcome_msg1_shown then
					if not peer then
						return
					end
					local message = "Welcome "..peer:name().."! This lobby runs \"Death Sentence, but Worse\" mod (version "..DS_BW.version..") which changes loud DS gameplay in a few ways."
					if managers.network:session() and managers.network:session():peers() then
						DS_BW.players[peer_id].welcome_msg1_shown = true
						if not DS_BW.peers_with_mod[peer_id] then
							peer:send("request_player_name_reply", managers.network.account:username())
							peer:send("send_chat_message", ChatManager.GAME, message)
						end
					end
				end
			end)
		end
	end

	function DS_BW:welcomemsg2(peer_id)
		if Network:is_server() and DS_BW.DS_difficultycheck == true then
			DelayedCalls:Add("DS_BW:welcomemsg2topeer_" .. tostring(peer_id), 1.6, function()
				local peer = managers.network:session():peer(peer_id)
				
				if peer == managers.network:session():local_peer() then
					DS_BW.players[peer_id].welcome_msg2_shown = true
					return
				end
				
				if not DS_BW.players[peer_id].welcome_msg2_shown then
					if not peer then
						return
					end
					if managers.network:session() and managers.network:session():peers() then
						DS_BW.players[peer_id].welcome_msg2_shown = true
						if not DS_BW.peers_with_mod[peer_id] then
							peer:send("send_chat_message", ChatManager.GAME, "Enemy updates:\n- ECM stun reduced: /ecm\n- Added spawn protection: /spawncamp\n- Intimidations are harder: /dom\n- Gained ability to handcuff players during interactions: /cuffs\n- Updated variety (/cops), behavior (/ai) and damage outputs (/weapons).")
							peer:send("send_chat_message", ChatManager.GAME, "Other updates:\n- Enemy pressure is adapting to team performance: /adl\n- Flashbangs can create explosions, gas and fire fields: /flash\n- Assault pacing was altered: /assault\n- Swat turrets no longer self-repair :)")
							peer:send("send_chat_message", ChatManager.GAME, "Use chat commands to get a DM with additional information. Bring your favoutite build and GLHF!")
							if DS_BW and not MenuCallbackHandler:is_modded_client() then
								peer:send("send_chat_message", ChatManager.GAME, "Lastly, host ("..managers.network.account:username()..") seems to have a hidden mod list, you can request their modlist using /hostmods.")
							end
							peer:send("request_player_name_reply", managers.network.account:username())
						end
					end
				end
			end)
		end
	end
	
	function DS_BW:infomessage(message)
		if Global.game_settings.single_player == false then
			managers.chat:_receive_message(1, "[DS_BW]", message, DS_BW.color)
		end
	end

	function DS_BW:return_skills(peer_id)

		if not peer_id then
			return
		end

		local peer = managers.network:session() and managers.network:session():peer(peer_id)
		if not peer then
			return
		end
		
		if peer == managers.network:session():local_peer() then
			DS_BW.players[peer_id].skills_shown = true
			return
		end
		
		-- DW+ compatibility to avoid duped messages. since this function is unchanged, allow for dw+ to sent it
		if DWP then
			return
		end
		
		if peer and peer:skills() then
			
			local skills_func_string = peer:skills()
			
			if type(skills_func_string) ~= "string" or skills_func_string == "" then
				return
			end
			
			local skills = string.split(string.split(skills_func_string, "-")[1], "_")
			local skill_count = 0
			for k,v in pairs(skills) do
				skill_count = skill_count + 1
				if skill_count > 15 or not v or type(tonumber(v)) ~= "number" then
					return
				end
			end
			if skill_count < 15 then
				return
			end
			
			local perk_deck = string.split(string.split(skills_func_string, "-")[2], "_")
			local perk_deck_id = tonumber(perk_deck[1])
			local perk_deck_completion = tonumber(perk_deck[2])
			
			local skills_string = ""
			
			if DS_BW.settings.skills_showcase == 2 then
				local skillsum = 0
				for k,v in pairs(skills) do
					skillsum = skillsum + tonumber(v)
				end
				skills_string = "|"..tostring(skillsum).." skill points used|"
			elseif DS_BW.settings.skills_showcase == 3 then
				skills_string = "|Mas.: ("..skills[1]+skills[2]+skills[3].."); Enf.: ("..skills[4]+skills[5]+skills[6].."); Tec.: ("..skills[7]+skills[8]+skills[9].."); Gho.: ("..skills[10]+skills[11]+skills[12].."); Fug.: ("..skills[13]+skills[14]+skills[15]..")|"
			elseif DS_BW.settings.skills_showcase == 4 then
				skills_string = "|Mas.: ("..skills[1].." "..skills[2].." "..skills[3]..") Enf.: ("..skills[4].." "..skills[5].." "..skills[6]..") Tec.: ("..skills[7].." "..skills[8].." "..skills[9]..") Gho.: ("..skills[10].." "..skills[11].." "..skills[12]..") Fug.:("..skills[13].." "..skills[14].." "..skills[15]..")|"
			end
			
			local perk_name = managers.localization:text("menu_st_spec_" .. perk_deck_id)
			if perk_deck_id > 23 then -- update this when, if ever, a new perk is added
				perk_name = "Custom perk deck"
			end
			
			local message = peer:name()..": "..skills_string.." |"..perk_name.." "..tostring(perk_deck_completion).."/9|"
			
			if DS_BW.settings.skills_showcase ~= 1 then
				if not DS_BW.players[peer_id].skills_shown then
					DS_BW.players[peer_id].skills_shown = true
					DS_BW:infomessage(message)
				end
			end
		end
	end

	function DS_BW:returnplayerhours(peer_id)

		if not peer_id then
			return
		end
		
		local peer = managers.network:session() and managers.network:session():peer(peer_id)
		if not peer then
			return
		end
		if peer == managers.network:session():local_peer() then
			DS_BW.players[peer_id].hours_shown = true
			return
		end
		
		-- DW+ compatibility to avoid duped messages
		if DWP then
			return
		end
		
		if DS_BW.settings.hourinfo and not DS_BW.players[peer_id].hours_shown then
		
			local hours
			local steam_id = tostring(managers.network:session():peer(peer_id)._account_id)
			
			local infamy = "."
			if DS_BW.settings.infamy then
				if peer and peer._rank then
					infamy = ", with level " .. tostring(peer._rank) .. " infamy."
				else
					-- we dont confirm hour print because it can cause false '0 infamy' messages, since the rank() func always exists for peers, but it can return default 0 if peer is not synced yet
					log("[DS_BW] NO peer._rank!!!!! hours function quits for peer: "..peer_id)
					return
				end
			end
			
			if peer:account_type() == Idstring("EPIC") then
				if DS_BW.settings.hourinfo == true then
					
					hours = "an EPIC profile"
					local message = tostring(peer:name()).." has "..hours..infamy
					
					if not DS_BW.players[peer_id].hours_shown then
						DS_BW.players[peer_id].hours_shown = true
						DS_BW:infomessage(message)
						return
					end
				end
			end
			
			if peer:account_type() == Idstring("STEAM") then
				dohttpreq('http://steamcommunity.com/profiles/' .. steam_id .. '/?xml=1',
					function (page)
						local hrs_str = "??"
						if type(page) ~= 'string' then
							log('[DS_BW] Error loading player hours for ' .. tostring(steam_id) .. ': no Steam reply')
						end
						
						hours = page:match('<mostPlayedGame>.-<gameLink>.-218620.-</gameLink>.-<hoursOnRecord>([%d,.]+)</hoursOnRecord>')
						hours = type(hours) == 'string' and hours:gsub(',' , '')
						if hours then
							hrs_str = hours
						end
						
						if DS_BW.settings.hourinfo then
							local message = tostring(peer:name()).." has "..hrs_str.." hours"..infamy
							DS_BW:infomessage(message)
						end
					end
				)
			end
			DS_BW.players[peer_id].hours_shown = true
		else
			DS_BW.players[peer_id].hours_shown = true
		end
	end
	
	-- since blt is so nice and only disables mods on restart, continiuosly re-disable this piece of shit after it was found, so that ngbto users can't re-enable the mod by restarting their game
	-- hopefuly ngbto users can read, and will process the warning pop up in the main menu
	function DS_BW:yoink_ngbto()
		DelayedCalls:Add("DS_BW_fuckoffngbto", 1, function()
			BLT.Mods:GetModByName("Newbies go back to overkill"):SetEnabled(false, true)
			DS_BW:yoink_ngbto()
		end)
	end
end