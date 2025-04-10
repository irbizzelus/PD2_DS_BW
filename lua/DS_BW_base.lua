-- Main global vars, default settings and utility functions
-- Death Sentence, But Worse. Title is WIP but i prob wont change it cuz im not creative enough.
if not DS_BW then
    _G.DS_BW = {}
	DS_BW._path = ModPath
    DS_BW.DS_difficultycheck = false
	DS_BW.version = "1.0.2"
	DS_BW.version_num = 1.02
	DS_BW.settings = {
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
	DS_BW.color = Color(255,240,140,35) / 255
	DS_BW.end_stats_printed = false

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
			local new_name = "DS, but Worse"
			if not is_DS then
				new_name = managers.network.account:username()
			end
			if cur_name ~= new_name then
				managers.network.matchmake._lobby_attributes.owner_name = new_name
				managers.network.matchmake.lobby_handler:set_lobby_data(managers.network.matchmake._lobby_attributes)
			end
		end
	end
	
	dofile(ModPath .. "lua/coputils_cuffing.lua")
	dofile(ModPath .. "lua/coputils_hotspots.lua")

	-- Change the surrender presets to harder ones
	function DS_BW:update_surrender_tweak_data()
		-- avoid crashed if tweak_data global wasnt created by the game yet by waiting until it loads. if it never does, we have bigger problems then creating a semi infinite loop
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
				base_chance = 0.25,
				significant_chance = 0,
				reasons = {
					health = {
						[1] = 0,
						[0.33] = 0.25
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
				base_chance = 0.15,
				significant_chance = 0,
				reasons = {
					health = {
						[1] = 0,
						[0.33] = 0.15
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
				local message = "1.0.2 release\n\nWelcome to DSBW!\n\nWhenever a big enough update for this mod is published in the future, this pop-up window will let you know of most important changes.\nMinor updates and bug fixes most likely will not appear here, but if you would like to know what was changed, you can always do so in options->mod options->DSBW->patch notes.\n\nGood luck and have fun!"
				local menu = QuickMenu:new("Death Sentence, but Worse.", message, menu_options)
				menu:Show()
				DS_BW.settings.changelog_msg_shown = DS_BW.version_num
				DS_BW:Save()
			end)
		end
	end
	
	function DS_BW:welcomemsg1(peer_id) -- welcome message for clients
		if Network:is_server() and DS_BW.DS_difficultycheck == true then
			DelayedCalls:Add("DS_BW:welcomemsg1topeer_" .. tostring(peer_id), 0.3, function()
				local peer = managers.network:session():peer(peer_id)
				
				if peer == managers.network:session():local_peer() then
					DS_BW.players[peer_id].welcome_msg1_shown = true
					return
				end
				
				if not DS_BW.players[peer_id].welcome_msg1_shown then
					if not peer then
						return
					end
					local message = "Hello and welcome "..peer:name().."! This lobby runs 'Death Sentence, but Worse' mod (Ver. "..DS_BW.version..") that adjusts loud gameplay in a few ways:"
					if managers.network:session() and managers.network:session():peers() then
						peer:send("request_player_name_reply", "DS_BW")
						peer:send("send_chat_message", ChatManager.GAME, message)
						DS_BW.players[peer_id].welcome_msg1_shown = true
					end
				end
			end)
		end
	end

	function DS_BW:welcomemsg2(peer_id)
		if Network:is_server() and DS_BW.DS_difficultycheck == true then
			DelayedCalls:Add("DS_BW:welcomemsg2topeer_" .. tostring(peer_id), 0.9, function()
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
						if Global.level_data and Global.level_data.level_id == "mad" then
							peer:send("send_chat_message", ChatManager.GAME, "- WHY DID YOU COME TO RUSSIA? 'Boiling Point' heist damage output was 'fixed' to make some enemies deal full DS damage.")
							peer:send("send_chat_message", ChatManager.GAME, "- All enemies have 75% DAMAGE RESISTANCE - please note that lower health enemies are used more often, and amount of enemies is also lower: /dmg")
						else
							peer:send("send_chat_message", ChatManager.GAME, "- All enemies have 50% DAMAGE RESISTANCE: /dmg")
						end
						peer:send("send_chat_message", ChatManager.GAME, "- Almost all enemies will IGNORE THE ECM STUN effect: /ecm")
						peer:send("send_chat_message", ChatManager.GAME, "- You can GET HANDCUFFED during interactions by cops: /cuffs")
						peer:send("send_chat_message", ChatManager.GAME, "- Enemies are MUCH harder to intimidate: /dom")
						peer:send("send_chat_message", ChatManager.GAME, "- Flashbangs have a chance to detonate as FIRE or a GAS grenade: /flash")
						peer:send("send_chat_message", ChatManager.GAME, "- Enemy variety, weapons used and tactical behavior were altered to make your life worse: /cops")
						peer:send("send_chat_message", ChatManager.GAME, "- Assault pacing was altered: /assault")
						peer:send("send_chat_message", ChatManager.GAME, "- Swat turrets will no longer self repair :)")
						peer:send("send_chat_message", ChatManager.GAME, "You can request additional information for all gameplay changes using associated chat commands - it will be sent to you in a private message. Bring your best build and a lot of ammo. Good luck.")
						if DS_BW and not MenuCallbackHandler:is_modded_client() then
							peer:send("send_chat_message", ChatManager.GAME, "Lastly, "..managers.network.account:username().." seems to have a hidden mod list, you can request their modlist using /hostmods.")
						end
						peer:send("request_player_name_reply", managers.network.account:username())
						DS_BW.players[peer_id].welcome_msg2_shown = true
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
end