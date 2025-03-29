if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

Hooks:PreHook(MenuManager,"show_person_joining","DS_BW_joinScreenMessageSend",function(self, id, nick)
	-- sent a welcome msg during the "x is joining the game" screen, this should be the earliest opportunity for a message if host is in a heist
	-- foolproof, since this func wont print itself more then once
	if managers.network and managers.network._session and Network:is_server() and Utils:IsInGameState() then
		local peer = managers.network:session():peer(id)
		if peer == managers.network:session():local_peer() then
			log("[DS_BW] How the fuck are we looking at our own join panel?")
		end
		
		DS_BW:welcomemsg1(id)
		DS_BW:welcomemsg2(id)
	end
end)
