-- this should never happen here
if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

local function DS_BW_statsmessage(message)
	if Network:is_server() then
		-- msg ourselves first, with a nice looking prefix
		managers.chat:_receive_message(1, "[DS_BW]", message, DS_BW.color)
		if DS_BW.settings.endstats_public then
			for i=2,4 do
				local peer = managers.network:session():peer(i)
				if peer then
					peer:send("send_chat_message", ChatManager.GAME, message)
				end
			end
		end
	end
end

Hooks:PostHook(BaseNetworkSession, "on_statistics_recieved", "DS_BW_endgamestats", function(self, peer_id, peer_kills, peer_specials_kills, peer_head_shots, accuracy, downs)
	-- if enabled, print stats in post game chat with customizable settings
	-- this part is the first message that creates a "header" explaining each column below
	if not DS_BW.end_stats_header_printed then
		DS_BW.end_stats_header_printed = true
		DelayedCalls:Add("DS_BW_endStatsAnnounce", 0.5, function()
			if DS_BW.settings.endstats_enabled and not DWP then
				local specials = ""
				local headshoots = ""
				local acc = ""
				if DS_BW.settings.endstats_specials then specials = "(Specials)" end
				if DS_BW.settings.endstats_headshots then headshoots = " Headshots |" end
				if DS_BW.settings.endstats_accuracy then acc = " Accuracy |" end
				local message = "KDR: | Kills"..specials.." // Downs |"..headshoots..acc
				DS_BW_statsmessage(message)
			end
		end)
	end
	
	-- same as above, but print actual numerical values that we have for each existing player
	DelayedCalls:Add("DS_BW_endStatsForPeer_"..tostring(peer_id) , 1.25, function()
		if DS_BW.settings.endstats_enabled and not DWP then
			local peer = managers.network:session():peer(peer_id)
			if peer and peer:has_statistics() then
				local specials = ""
				local headshoots = ""
				local acc = ""
				if DS_BW.settings.endstats_specials then specials = "(" .. peer_specials_kills .. ")" end
				if DS_BW.settings.endstats_headshots then headshoots = " " .. peer_head_shots .. " |" end
				if DS_BW.settings.endstats_accuracy then acc = " " .. accuracy .. "%" .. " |" end
				local message = "| "..peer_kills..specials.." // "..downs.." |"..headshoots..acc.." <- "..peer:name()
				DS_BW_statsmessage(message)
			end
		end
	end)
end)