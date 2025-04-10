if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

if not DS_BW.CM then
	DS_BW.CM = {
		prefixes = {
			["/"] = true,
			["!"] = true
		},
		commands = {}
	}
	
	-- noone actually knows that ! is a valid prefix, because this would make welcome message longer but its allready ridiculously long
	function DS_BW.CM:validPrefix(prefix)
		return self.prefixes[prefix]
	end
	
	function DS_BW.CM:add_command(command_name, cmd_data)
		self.commands[command_name] = cmd_data
	end
	
	-- unlike that utiliy (from BLT?) function, returns actuall status of being in game, where breifing screen still counts as 'not in game'
	function DS_BW.CM:is_playing()
		if BaseNetworkHandler then
			return BaseNetworkHandler._gamestate_filter.any_ingame_playing[game_state_machine:last_queued_state_name()]
		else
			return false
		end
	end

	function DS_BW.CM:local_peer()
		return managers.network:session():local_peer()
	end
	
	function DS_BW.CM:public_chat_message(text)
		if not text or (text == "") then
			return
		end
		managers.chat:send_message(ChatManager.GAME, nil, text)
	end
	
	-- preferably this message should have a [DS_BW Private Message] prefix, but this would require sending name send requests
	-- this already sometimes causes sync issues with the welcome message at high ping, so fuck that.
	function DS_BW.CM:private_chat_message(peer_id, message)
		if not message or (message == "") then
			return
		end
		
		local peer = managers.network:session():peer(peer_id)
		if peer_id == self:local_peer():id() then
			managers.chat:_receive_message(1, "[DS_BW]", message, DS_BW.color or tweak_data.system_chat_color)
		else
			if managers.network:session():peer(peer_id) then
				managers.network:session():send_to_peer(peer, "send_chat_message", 1, message)
			end
		end
	end
	
	function DS_BW.CM:process_command(input, sender)
		sender = sender or self:local_peer()
		if not input or input == "" then
			return
		end
		local lower_cmd = string.match(input:sub(2):lower(), "(%w+)")
		local command = self.commands and self.commands[lower_cmd]
		
		if not command then
			if Network:is_server() then
				if DS_BW.DS_difficultycheck then
					self:private_chat_message(sender:id(), "Such command doesn't exist.")
					return
				else
					self:private_chat_message(sender:id(), "Chats commands are disabled for non-DS difficulty contracts.")
					return
				end
			else
				self:private_chat_message(sender:id(), "Commands are disabled if you are not the lobby host.")
				return
			end
		end
		
		if command.in_game_only and not self:is_playing() then
			self:private_chat_message(sender:id(), "In game only command!")
			return
		end

		if command.callback and type(command.callback) == "function" then
			command.callback(sender)
		end
	end

	dofile(ModPath .. "lua/commands.lua")
end