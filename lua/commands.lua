if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

-- clear existing ones every time we update our commands
DS_BW.CM.commands = {}

if Network:is_server() and DS_BW.DS_difficultycheck == true then
	
	DS_BW.CM:add_command("cops", {
		callback = function(sender)
			local msg = "Special enemies spawn more often. All enemies use harder hitting weapons. Bulldozers sometimes may use a stunning shotgun. Enemies will notice and try to defend objective areas and/or your deployables, after you interact with them."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("ecm", {
		callback = function(sender)
			local msg = "All specials and light/heavy swat units are immune to the ECM feedback. Normal cops and gangsters can still be stunned. You can still receive 20% dodge upon a kill with Hacker's pocket ECM, even if enemies are not visually stunned from ECM feedback."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("dmg", {
		callback = function(sender)
			local msg = "All enemies receive 50% less damage then usual, which means you need twice the bullets to kill them. This effect is copied from Cpt.Winter's buff and can not be disabled in any way. To compensate, amount of enemies was reduced."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("flash", {
		callback = function(sender)
			local msg = "All flashbangs will now explode twice as quickly. If flashbang was not successfully destroyed, there is a 75% chance for it to be replaced by a small, but really high damaging, fire field. This field lasts for about 5 seconds."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})

	DS_BW.CM:add_command("cuffs", {
		callback = function(sender)	
			local msg = "After you begin an inteaction, any enemy that gets close enough to you can handcuff you. All cops are able do this. You have 2 ways to get out if you are cuffed: get uncuffed by a teammate, or uncuff yourself after 60 seconds."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})

	DS_BW.CM:add_command("dom", {
		callback = function(sender)
			local msg = "All enemies are harder to intimidate. Normal cops may give up instantly, but light swats only have 25% chance to surrender. Heavy swats have 15% chance to surrender. Getting enemies to less then 33% of their health will double your intimidation chances."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("assault", {
		callback = function(sender)
			local msg = "First assault wave will be slightly easier and shorter then 2nd assault and onwards. Second and onwards assaults have tougher enemies and last much longer, but will also give longer breaks in between. Try to be quick."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	-- if you are dicking around in here, it wouldnt take you long to figure out what this does, might as well save you 3 minutes of time
	-- this prints host's mods for clients who request them, but only once per client
	-- this command is hidden if host doesnt have a hidden mod list, but still can be activated, tho there's no reason for that, since you can see mods under player list tab
	-- however, if host's mod list is hidden, at the end of the welcome message clients will be informed of the hidden mod list, and would be given instruction on how to use this command
	-- if host uses this command, they will just recieve a random quote from the list bellow, to keep slimy mod hiders guessing what's happening
	DS_BW.CM:add_command("hostmods", {
		callback = function(sender)
			if sender:id() ~= 1 then
				if not DS_BW.players[sender:id()].requested_mods_1 then
					DS_BW.CM:private_chat_message(sender:id(), "This command will print all mods that lobby host has, printing every name as a seperate message, it may get really spammy if the list is really big. To confirm your request use /hostmodsconfirm")
					DS_BW.players[sender:id()].requested_mods_1 = true
				else
					if not DS_BW.players[sender:id()].requested_mods_2 then
						DS_BW.CM:private_chat_message(sender:id(), "As mentioned before, you can request host's mod list with /hostmodsconfirm")
					else
						DS_BW.CM:private_chat_message(sender:id(), "You have allready requested host's mod list.")
					end
				end
			else
				-- i know most of these, but i gotta be honest, i took a couple that i found funny from some quotes website (most of the top of this list)
				local random_message = {
					"You have died of dysentery.",
					"Praise the sun!",
					"Are you a boy or a girl?",
					"Does this unit have a soul?",
					"Stop right there, criminal scum!",
					"Do a barrel roll!",
					"Space. Space. I'm in space. SPAAAAAAACE!",
					"Grass grows, birds fly, sun shines, and brother, I hurt people.",
					"It's a-me, Mario!",
					"It's time to chew ass and kick bubblegum... and I'm all outta bubblegum.",
					"This is a bucket.",
					"There is nothing. Only warm, primordial blackness. Your conscience ferments in it — no larger than a single grain of malt. You don't have to do anything anymore. Ever. Never ever.",
					"The man does not know the bullet has entered his brain. He never will. Death comes faster than the realization.",
					"This is real darkness. It's not death, or war, or child molestation. Real darkness has love for a face. The first death is in the heart, Harry.",
					"The pain of your absence is sharp and haunting, and I would give anything not to know it; anything but never knowing you at all (which would be worse).",
					"Science compels us to explode the sun.",
				}
				DS_BW.CM:private_chat_message(sender:id(), random_message[math.random(1,16)])
			end
		end
	})
	
	DS_BW.CM:add_command("hostmodsconfirm", {
		callback = function(sender)
			if sender:id() ~= 1 then
				if not DS_BW.players[sender:id()].requested_mods_2 then
					for i, mod in pairs(BLT.FindMods(BLT)) do
						DS_BW.CM:private_chat_message(sender:id(), tostring(mod))
					end
					DS_BW.players[sender:id()].requested_mods_2 = true
				else
					DS_BW.CM:private_chat_message(sender:id(), "You have allready requested host's mod list.")
				end
			else
				local random_message = {
					"You have died of dysentery.",
					"Praise the sun!",
					"Are you a boy or a girl?",
					"Does this unit have a soul?",
					"Stop right there, criminal scum!",
					"Do a barrel roll!",
					"Space. Space. I'm in space. SPAAAAAAACE!",
					"Grass grows, birds fly, sun shines, and brother, I hurt people.",
					"It's a-me, Mario!",
					"It's time to chew ass and kick bubblegum... and I'm all outta bubblegum.",
					"This is a bucket.",
					"There is nothing. Only warm, primordial blackness. Your conscience ferments in it — no larger than a single grain of malt. You don't have to do anything anymore. Ever. Never ever.",
					"The man does not know the bullet has entered his brain. He never will. Death comes faster than the realization.",
					"This is real darkness. It's not death, or war, or child molestation. Real darkness has love for a face. The first death is in the heart, Harry.",
					"The pain of your absence is sharp and haunting, and I would give anything not to know it; anything but never knowing you at all (which would be worse).",
					"Science compels us to explode the sun.",
				}
				DS_BW.CM:private_chat_message(sender:id(), random_message[math.random(1,16)])
			end
		end
	})
	
	-- as for the constant checks bellow: they are requred in lobby/menu since user can move between contract difficultied while there, which affects what
	-- certain commands will do/print. if we are in game however, contract difficulty is set in stone, so we don't have to update our command list
	
	-- if we are a host, but not in game yet, check every 0.5 seconds that we still are a host - in case we leave our lobby
	if not Utils:IsInGameState() then
		DelayedCalls:Add("DS_BW_updatecommandfilewhenhost", 0.5, function()
			dofile(DS_BW._path .. "lua/commands.lua")
		end)
	end

elseif not Utils:IsInGameState() then
	-- if we are a not a host, and not in game, recheck if we got into our own created lobby every 0.5 seconds
	DelayedCalls:Add("DS_BW_updatecommandfile", 0.5, function()
		dofile(DS_BW._path .. "lua/commands.lua")
	end)
end