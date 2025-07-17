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
			local msg = "All enemies now only have a 18% chance to get stunned by the ECM feedback (instead of 80%-100%), and the stun duration is also shorter. All of Hacker's bonuses you get while PECM is active can still be received even if enemies are not visually stunned."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("dmg", {
		callback = function(sender)
			local msg = "All enemies receive 50% less damage than usual, which means you need twice the bullets to kill them. This effect is copied from Cpt.Winter's buff and can not be disabled in any way. To compensate, amount of enemies was reduced."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("flash", {
		callback = function(sender)
			local msg = "Flashbang detonates 3 times as quickly. If it's not destroyed, there is a 45% chance for the flashbang to create a fire field, 22.5% chance for it to explode, and a 7.5% chance for it to create a much deadlier explosion. Or it may just remain a flashbang."
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
	
	-- i know some of these, but the rest i just found funny from some quotes website
	local gibberish = {
		"You have died of dysentery.",
		"Praise the sun!",
		"Does this unit have a soul?",
		"Stop right there, criminal scum!",
		"Space. Space. I'm in space. SPAAAAAAACE!",
		"Grass grows, birds fly, sun shines, and brother, I hurt people.",
		"This is a bucket.",
		"There is nothing. Only warm, primordial blackness. Your conscience ferments in it — no larger than a single grain of malt. You don't have to do anything anymore. Ever. Never ever.",
		"The man does not know the bullet has entered his brain. He never will. Death comes faster than the realization.",
		"This is real darkness. It's not death, or war, or child molestation. Real darkness has love for a face. The first death is in the heart, Harry.",
		"The pain of your absence is sharp and haunting, and I would give anything not to know it; anything but never knowing you at all (which would be worse).",
		"Science compels us to explode the sun.",
		"Like a fly to the oinment, your conscience sticks to it. The limbed and headed machine of pain and undignified suffering is firing up again. It wants to walk the desert. Hurting. Longing. Dancing to disco music.",
		"You found a joke placeholder! There is not joke here yet. Hmmmm, maybe you can think of one?",
		"Nicolas Cage is my waifu.",
		"Cats are cute.",		
		"The Eiffel Tower can be 15 cm taller during the summer, due to thermal expansion meaning the iron heats up, the particles gain kinetic energy and take up more space.",
		"Australia is wider than the moon. The moon sits at 3400km in diameter, while Australia’s diameter from east to west is almost 4000km.",
		"It's illegal to own just one guinea pig in Switzerland. It's considered animal abuse because they're social beings and get lonely.",
		"The unicorn is the national animal of Scotland. It was apparently chosen because of its connection with dominance and chivalry as well as purity and innocence in Celtic mythology",
		"Ketchup was once sold as medicine. The condiment was prescribed and sold to people suffering with indigestion back in 1834.",
		"A jiffy is an actual unit of time. It's 1/100th of a second.",
		"Sliced bread was first manufactured by machine and sold in the 1920s by the Chillicothe Baking Company in Missouri. It was the greatest thing since...unsliced bread?",
		"Wombats are the only animal whose poop is cube-shaped. This is due to how its intestines form the feces. The animals then stack the cubes to mark their territory. 'Insert minecraft joke here'",
		"What do you call an ant who fights crime? A vigilANTe!",
		"What does a storm cloud wear under his raincoat? Thunderwear.",
		"What did the policeman say to his hungry stomach? 'Freeze. You’re under a vest.'",
		"What social event do spiders love to attend? Webbings.",
		"Why are pizza jokes the worst? They’re too cheesy.",
		"What did the elf learn in school? The elf-abet.",
		"Why are elevator jokes the funniest? Because they work on so many levels.",
		"What did the snowman ask the other snowman? 'Do you smell carrots?'",
		"You have unlocked existential dread!"
	}
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
				DS_BW.CM:public_chat_message(gibberish[math.random(1,33)])
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
				DS_BW.CM:public_chat_message(gibberish[math.random(1,33)])
			end
		end
	})
	
	DS_BW.CM:add_command("rng", {
		callback = function(sender)
			local am_angry = math.random() <= 0.2
			if am_angry then
				local peer = managers.network and managers.network:session() and managers.network:session():peer(sender:id())
				local unit = peer and peer:unit() or nil
				if (unit and alive(unit)) then
					DS_BW.CM:public_chat_message("RNG command is tired of your shit "..sender:name()..", get cuffed.")
					unit:movement():on_cuffed()
				else
					DS_BW.CM:public_chat_message("RNG command is tired of your shit "..sender:name()..", get a job.")
				end
			else
				DS_BW.CM:public_chat_message(gibberish[math.random(1,33)])
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