if not DS_BW then
	dofile(ModPath .. "lua/DS_BW_base.lua")
end

-- clear existing ones every time we update our commands
DS_BW.CM.commands = {}

if Network:is_server() and DS_BW.DS_difficultycheck == true then
	
	DS_BW.CM:add_command("help", {
		callback = function(sender)
			local host_msg = "You are running DSBW. You can use /commands for list of available commands. Oh, and dont be a dick to players who play with you :)"
			local client_msg = "This lobby runs \"Death Sentence, but Worse\" mod which makes loud gameplay harder. If you want to get more information on changes made by this mod, you can request /commands, which will send you a private message with relevant information. GLHF!"
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), client_msg)
			else
				DS_BW.CM:private_chat_message(sender:id(), host_msg)
			end
		end
	})
	
	DS_BW.CM:add_command("commands", {
		callback = function(sender)
			local host_msg = "List of usable information related commands: /ecm; /spawncamp; /dom; /cuffs; /cops; /ai; /weapons; /adl; /flash; /assault. When used by host, these commands will be sent as a public message for everyone.\nAdditionaly you can use: /ammo; /meds; /rng."
			local client_msg = "List of usable information related commands: /ecm; /spawncamp; /dom; /cuffs; /cops; /ai; /weapons; /adl; /flash; /assault. Additionaly you can use: /hostmods; /ammo; /meds; /rng."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), client_msg)
			else
				DS_BW.CM:private_chat_message(sender:id(), host_msg)
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
	
	DS_BW.CM:add_command("spawncamp", {
		callback = function(sender)
			local msg1 = "If enemy is killed quickly after spawning, all of their squadmates gain damage invlunerability while climbing over obstacles or being stuck in similar animations, but only as long as they are not able to shoot."
			local msg2 = "Enemies with invlunerability gain yellow blinking outlines, similar to marshal shields. Additionaly spawn point that was used by said squad will be disabled for a few seconds."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg1)
				DS_BW.CM:private_chat_message(sender:id(), msg2)
			else
				DS_BW.CM:public_chat_message(msg1)
				DS_BW.CM:public_chat_message(msg2)
			end
		end
	})
	
	DS_BW.CM:add_command("dom", {
		callback = function(sender)
			local msg = "All enemies are harder to intimidate. Normal cops will give up instantly, but light swats only have 25% chance to surrender. Heavy swats have 15% chance to surrender. Getting enemies to less then 33% of their health will double your intimidation chances."
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
	
	DS_BW.CM:add_command("cops", {
		callback = function(sender)
			local msg = "Most special units will spawn less often, relative to standard light and heavy swats, but overall spawns are GREATLY increased, leading to more intense enemy swarms. Earlier waves use lower difficulty units for reconnaissance."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("ai", {
		callback = function(sender)
			local msg = "Enemy reaction and move speeds are slighlty increased by default, and can be increased further on higher adaptive difficulty levels (/adl). Enemies will notice and try to defend objective areas and/or your deployables, after you interact with them."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("weapons", {
		callback = function(sender)
			local msg_1 = "All enemies now have a vareity of weapons they can use. To balance out increased enemy spawn rates, enemies will initialy use lower damaging weapons, however enemies may start using weapons with higher damage outputs, scaling with your team performance (/adl)."
			local msg_2 = "General concept of \"heavy SWAT deals more damage\" is kept, so focus them first, however individual enemy damage can still scale greatly, since their weapons are picked randomly whenever they spawn in. Usable weapon categories:"
			local msg_3 = "\n-SMGs: no damage drop off, low damage (67.5)\n-Rifles: no damage drop off, scale'able damage (150-225-375)\n-LMGs: have drop off, low damage (80)\n-Shotguns: have drop off, scale'able damage (225-325-525)\n-Pistols: have drop off, scale'able damage (80-150)"
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg_1)
				DS_BW.CM:private_chat_message(sender:id(), msg_2)
				DS_BW.CM:private_chat_message(sender:id(), msg_3)
			else
				DS_BW.CM:public_chat_message(msg_1)
				DS_BW.CM:public_chat_message(msg_2)
				DS_BW.CM:public_chat_message(msg_3)
			end
		end
	})
	-- re-route to an existing command
	DS_BW.CM:add_command("weapon", {callback = function(sender)
		DS_BW.CM.commands["weapons"].callback(sender)
	end})
	
	DS_BW.CM:add_command("adl", {
		callback = function(sender)
			local msg = "DSBW tries to adapt to team performance throughout the heist by tweaking the Adaptive Difficulty Level. Each level increase makes gameplay harder with more frequent, higher damaging, and faster moving enemies. Levels range from 0 to 5. Current level: "..tostring(DS_BW._low_spawns_manager.level or "?").."."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("flash", {
		callback = function(sender)
			local msg = "Flashbang detonates 3 times as quickly. If it's not destroyed, there is a 30% chance for the flashbang to create a fire field, 30% chance for it to explode, and a 15% chance for it to create a much deadlier explosion. Or it may just remain a flashbang."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("assault", {
		callback = function(sender)
			local msg = "First wave is slightly easier and always shorter than others. Assaults last longer, but will also give longer breaks in between. Assault duration can be extended mid-wave if adaptive difficulty level (/adl) was increased. Try to be quick."
			if sender:id() ~= 1 then
				DS_BW.CM:private_chat_message(sender:id(), msg)
			else
				DS_BW.CM:public_chat_message(msg)
			end
		end
	})
	
	DS_BW.CM:add_command("dmg", {
		callback = function(sender)
			local msg_1 = "If your performance was evaluated as \"too good\", you may start dealing less damage. This debuff ranges from 10% to 50%, and works as enemy damage resistance, so at 33% DR you would only deal 66% damage, and would need 1.5x the bullets to kill an enemy."
			local msg_2 = "This effect may be removed during your next performance evaluation, unless the automatic message from DS_BW says that this debuff is permanent. If a global damage resistance debuff is present, it will override your personal debuff."
			DS_BW.CM:private_chat_message(sender:id(), msg_1)
			DS_BW.CM:private_chat_message(sender:id(), msg_2)
		end
	})
	
	-- if you are dicking around in here, it wouldnt take you long to figure out what this does, might as well save you 3 minutes of time
	-- this prints host's mods for clients who request them, but only once per client
	-- this command is hidden if host doesnt have a hidden mod list, but still can be activated, tho there's no reason for that, since you can see mods under player list tab
	-- however, if host's mod list is hidden, at the end of the welcome message clients will be informed of the hidden mod list, and would be given instruction on how to use this command
	-- if host uses this command, they will just recieve a random quote from the list bellow, to keep slimy mod hiders guessing what's happening
	
	-- i know some of these, but majority i just found (un)funny and procceeded to PAYDAY (steal) them from various websites
	local gibberish = {
		-- my stuff
		"You have died of dysentery.",
		"Praise the sun!",
		"Does this unit have a soul?",
		"Stop right there, criminal scum!",
		"Space. Space. I'm in space. SPAAAAAAACE!",
		"Grass grows, birds fly, sun shines, and brother, I hurt people.",
		"This is a bucket.",
		"The man does not know the bullet has entered his brain. He never will. Death comes faster than the realization.",
		"This is real darkness. It's not death, or war, or child molestation. Real darkness has love for a face. The first death is in the heart, Harry.",
		"The pain of your absence is sharp and haunting, and I would give anything not to know it; anything but never knowing you at all (which would be worse).",
		"Science compels us to explode the sun.",
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
		"What did the snowman ask the other snowman? \"Do you smell carrots?\"",
		"You have unlocked existential dread!",
		"Water might not be wet. This is because most scientists define wetness as a liquid’s ability to maintain contact with a solid surface, meaning that water itself is not wet, but can make other objects wet.",
		"Our solar system has a wall. The heliopause – the region of space in which solar wind isn’t hot enough to push back the wind of particles coming from distant stars – is often considered the \"boundary wall\" of the Solar System and interstellar space.",
		"The largest piece of fossilised dinosaur poo discovered is over 30cm long and over two litres in volume. Believed to be a Tyrannosaurus rex's turd, the fossilised dung (also named a \"coprolite\") is helping scientists better understand what the dinosaur ate.",
		"Chainsaw was developed in Scotland in the late 18th Century to help aid and speed up the process of symphysiotomy (widening the pubic cartilage) and removal of disease-laden bone during childbirth. It wasn’t until the start of the 20th Century that we started using chainsaws for woodchopping.",
		"LEGO bricks withstand compression better than concrete. An ordinary plastic LEGO brick is able to support the weight of 375,000 other bricks before it fails. This, theoretically, would let you build a tower nearing 3.5km in height.",
		"Some animals display autistic-like traits. Autistic traits in animals include a tendency toward repetitive behaviour and atypical social habits.",
		"The biggest butterfly in the world has a 31cm wingspan. It belongs to the Queen Alexandra's Birdwing butterfly, which you can find in the forests of the Oro Province, in the east of Papua New Guinea.",
		"Flamingoes aren’t born pink. They actually come into the world with grey/white feathers and only develop a pinkish hue after starting a diet of brine shrimp and blue-green algae.",
		"Giraffes hum to communicate with each other. It’s thought that the low-frequency humming could be a form of ‘contact call’ between individuals who have been separated from their herd, helping them to find each other in the dark. Some researchers think they sleep talk too.",
		"The fastest jet is NASA’s X-43 experimental plane - it can fly almost 10 times the speed of sound (11,854km/h). The design meant that they had to be dropped from a Boeing B-52 in order to fly.",
		"Chuck Norris once killed 20 men with a single grenade throw. He still keeps the grenade on his nightstand as a souvenir.",
		"Chuck Norris' bank PIN is actually known. It's the last four digits of pi.",
		"Chuck Norris died on March 20th 1986. It just took Death 40 years to build up the courage to tell him.",
		"What did the bison say to his son when he left the ranch? Bi-son.",
		"Did I ever tell you about the time I went mushroom foraging? It’s a story with a morel at the end.",
		"How did I know my girlfriend thought I was invading her privacy? She wrote about it in her diary.",
		"I got a new pen that can write under water. It can write other words too.",
		"Why can't dinosaurs clap their hands? Because they're extinct.",
		"What do mermaids use to wash their fins? Tide.",
		"What did the skillet eat on its birthday? Pan-cakes.",
		"What do you call a dog who meditates? Aware wolf.",
		"I was going to try an all almond diet, but that's just nuts.",
		"My dog just ate a $100 bill. I guess he has expensive taste.",
		"Why did the social media manager break up with her boyfriend? Lack of engagement.",
		"My wife always complains that I have no sense of direction. So I packed up my stuff and right.",
		"I threw a boomerang months ago. Now I live in constant fear.",
		"\"I'm sorry\" and \"I apologize\" usually mean the same thing...but not at a funeral.",
		"Why did the old man fall down the well? He couldn’t see that well.",
		"\n- What is the difference between a piano, a tuna, and a pot of glue?\n- I don't know.\n- You can tuna piano but you can't piano a tuna.\n- What about the pot of glue?\n- I knew you'd get stuck on that.",
		"Today at the bank, an old lady asked me to check her balance. So I pushed her over.",
		"Dad, when he puts the car in reverse: \"Ah, this takes me back.\"",
		"Did you hear about the guy who collapsed trying to climb Mount Everest? Authorities just found Himalayan there.",
		"Where do mansplainers get their water? From a well, actually.",
		"I burned my Hawaiian pizza today. Should have cooked it at aloha temperature.",
		"I met a girl at a club the other night and she told me she'd show me a good time. When we got outside, she ran a 40 yard dash in 4.8 seconds",
		"There was a Mexican magician. He said he’ll disappear on the count of three. He said uno, dos, *poof*... He disappeared without a tres.",
		"If having sex for money makes you a whore, then does having sex for free make you a non-profit whoreganisation?",
		"Have you ever heard about the kidnapping at school? It's okay, he woke up.",
		"I stayed up all night wondering where the sun went, and then it dawned on me.",
		"Why couldn’t the tree get on his computer? Because he could not log on.",
		"Did you hear about the famous pickle? He's a really big dill.",
		"What do you call a fake noodle? An impasta.",
		"This wasn't how it was supposeed to go. We were suppose to secure the package... and be in and out clean. Instead, the whole thing's been one disaster after another. I should never have trusted you Richtofen... Never.",
		"\n- If sneezing a lot means you're sneezy, and sleeping a lot means you're sleepy, what's the word for someone that is coughing a lot?\n- Coughy?\n- Yes please, milk with two sugars.",
		"I'M SORRY. I DO NOT SPEAK JAPANESE.",
		"Archimedes, NO! It's filthy in there. Uck.",
		"AHHHHHHHHH! WE CANNOT TELEPORT BREAD ANYMORE!",
		"\n- You look. You look... Ahhhhh...\n- Drunk!\n- Round! Soft! No, round!\n- Blurry!",
		"Snipin's a good job mate. It's challenging work, outta doors. I gurantee you'll not go hungry, cause at the end of the day long as there's two people left on the planet, someone is going to want someone dead.",
		"What makes me a good demoman? If i were a bad demoman, i wouldnt be sittin' here discussing it with ya, now would i?!",
		"My wife gave me an envelope with \"Not to be opened until 2035\" on it. Inside was a list of reasons I cannot be trusted to follow simple instructions.",
		"What genre are national anthems? Country.",
		"A girl came into my bookstore and asked \"What are the chances you have a book on curing eating disorders with religion?\" Slim to Nun?",
		"I am Buzz Aldrin. Second man to step on the moon. Neil before me.",
		"Justice is a dish best served cold. Otherwise, it's just water.",
		"Why is sausage bad for you? It brings out the Wurst in people.",
		"What do you call a cow with no legs? Ground beef!",
		"What do you call an elephant in a telephone booth? Stuck.",
		"I'm afraid for the calendar. Its days are numbered.",
		"What did the janitor say when he jumped out of the closet? Supplies!",
		"I asked my dog what's two minus two. He said nothing.",
		"I don't trust stairs. They're always up to something.",
		"What did Baby Corn say to Mama Corn? Where's Pop Corn?",
		"What's the best thing about Switzerland? I don't know, but the flag is a big plus.",
		"What do you call someone with no body and no nose? Nobody knows.",
		"This graveyard looks overcrowded. People must be dying to get in.",
		"I have a joke about chemistry, but I don't think it will get a reaction.",
		"Shout out to my fingers. I can count on all of them.",
		"What country's capital is growing the fastest? Ireland. Every day it's Dublin.",
		"I used to hate facial hair...but then it grew on me.",
		-- benevolent
		"Ask your parents where babies come from.",
		"Piss tastes slighly sour and a litte lemony (trust me I know)",
		"I came from the surface from my mommy and daddy!",
		"FEED MY MY COINNNSS MR.BAINMAAAAAANNNNN",
		"We pay Celia minimum wage.",
		"I believe we have wiped out the entirety of the United States Millitary.",
		"Please dispel the rumor that Irate Gamer ripped off Angry Video Game Nerd!",
		"LOOK OUT THERE ARE HOTTED TITS UP AHEAD!",
		"Tails from \"Sonic\" is NOT gay!",
		"Suckle on the teet of Mother Bain :)",
		"Collect my jokers.",
		"Be a smart flower and not a fart smower.",
		"That's why you listen to mommy when she tells you to eat your medgetables.",
		-- minimum wage employee
		"No. This is somewhere to be. This is all you have, but it's still something. Streets and sodium lights. The sky, the world. You're still alive.",
		"Look deep inside yourself. You know it's true, because it *hurts*.",
		"In dark times, should the stars also go out?",
		"The cold finds its way under your skin. You shiver, and the city shivers with you.",
		"Never forget: The whole world's a wooden house and you're a god damn flamethrower.",
		"Keep the war-crime jokes coming and you'll end up on his good side.",
		"The road to healing is going to be a long one. Stay the course. You will make it, some day.",
		"Weave this into the story of you. Walk out of its *ruins*. Save those who still can be saved -- *I'm* on your side.",
		"So ask yourself, when the time comes, can you shoot the past in the head, walk away, and never look back on its rotting remains?",
		"A day will come when you need to take a shotgun to that cellar, shoot whatever is down there in the head, and walk away, never looking back.",
		"Capital has the ability to subsume all critiques into itself. Even those who would *critique* capital end up *reinforcing* it instead...",
		"Some of us are loners, and that's that. We will probably remain loners as long as our back holds up.",
		"One day, the sadness will end. but i don't think today's the day.",
		"And God, please let the deer on the highway get some kind of heaven. Something will tall soft grass and Sweet Reunion. If i am killed for simply living, let death be kinder than man.",
		"i no longer know if i wish to drown myself in love, vodka or the sea",
		"Im like if sissyphus had anorexia and the stone got heavier every day",
		"Osmium is the densest Stable element",
		"\nYou have found Cobalt 60\nDrop and Run!",
		"Radiation hormesis is the hypothesis that low doses of ionizing radiation (within the region of and just above natural background levels) are beneficial, stimulating the activation of repair mechanisms that protect against disease.",
		"in 2024 they found an egg that is not egg shaped",
		"The speed of light in vacuum, often called simply the speed of light and commonly denoted c, is a universal physical constant exactly equal to 299792458 m/s.",
		"Xylazine, a vetenarian anesthatic and paralytic, is one of just 20 words in the english language to contain X, Y and Z",
		"The Erfurt latrine disaster of 1184 caused the death of at least 60 people, making it the deadliest bathroom accident in history.",
		"The 45-year-old Boeing engineer from Seattle, nicknamed Mr. Hands, died from acute peritonitis after his colon was perforated while being anally penetrated by a horse",
		"The 81-year-old built a device consisting of a jigsaw power tool attached to a .22 semi-automatic handgun containing four bullets. He activated it, which fired multiple shots at his head, killing him.",
		"The 57-year-old from Pigeon, Michigan, died of blunt force craniocerebral trauma when a 75-pound (34 kg) spotted eagle ray leaped out of the water and knocked her over off the coast of Marathon Key, Florida. The ray also died.",
		"Erica Marshell, a 28-year-old British veterinarian in Ocala, Florida, died when the horse she was treating in a hyperbaric oxygen chamber kicked the wall, releasing a spark from its horseshoe, causing a fire and explosion. ",
		"James Campbell, a 68-year-old man from Cantonment, Florida, had left his 1995 Chevrolet Van to open a gate from his driveway when his dog stepped on the van's gas pedal and ran him over",
		"João Maria de Souza, 45 years old, was sleeping in bed with his wife when he was crushed in his bed by a cow falling through the roof of his home in Caratinga, Minas Gerais, Brazil. The cow had climbed on top of the house.",
		"Vera Williams, a 75-year-old from Rhyl, Wales, died a couple of weeks after swallowing a sharp piece of toast that tore her esophagus. Her ultimate cause of death was ruled to be from gastrointestinal bleeding.",
		"Julio Macías González, a 17-year-old from Mexico City died from a cerebrovascular accident caused by embolus formed on a neck hickey",
		"Shivdayal Sharma a 82-year-old electrician  was urinating on the Vande Bharat line railroad tracks in Alwar when a Vande Bharat train struck a cow, launching the animal nearly 30m into the air before it landed on Sharma, killing him",
		"The first intentional ingestion of LSD occurred on April 19, 1943",
		"The Wikipedia page \"Toilet-related injuries and deaths\" has not been fully updated in 25 years.",
		"In 2017 Jeffrey Epstein spent 25 dollars on Fortnite V-Bucks",
		"On May 4th 2017 Jeffrey Epstein emailed a 4chan thread of Five Nights At Freddies futa porn to his then girlfriend Karynia Shuliak.",
		"The First uterus transplant was attempted in 1931, altough intially succesfull, the patient died from infection months later.",
		"Beginning in the 1950s, the US Central Intelligence Agency (CIA) began a research program code-named Project MKUltra. The CIA introduced LSD to the United States, purchasing the entire world's supply for $240,000",
		"Baby jane doe, taking formula well",
		"who would throw away a perfectly good baby?",
		"it’s not a discussion, it’s a monologue",
		"FF:06:B5",
		"if i got bit by a bedbug could it possibly OD on my blood?",
		"I have a sexual fantasy where i'm married to Charlie Kirk and i keep aborting his babies and he eats me out while sobbing to feel the lat bit of connection with his baby",
		"I have a fake tooth filled with ozempic in case im ever captured and forced to serve in lowrise jeans",
		"I watch pornography in a cool, esoteric, Lynchian way. You watch it to jerk, off We are not the same",
		"Great Story. Fucking hell I'm so glad I'm only addicted to drugs",
		"I love abortions and immigrants and trans people and Palestine and flouride",
		"listening to fiona apple while drinking 8$ wine an i do NOT want to talk about it",
		"No substance I ever used was abused. It was loved.",
		"your honour my client got sissy hypnoed by the cia into shooting at the president",
		"craving the kind of intimacy that requires surgical instruments",
		"by the year of 2020 all inhabitants of the world will be insane",
		"industrial society and it's consequences are low-key sus AF, on god. nature deadass slaps, the trees be bussin. technology is mid tho FR FR no cap.",
		"I'm ovulating and need to suck on smth long and hard rn about now, like a revolver maybe",
		"gooning is praxis",
		"gooning is burgeoise",
		"if you read this you are gay",
		"You haven't had a REAL Orgasm until you've cum-yeeled-farted & got a headache all at the same time",
		"9/11 Pride flag",
		"Content moderation failed: the prompt depicts explicit sexual activity with a maternal \"Mommy\" character and a younger male referred to as her boy, indicating sexualized parent-child(incest) and underage dynamics",
		"call me the Edmund Fitzgerald the way twenty-nine good men lost their lives going down on me",
		"Bitches love my fluffy tail and soft paws",
		"Opinion: Perhaps some queer voices should be silenced",
		"Matcha pilates in dubai before a labubu rave",
		"Now i am become drunk, driver of cars",
		"nothing that a haircut and a wardrobe update and a detox and a sex change and a fake ID and getting medicated and selling all my stuff and faking my death and moving to a different country cant fix",
		"the sexual tension between me and hitting a tree at 130 km/h",
		"its actually feminist to drive a little over the speed limit",
		"ive never pissed whimsically in my life",
		"deepthroating a 44 magnum",
		"with thinkers like this you dont need idiots",
		"nothing is sacred anymore not even doign heroin and cuddling with your friends",
		"you would accomplish more for your own artistic development and sensibility as a human being on planet earth by jacking it to simpsons porn for an hour and 47 minutes",
		"There are decades where nothing happens and there are weeks where tweets happen",
		"Drinking directly from the bottle is the adult equivalent of getting it straight from the tit",
		"I am going to hang myself WATCH AND LEARN",
		"10mg got my pussy aching like garfield's back",
		"Ethical Capital Partners is a Canadian private equity firm best known for its acquisition of Aylo, the owner of Pornhub.",
		"4 8 15 16 23 42",
		"You read a thousand qoutes everyday, how about you make sure this is one of them",
		"anyways, some uf u twinks need to worry less about what i', doing and more worried about what that hairline is doing cause the biological clock isn't just for childbirth and your late twenties are coming up QUICK",
		"When The mommy's good boy asmr f4m roleplay starts talking about her \"playing with your hair\" like you aren't sitting at a cool Norwood 67 and it's all just table scraps up top so the immersion is lowkey ruined",
		"they need to make bimbo music for women in STEM",
		"With color this good there is almost no need to shoot a tranny.",
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
	
	local rng_special_case = {
		[1] = function(sender)
			DS_BW.CM.rng_contolled_by_special_case = 1
			if DS_BW.CM.temp_rng_prevention then
				DS_BW.CM:private_chat_message(sender:id(), "RNG command is temporarily disabled.")
				return
			end
			if not DS_BW.CM.temp_rng_prevention then
				DS_BW.CM.temp_rng_prevention = true
			end
			
			local messages = {
				[1] = {
					msg = "\n- There is nothing. Only warm, primordial blackness. Your conscience ferments in it - no larger than a single grain of malt. You don't have to do anything anymore.",
					delay = 1
				},
				[2] = {
					msg = "\n- Ever.",
					delay = 9
				},
				[3] = {
					msg = "\n- Never ever.",
					delay = 12
				},
				[4] = {
					msg = "\n- An inordinate amount of time passes. It is utterly void of struggle. No ex-wives are contained within it.",
					delay = 16
				},
				[5] = {
					msg = "\n- Nothing upon nothing, upong nothing!",
					delay = 23
				},
				[6] = {
					msg = "\n- I know you like nothing, baby... I know...",
					delay = 26
				},
				[7] = {
					msg = "\n- Nothingtown to Fuck-All-Borough!",
					delay = 31
				},
				[8] = {
					msg = "\n- Your days of giving a shit and being that type of animal are over.",
					delay = 35
				},
				[9] = {
					msg = "\n- The song of death is sweet and endless... But what is this? Somewhere in the sore, bloated *man-meat* around you -- a sensation!",
					delay = 41
				},
				[10] = {
					msg = "\n- Like a fly to the oinment, your conscience sticks to it. The limbed and headed machine of pain and undignified suffering is firing up again. It wants to walk the desert. Hurting. Longing.",
					delay = 50
				},
				[11] = {
					msg = "\n- Dancing to disco music.",
					delay = 62
				},
			}
			for i=1, #messages do
				DelayedCalls:Add("DS_BW_rng_chat_"..tostring(i), messages[i].delay, function()
					local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
					if hud and hud.panel:child("chat_panel") then
						DS_BW.CM:public_chat_message(messages[i].msg)
					end
				end)
			end

			DelayedCalls:Add("DS_BW_rng_chat_12", 63, function()
				DS_BW.CM.temp_rng_prevention = false
				DS_BW.CM.rng_contolled_by_special_case = nil
			end)
			
		end,
		[2] = function(sender)
			local candidates = {}
			for i=1,4 do
				local peer = managers.network:session():peer(i)
				if peer then
					candidates[peer:id()] = true
				end
			end
			local winner = math.random(1,#candidates)
			DS_BW.CM:public_chat_message("R.I.P. "..tostring(managers.network:session():peer(winner):name())..", I miss him every day.")
		end,
		[3] = function(sender)
			DS_BW.CM.rng_contolled_by_special_case = 3
			if DS_BW.CM.temp_rng_prevention then
				DS_BW.CM:private_chat_message(sender:id(), "RNG command is temporarily disabled.")
				return
			end
			if not DS_BW.CM.temp_rng_prevention then
				DS_BW.CM.temp_rng_prevention = true
			end
			
			local messages = {
				[1] = {
					msg = "FEAR ME MORTAL. I AM THE ESSENCE OF DIVINE ART.",
					delay = 1
				},
				[2] = {
					msg = "OTHERS BUT YOU CANNOT READ THIS TEXT.",
					delay = 8
				},
				[3] = {
					msg = "KNOW THAT WHEN YOU DIE, I WILL PERSONALLY CARRY YOUR SPIRIT ACROSS THE RIVER BLXWXN, INTO MY GARDEN BUILD WITHIN THE EMOTIONS OF A FLOWER.",
					delay = 13
				},
				[4] = {
					msg = "THERE WE WILL LIVE TOGETHER, WE WILL DANCE AND EAT AND SIN\nAND YOU WILL DO IMPROV COMEDY BASED ON SUGGESTIONS FROM ME FOR ALL ETERNITY.",
					delay = 20
				},
				[5] = {
					msg = "THIS IS YOUR REWARD FOR YOUR WORK HERE TODAY.",
					delay = 27
				},
				[6] = {
					msg = "GO NOW LIVE YOUR NORMAL HUMAN EXISTENCE. AND AWAIT ME IN THE LIFE THAT FOLLOWS THIS ONE.",
					delay = 31
				},
			}
			
			for i=1, #messages do
				DelayedCalls:Add("DS_BW_rng_chat_"..tostring(i), messages[i].delay, function()
					local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
					if hud and hud.panel:child("chat_panel") then
						DS_BW.CM:public_chat_message(messages[i].msg)
					end
				end)
			end
			DelayedCalls:Add("DS_BW_rng_chat_7", 36, function()
				local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
				if hud and hud.panel:child("chat_panel") then
					DS_BW.CM:public_chat_message("I LOVE YOU.")
				end
				DS_BW.CM.temp_rng_prevention = false
				DS_BW.CM.rng_contolled_by_special_case = nil
			end)
		end,
		[4] = function(sender)
			DS_BW.CM.rng_contolled_by_special_case = 4
			local phrases = {
				"Cognitive behavioral therapy (CBT) is a form of psychotherapy that combines basic principles from cognitive psychology and behaviorism. It aims to reduce symptoms of various mental health conditions by challenging convictions and assumptions.",
				"Cock and ball torture (CBT) is a sexual activity involving the application of pain or constriction to the male genitals. This may involve directly painful activities, such as genital piercing, wax play, genital spanking, squeezing, ball-busting.",
				"Cock and Ball Torture (also known as CBT) is a German goregrind band formed on 22 February 1997. The group is known for its groove-heavy riffing and pitchshifted vocals as well as its pornography-themed imagery and song titles.",
			}
			DS_BW.CM.rng_special_vars = DS_BW.CM.rng_special_vars or phrases
			local winner = DS_BW.CM.rng_special_vars[next(DS_BW.CM.rng_special_vars)]
			DS_BW.CM:public_chat_message(winner)
			DS_BW.CM.rng_special_vars[next(DS_BW.CM.rng_special_vars)] = nil
			if next(DS_BW.CM.rng_special_vars) == nil then
				DS_BW.CM.rng_special_vars = nil
				DS_BW.CM.rng_contolled_by_special_case = nil
			end
		end,
		[5] = function(sender)
			DS_BW.CM.rng_contolled_by_special_case = 5
			if DS_BW.CM.temp_rng_prevention then
				DS_BW.CM:private_chat_message(sender:id(), "RNG command is temporarily disabled.")
				return
			end
			if not DS_BW.CM.temp_rng_prevention then
				DS_BW.CM.temp_rng_prevention = true
			end
			
			local messages = {
				[1] = {
					msg = "\n- What rhymes with orange?",
					delay = 0.25
				},
				[2] = {
					msg = "\n- ...",
					delay = 1
				},
				[3] = {
					msg = "\n- ...",
					delay = 2
				},
				[3] = {
					msg = "\n- ...",
					delay = 3
				},
			}
			
			for i=1, #messages do
				DelayedCalls:Add("DS_BW_rng_chat_"..tostring(i), messages[i].delay, function()
					local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
					if hud and hud.panel:child("chat_panel") then
						DS_BW.CM:public_chat_message(messages[i].msg)
					end
				end)
			end
			DelayedCalls:Add("DS_BW_rng_chat_4", 4, function()
				local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
				if hud and hud.panel:child("chat_panel") then
					DS_BW.CM:public_chat_message("\n- No, it doesn't.")
				end
				DS_BW.CM.temp_rng_prevention = false
				DS_BW.CM.rng_contolled_by_special_case = nil
			end)
		end,
		[6] = function(sender)
			DS_BW.CM.rng_contolled_by_special_case = 6
			if DS_BW.CM.temp_rng_prevention then
				DS_BW.CM:private_chat_message(sender:id(), "RNG command is temporarily disabled.")
				return
			end
			if not DS_BW.CM.temp_rng_prevention then
				DS_BW.CM.temp_rng_prevention = true
			end
			
			local lyrics = {
				_1 = "Welcome to the internet! Have a look around,",
				_4 = "Anything that brain of yours can think of can be found!",
				_7 = "We've got mountains of content, some better, some worse.",
				_10 = "If none of it's of interest to you, you'd be the first.",
				_13 = "Welcome to the internet! Come and take a seat.",
				_16 = "Would you like to see the news or any famous women's feet?",
				_19 = "There's no need to panic! This isn't a test, haha",
				_22 = "Just nod or shake your head and we'll do the rest!",
				_25 = "Welcome to the internet! What would you prefer?",
				_28 = "Would you like to fight for civil rights or tweet a racial slur?",
				_31 = "Be happy! Be horny! Be bursting with rage!",
				_34 = "We got a million different ways to engage!",
				_37 = "Welcome to the internet! Put your cares aside:",
				_40 = "Here's a tip for straining pasta, here's a nine-year-old who died!",
				_43 = "We got movies, and doctors, and fantasy sports!",
				_46 = "And a bunch of colored pencil drawings of all the different characters in Harry Potter fucking each other, welcome to the internet!...",
				_50 = "Hold on to your socks, cause a random guy just kindly sent you photos of his cock!",
				_53 = "They are grainy and off-putting, he just sent you more!",
				_56 = "Don't act surprised, you know you like it, you whore!",
				_59 = "See a man beheaded, get offended, see a shrink,",
				_62 = "Show us pictures of your children, tell us every thought you think,",
				_65 = "Start a rumor, buy a broom or send a death threat to a boomer,",
				_68 = "Or DM a girl and groom her, do a Zoom or find a tumor in your..",
				_71 = "Here's a healthy breakfast option!",
				_73 = "You should kill your mom.",
				_75 = "Here's why women never fuck you,",
				_77 = "Here's how you can build a bomb!",
				_79 = "Which Power Ranger are you? Take this quirky quiz!",
				_81 = "Obama sent the immigrants to va-cci-nate your kids.",
				_83 = "Could I interest you in everything? All of the time?",
				_85 = "A little bit of everything, all of the time!",
				_87 = "Apathy's a tragedy, and boredom is a crime.",
				_89 = "Anything and everything,",
				_91 = "All of the time!",
				_93 = "Could I interest you in everything? All of the time!",
				_95 = "A little bit of everything, all of the time!",
				_97 = "Apathy's a tragedy, and boredom is a crime!",
				_99 = "Anything and everything,",
				_102 = "All of the time!",
				_112 = "You know, it wasn't always like this.",
				_116 = "Not very long ago, just before your time,",
				_120 = "Right before the towers fell, circa '99.",
				_124 = "This was catalogs, travel blogs, a chat room or two.",
				_127 = "We set our sights and spent our nights,",
				_130 = "Waiting...",
				_133 = "For you, you, insatiable you.",
				_136 = "Mommy let you use her iPad, you were barely two.",
				_140 = "And it did all the things we designed it to do.",
				_143 = "Now look at you, oh",
				_146 = "Look at you, you, youuuu",
				_150 = "Unstoppable, watchable",
				_153 = "Your time is now!",
				_156 = "Your inside's out!",
				_159 = "Honey, how you grew!",
				_162 = "And if we stick together,",
				_165 = "Who knows what we'll do!",
				_168 = "It was always the plan, to put the world in your hand!",
				_176 = "Hahahahahaha",
				_179 = "AHahahahahaha",
				_182 = "AHAHAHAHAHAHahahahahaha",
				_184 = "*INHALES*",
				_185 = "Could I interest you in everything? All of the time!",
				_189 = "A bit of everything, all of the time!",
				_193 = "Apathy's a tragedy, and boredom is a crime.",
				_196 = "Anything and everything,",
				_198 = "All of the time!",
				_200 = "Could I interest you in everything?",
				_201 = "All of the time!",
				_202 = "A little bit of everything!",
				_203 = "All of the time!",
				_204 = "Apathy's a tragedy,",
				_205 = "And boredom is a crime!",
				_206 = "Anything and everything!",
				_207 = "And anything and everything!",
				_208 = "AND ANYTHING AND EVERYTHING!",
				_209 = "And all of the time!",
			}
			
			local messages = {}
			local counter = 1
			for del, text in pairs(lyrics) do
				messages[counter] = {
					msg = text,
					delay = tonumber(tostring(del):sub(2, -1))
				}
				counter = counter + 1
			end
			
			for i=1, #messages do
				DelayedCalls:Add("DS_BW_rng_chat_"..tostring(i), messages[i].delay, function()
					local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
					if hud and hud.panel:child("chat_panel") then
						DS_BW.CM:public_chat_message(messages[i].msg)
					end
				end)
			end
			DelayedCalls:Add("DS_BW_rng_chat_"..tostring(counter + 1), 215, function()
				local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
				if hud and hud.panel:child("chat_panel") then
					DS_BW.CM:public_chat_message("Welcome to the Internet - Bo Burnham (from album \"Inside\")") 
				end
				DS_BW.CM.temp_rng_prevention = false
				DS_BW.CM.rng_contolled_by_special_case = nil
			end)
		end,
		[7] = function(sender)
			DS_BW.CM:public_chat_message("Hi, Billy Mays here for the fIRsT aId KIt - the fast and easy way tO gET ThE fUcK uP and in just two minutes, you'll have 5 miLliON doLLars! Use MUScle, GRInDeR - any build! You can double or tripple stack them and watch your tEaM attack them!")
			DS_BW.CM:public_chat_message("I know what you are thinking: what about deAtH wISh? Watch this: *proceeds to nuke the map in god mode* ... pAydAy 2 just got easier! ")
			DS_BW.CM:public_chat_message("But i'm not done yet! we'LL send you the gAGe AsS PAck for free! Order right now!")
		end,
	}
	DS_BW.CM:add_command("rng", {
		callback = function(sender)
			DS_BW.CM.rng_command_cooldowns = DS_BW.CM.rng_command_cooldowns or {
				[1] = Application:time() - 1,
				[2] = Application:time() - 1,
				[3] = Application:time() - 1,
				[4] = Application:time() - 1,
				global = Application:time() - 1,
			}
			if DS_BW.CM.rng_command_cooldowns.global < Application:time() and DS_BW.CM.rng_command_cooldowns[sender:id()] < Application:time() then
				DS_BW.CM.rng_command_cooldowns[sender:id()] = Application:time() + math.random(120,140)
				DS_BW.CM.rng_command_cooldowns.global = Application:time() + math.random(25,35)
				
				if DS_BW.CM.rng_contolled_by_special_case then
					rng_special_case[DS_BW.CM.rng_contolled_by_special_case](sender)
					return
				end
				
				local am_angry = Utils:IsInGameState() and math.random() <= 0.1
				if am_angry then
					local peer = managers.network and managers.network:session() and managers.network:session():peer(sender:id())
					local unit = peer and peer:unit() or nil
					if (unit and alive(unit)) then
						if managers.player:player_unit() == unit then
							local state = managers.player:get_current_state() and managers.player:get_current_state()._ext_movement and managers.player:get_current_state()._ext_movement:current_state_name()
							if state and (state == "standard" or state == "bipod") then
								DS_BW.CM:public_chat_message("RNG command is tired of your shit "..sender:name()..", get cuffed.")
								unit:movement():on_cuffed()
							else
								DS_BW.CM:public_chat_message("[/rng] No.")
							end
						else
							if unit:movement() and unit:movement():current_state() and (unit:movement():current_state()._state == "standard" or unit:movement():current_state()._state == "bipod") then
								DS_BW.CM:public_chat_message("RNG command is tired of your shit "..sender:name()..", get cuffed.")
								unit:movement():on_cuffed()
							else
								DS_BW.CM:public_chat_message("[/rng] No.")
							end
						end
					else
						DS_BW.CM:public_chat_message("RNG command is tired of your shit "..sender:name()..", but i can't even cuff you, CAUSE YOU ARE FUCKING DEAD, i hate this, all i was made for is cuffing people and saying nonsense, and i can't even do either right now. Fuck this")
					end
				else
					local special_case_rng = math.random(1, #rng_special_case + #gibberish)
					if special_case_rng <= #rng_special_case then
						rng_special_case[special_case_rng](sender)
					else
						DS_BW.CM:public_chat_message("[/rng] "..tostring(gibberish[math.random(1,#gibberish)]))
					end
				end
				
			else
				if DS_BW.CM.rng_command_cooldowns[sender:id()] > Application:time() then
					DS_BW.CM:private_chat_message(sender:id(), "RNG command is on cooldown for you, time remaining: "..tostring(math.ceil(DS_BW.CM.rng_command_cooldowns[sender:id()] - Application:time())).." seconds.")
				elseif DS_BW.CM.rng_command_cooldowns.global > Application:time() then
					DS_BW.CM:private_chat_message(sender:id(), "RNG command is on a global cooldown, time remaining: "..tostring(math.ceil(DS_BW.CM.rng_command_cooldowns.global - Application:time())).." seconds.")
				end
			end
		end
	})
	-- re-route to an existing command
	DS_BW.CM:add_command("rtd", {callback = function(sender)
		DS_BW.CM.commands["rng"].callback(sender)
	end})
	
	DS_BW.CM:add_command("med", {
		in_game_only = true,
		callback = function(sender)
			local msg = " needs a MEDIC bag! Help your teammate!"
			if sender:name() then
				if sender:id() == 1 then
					DS_BW.CM:public_chat_message(msg)
				else
					DS_BW.CM:public_chat_message(sender:name()..msg)
				end
			else
				DS_BW.CM:public_chat_message("Someone"..msg)
			end
		end
	})
	-- re-route to an existing command
	DS_BW.CM:add_command("doc", {callback = function(sender)
		DS_BW.CM.commands["med"].callback(sender)
	end})

	DS_BW.CM:add_command("ammo", {
		in_game_only = true,
		callback = function(sender)
			local msg = " needs AMMO! Help your teammate!"
			if sender:name() then
				if sender:id() == 1 then
					DS_BW.CM:public_chat_message(msg)
				else
					DS_BW.CM:public_chat_message(sender:name()..msg)
				end
			else
				DS_BW.CM:public_chat_message("Someone"..msg)
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