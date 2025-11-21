if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

Hooks:Add('LocalizationManagerPostInit', 'DS_BW_option_loc', function(loc)
	DS_BW:Load()
	loc:load_localization_file(DS_BW._path .. 'menu/DS_BW_menu_en.json', false)
end)

-- all the settings that can be changes in the mod's settings in game
Hooks:Add('MenuManagerInitialize', 'DS_BW_init', function(menu_manager)

	-- menu backout
	MenuCallbackHandler.DS_BWsave = function(this, item)
		DS_BW:Save()
	end
	
	-- header buttons
	MenuCallbackHandler.DS_BWcb_donothing = function(this, item)
		--nothingness
	end
	
	-- gameplay
	MenuCallbackHandler.DS_BWcb_adapt_diff_announcements = function(this, item)
		DS_BW.settings.adapt_diff_announcements = tonumber(item:value())
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_starting_adapt_diff = function(this, item)
		DS_BW.settings.starting_adapt_diff = tonumber(item:value())
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_always_hard_heists = function(this, item)
		DS_BW.settings[item:name()] = item:value() == 'on'
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DWPcb_tasks_per_min_mul = function(this, item)
		DS_BW.settings.tasks_per_min_mul = tonumber(item:value())
		DS_BW:Save()
	end
	
	-- info msg
	MenuCallbackHandler.DS_BWcb_skills_showcase = function(this, item)
		DS_BW.settings.skills_showcase = tonumber(item:value())
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_hourinfo = function(this, item)
		DS_BW.settings[item:name()] = item:value() == 'on'
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_infamy = function(this, item)
		DS_BW.settings[item:name()] = item:value() == 'on'
		DS_BW:Save()
	end
	
	-- end score
	MenuCallbackHandler.DS_BWcb_endstattoggle = function(this, item)
		DS_BW.settings.endstats_enabled = item:value() == 'on'
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_statsmsgpublic = function(this, item)
		DS_BW.settings.endstats_public = item:value() == 'on'
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_endstatSPkills = function(this, item)
		DS_BW.settings.endstats_specials = item:value() == 'on'
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_endstatheadshots = function(this, item)
		DS_BW.settings.endstats_headshots = item:value() == 'on'
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_endstataccuarcy = function(this, item)
		DS_BW.settings.endstats_accuracy = item:value() == 'on'
		DS_BW:Save()
	end
	
	-- misc
	MenuCallbackHandler.DS_BWcb_lobbyname = function(this, item)
		DS_BW.settings[item:name()] = item:value() == 'on'
		DS_BW:Save()
	end
	
	MenuCallbackHandler.DS_BWcb_patch_notes = function(this, item)
		managers.network.account:overlay_activate("url", "https://github.com/irbizzelus/PD2_DS_BW/releases")
	end

	DS_BW:Load()

	MenuHelper:LoadFromJsonFile(DS_BW._path .. 'menu/DS_BW_menu.json', DS_BW, DS_BW.settings)
end)

-- any time host changes lobby attributes, update lobby name
Hooks:PostHook(MenuCallbackHandler, "update_matchmake_attributes", "DS_BW_swapname_on_attributes_update", function()
	if DS_BW.settings.lobbyname then
		if DWP then
			if DS_BW.DS_difficultycheck then
				DS_BW.change_lobby_name(DS_BW.DS_difficultycheck)
			end
		else
			DS_BW.change_lobby_name(DS_BW.DS_difficultycheck)
		end
	end
end)

-- whenever a contract is bought, check for it's difficulty to apply welcome messages and lobby rename
Hooks:PostHook(MenuCallbackHandler, "start_job", "DS_BW_oncontractbought", function(self, job_data)
	if job_data.difficulty == "sm_wish" then
		DS_BW.DS_difficultycheck = true
		if DS_BW.settings.lobbyname then
			DS_BW.change_lobby_name(true)
		end
	else
		DS_BW.DS_difficultycheck = false
		if DS_BW.settings.lobbyname then
			if DWP and DWP.settings.lobbyname then
				-- let dw+ handle it
			else
				DS_BW.change_lobby_name(false)
			end
		end
	end
end)

Hooks:PostHook(MenuManager, "_node_selected", "DS_BW:Node", function(self, menu_name, node)
	-- clear peer's vars if we quit to main menu
	if type(node) == "table" and node._parameters.name == "main" then
		DS_BW._is_client_in_DSBW_lobby = false
		DS_BW:changelog_popup()
		for i=1,4 do
			DS_BW.players[i] = {
				skills_shown = false,
				hours_shown = false,
				welcome_msg1_shown = false,
				welcome_msg2_shown = false,
				requested_mods_1 = false,
				requested_mods_2 = false
			}
		end
		-- disable and warn about NGBTO incompatibility
		if NoobJoin or BLT.Mods:GetModByName("Newbies go back to overkill") then
			DelayedCalls:Add("DS_BW_show_NGBTO_warning", 2, function()
				local menu_options = {}
				menu_options[1] = {text = "Ok", is_cancel_button = true}
				local menu = QuickMenu:new("Death Sentence, but Worse.", "DSBW is incompatible with NGBTO (newbies go back to overkill) and will not allow for NGBTO to work. Uninstall NGBTO if you want to use DSBW without seeing this message.\n\nIf you want to limit access to your lobby use TDLQ's 'Lobby settings' mod. You can find it on their web site, NOT modworkshop.", menu_options)
				menu:Show()
				DS_BW:yoink_ngbto()
			end)
		end
	end
	if type(node) == "table" and node._parameters.menu_id == "DS_BWmenu" then
		DS_BW.menu_node = node
	end
	if type(node) == "table" and node._parameters.name == "lobby" then
		-- whenever in the lobby as host make sure to set lobby name to whatever it should be, depending on current contract difficulty and such
		if DS_BW.settings.lobbyname then
			if managers.network.matchmake._lobby_attributes then
				if Network:is_server() then
					if managers.network.matchmake._lobby_attributes.job_id == 0 and managers.network.matchmake.lobby_handler then
						if managers.network.matchmake._lobby_attributes.owner_name ~= managers.network.account:username_id() then
							DS_BW.change_lobby_name(false)
						end
					else
						if managers.network.matchmake._lobby_attributes.difficulty == 8 then
							if managers.network.matchmake._lobby_attributes.owner_name == managers.network.account:username_id() then
								DS_BW.change_lobby_name(true)
							end
						else
							if managers.network.matchmake._lobby_attributes.owner_name ~= managers.network.account:username_id() then
								if DWP and DWP.settings.lobbyname then
									-- let dw+ handle it
								else
									DS_BW.change_lobby_name(false)
								end
							end
						end
					end
				end
			end
		end
	end
end)