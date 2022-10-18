proc(_deathmsg, @player, @deathtypeg, @odm,

#Death message colors.
	#Color of victim's name.
	assign(@colorplayer, 7)
	#Color of message.
	assign(@colormsg, c)
	#Color of alternate item, such as the person/entity who killed the victim.
	assign(@coloralt, 9)
	#Color of weapon used in a PvP battle
	assign(@colorweapon, 3)


#---

#error checks
	if(@deathtypeg == '',
		return(color(d).'FAIL (what death?)')
	)
	
	if(@player == '',
		return(color(d).'FAIL (no player?)')
	)

#everything is uppercase here.
	assign(@deathtype, to_upper(@deathtypeg))

#error checks part 2
	if(@deathtype == 'ENTITY_ATTACK' && @odm == '',
		return(color(d).'FAIL (who did it?)')
	)
	if(@deathtype == 'FIRE_TICK', assign(@deathtype, FIRE))

#---

#CH workaround: WHO attacked em?
	#this splits the death message sentence into individual words.
	assign(@odmsplit, reg_split(' ', @odm))
#	msg(@odmsplit)
	if(@deathtype == 'ENTITY_ATTACK',
	#mob types
		if(array_contains_ic(@odmsplit, Wolf), assign(@entitytype, Wolf))
		if(array_contains_ic(@odmsplit, Golem), assign(@entitytype, IronGolem))
		if(array_contains_ic(@odmsplit, Spider), assign(@entitytype, Spider))
		if(array_contains_ic(@odmsplit, Cave), assign(@entitytype, CaveSpider))
		if(array_contains_ic(@odmsplit, Silverfish), assign(@entitytype, Silverfish))
		if(array_contains_ic(@odmsplit, Zombie), assign(@entitytype, Zombie))
		if(array_contains_ic(@odmsplit, Giant), assign(@entitytype, Giant))
		if(array_contains_ic(@odmsplit, Pigman), assign(@entitytype, PigZombie))
		if(array_contains_ic(@odmsplit, Slime), assign(@entitytype, Slime))
		if(array_contains_ic(@odmsplit, Magma), assign(@entitytype, MagmaCube))
		if(array_contains_ic(@odmsplit, Enderman), assign(@entitytype, Enderman))
		if(array_contains_ic(@odmsplit, Dragon), assign(@entitytype, Enderdragon))
	)
	if(@deathtype == 'PROJECTILE',
	#projectile types
		if(array_contains_ic(@odmsplit, Blaze), assign(@projectiletype, Blaze))
		if(array_contains_ic(@odmsplit, Skeleton), assign(@projectiletype, Skeleton))
		if(array_contains_ic(@odmsplit, arrow), assign(@projectiletype, arrow))	
	)


	#pvp: who did it?
	foreach(@odmsplit, @word, 
		if(array_contains_ic(all_players(), @word) && nequals_ic(@player, @word), assign(@opponent, @word) assign(@pvp1, true))
	)
	#making sure
	if(@pvp1 == 'true',
		if(ponline(@opponent) == true, 
			assign(@pvp, true)
			,
			return(color(d).'FAIL (invisible opponent)') die()
		)

            #convenience
            assign(@hand, pinv(@attacker, null))
         
            #You may want to change this if() depending on how you plan to use the weapon info
            	assign(@weapon,
         
                #bare hands are a different data type than when you are holding an item
                if(!is_array(@hand), 'Fist', data_name(@hand[type]))
		)
	)
	#foreach message. to avoid the victim as 'opponent', if they match, continue.
	#todo: the weapon name?


#todo: make sure if a player is using a name that matches a entity name, that its not pvp.

#The Messages

# Damage notes from https://github.com/sk89q/commandhelper/blob/master/src/main/java/com/laytonsmith/abstraction/MCDamageCause.java

# Damage caused when an entity contacts a block such as a Cactus.
# Damage: 1 (Cactus)
	if(@deathtype == 'CONTACT',
		assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' poked a '.color(@coloralt).'Cactus'.color(@colormsg).', but the cactus poked back.')
		assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' can\'t disco.')
		assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' mistook the '.color(@coloralt).'Cactus'.color(@colormsg).' for a creeper and went in for a hug. '.color(@coloralt).'Cactus '.color(@colormsg).'won.')
	)


# Damage caused when an entity attacks another entity.
# Damage: variable
       	if(@deathtype == 'ENTITY_ATTACK',
	#Mobs	
		if(@entitytype == 'Wolf',
 			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' became a wolf\'s lunch')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' tried to befriend a wolf with an axe.')
			assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' can\'t disco.')
		)	
		if(@entitytype == 'IronGolem',	
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' got stomped on by a '.color(@coloralt).'Iron Golem.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' forgot to run away from the angry '.color(@coloralt).'Iron Golem.')
			assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' can\'t disco.')
		)
		if(@entitytype == 'Spider', 
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' forgot how to get a spider out of his clothes.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' is all webbed up.')
			assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' got trampled by arachnids!')
		)

		if(@entitytype == 'CaveSpider',
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' got poisoned by a '.color(@coloralt).'Cave Spider.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' was out treasure hunting but ended up as lunch for a '.color(@coloralt).'Cave Spider.')
		)
		if(@entitytype == 'Silverfish',	
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' just got stealth-killed by an ankle-biting '.color(@coloralt).'Silverfish'.color(@colormsg).'. Yikes.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' mined the wrong block and got ate by '.color(@coloralt).'Silverfish'.color(@colormsg).'.')
		)
		if(@entitytype == 'Zombie',	
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' became breakfast for a hungry '.color(@coloralt).'Zombie!')
		)
		if(@entitytype == 'Giant',
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' just got stomped on by a '.color(@coloralt).'Giant!')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' is now a waffle.')
		)
		if(@entitytype == 'PigZombie',	
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).'angered the '.color(@coloralt).'Pig Zombies!')
		)
		if(@entitytype == 'Slime',
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' just got Slimed!')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' discovered that '.color(@coloralt).'Slime '.color(@colormsg).'is not something you wear.')
		)
		if(@entitytype == 'MagmaCube',	
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' introduced himself to the kind and gentle '.color(@coloralt).'Magma Cube. '.color(@colormsg).'Since you are seeing this message, it wasn\'t terribly kind nor gentle.')
		)
		if(@entitytype == 'Enderman',
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' looked at a '.color(@coloralt).'Enderman'.color(@colormsg).' the wrong way.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' said Hi to an '.color(@coloralt).'Enderman'.color(@colormsg).', and then was killed by said '.color(@coloralt).'Enderman.')
			assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' was killed by '.color(@coloralt).'Herobrine'.color(@colormsg).'  ... I mean '.color(@coloralt).'Enderman.')
		)
		if(@entitytype == 'Enderdragon',
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' met with the lord of the End. The End.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' tried to steal '.color(@coloralt).'Herobrine\'s'.color(@colormsg).' sweet ride. Turned into lunch.')
			assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' became redstone in the fight against the '.color(@coloralt).' Ender Dragon.')
		)
	#PvP: attack.
		if(@pvp == 'true',
			assign(@msg[0], color(@coloralt).@opponent.color(@colormsg).' killed '.color(@colorplayer).@player.color(@colormsg).' wielding '.color(@colorweapon).@weapon)
			assign(@msg[1], color(@coloralt).@opponent.color(@colormsg).' slays '.color(@colorplayer).@player.color(@colormsg).' with a '.color(@colorweapon).@weapon)
			assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' needs more practice and was killed by '.color(@coloralt).@opponent)
			assign(@msg[3], color(@coloralt).@opponent.color(@colormsg).' hunts '.color(@colorplayer).@player.color(@colormsg).' down with a '.color(@colorweapon).@weapon)
			assign(@msg[4], color(@colorplayer).@player.color(@colormsg).' took a leap of faith but landed on '.color(@coloralt).@opponent.color(@colormsg).'\'s '.color(@colorweapon).@weapon)
			assign(@msg[5], color(8).'Score '.color(@coloralt).@opponent.color(a).' +1'.color(f).' - '.color(@colorplayer).@player.color(c).' 0')
			assign(@msg[6], color(@colorplayer).@player.color(@colormsg).' was fragged by '.color(@coloralt).@opponent)
			assign(@msg[7], color(@colorplayer).@player.color(@colormsg).' is now redstone thanks to '.color(@coloralt).@opponent.color(@colormsg).'\'s '.color(@colorweapon).@weapon)
			assign(@msg[8], color(@coloralt).@opponent.color(@colormsg).' slapped '.color(@colorplayer).@player.color(@colormsg).' around a bit too hard.')
		)

	)

# Damage caused when attacked by a projectile.
# Damage: variable
	if(@deathtype == 'PROJECTILE',
	#How many messages?
		assign(@msgcount, 3)
	#Message content
		if(@projectiletype == 'Blaze',
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' was set ablaze by a '.color(@coloralt).'Blaze.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' is smokin\'. Needs to avoid the '.color(@coloralt).'Blaze.')
		)
		if(@projectiletype == 'Skeleton', 
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' just got snipe\'d by a '.color(@coloralt).'Skeleton!')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' was on the wrong end of the bow')
			assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' found out '.color(@coloralt).'Skeletons '.color(@colormsg).'know how to aim their arrows.')
		)
		if(@projectiletype == 'arrow', 
			assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' did not see the '.color(@coloralt).'Dispenser '.color(@colormsg).'and is now full of holes.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' did not need a '.color(@coloralt).'Dispenser '.color(@colormsg).'there.')
		)
	#PvP: Bow and arrow.
		if(@pvp == 'true',
			assign(@msg[0], color(@coloralt).@opponent.color(@colormsg).' shot '.color(@colorplayer).@player.color(@colormsg).' in the knee.')
			assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' is now redstone thanks to '.color(@coloralt).@opponent.color(@colormsg).'')
			assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' just got snipe\'d by '.color(@coloralt).@opponent.'!')
			assign(@msg[3], color(@colorplayer).@player.color(@colormsg).' needs more practice and was killed by '.color(@coloralt).@opponent)
			assign(@msg[4], color(@colorplayer).@player.color(@colormsg).' can\'t disco.')
		)
	)


# Damage caused by being put in a block
# Damage: 1
	if(@deathtype == 'SUFFOCATION',
		assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' suffocated')
		assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' choked on a ham sandwich')
		assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' successfully held his breath until he died! I think we need a new definition for \'success\'.')
	)

# Damage caused when an entity falls a distance greater than 3 blocks
# Damage: fall height - 3.0
	if(@deathtype == 'FALL',
		assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' fell to their death')
		assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' tripped and fell...down a cliff')
		assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' leapt before looking')
		assign(@msg[3], color(@colorplayer).@player.color(@colormsg).' forgot to bring a parachute')
		assign(@msg[4], color(@colorplayer).@player.color(@colormsg).' learned to fly...briefly...')
		assign(@msg[5], color(@colorplayer).@player.color(@colormsg).' just experienced physics in action')
		assign(@msg[6], color(@colorplayer).@player.color(@colormsg).' forgot to look out below')
		assign(@msg[7], color(@colorplayer).@player.color(@colormsg).' got a little too close to the edge')
		assign(@msg[8], color(@colorplayer).@player.color(@colormsg).' faceplanted into the ground')
		assign(@msg[9], color(@colorplayer).@player.color(@colormsg).' can\'t disco.')
		assign(@msg[10], color(@colormsg).' Skydiving without a parachute again, '.color(@colorplayer).@player.color(@colormsg).'?')
		assign(@msg[11], color(@colorplayer).@player.color(@colormsg).' forgot about the ejector seat.')
	)
#* Damage caused by direct exposure to fire
#* Damage: 1
	if(@deathtype == 'FIRE',
		assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' has a new, slightly charred look!')
		assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' melted.')
		assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' is toast! Literally...')
		assign(@msg[3], color(@colorplayer).@player.color(@colormsg).' just got barbequed')
		assign(@msg[4], color(@colorplayer).@player.color(@colormsg).' forgot to stop, drop, and roll')
		assign(@msg[5], color(@colorplayer).@player.color(@colormsg).' spontaneously combusted')
	)

# Damage caused due to burns caused by fire
# Damage: 1
#        FIRE_TICK,
#redirect to FIRE


# Damage caused by direct exposure to lava
# Damage: 4
	if(@deathtype == 'LAVA',
		assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' just got splattered with '.color(@coloralt).'hot magma.')
		assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' became obsidian')
		assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' was caught in an active volanic eruption')
		assign(@msg[3], color(@colorplayer).@player.color(@colormsg).' found out how to encase himself in carbonite')
	)


# Damage caused by running out of air while in water
# Damage: 2
	if(@deathtype == 'DROWNING',
		assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' is swimming with the fishes')
		assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' sunk to the bottom of the ocean')
		assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' went diving but forgot the diving gear')
		assign(@msg[3], color(@colorplayer).@player.color(@colormsg).' took too long of a bath')
	)

# Damage caused by being in the area when a block explodes.
# Damage: variable
	if(@deathtype == 'BLOCK_EXPLOSION',
	assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' was blown to bits by a pile of '.color(@coloralt).'TNT!')
	assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' tried to launch himself into orbit using '.color(@coloralt).'TNT'.color(@colormsg).'. Result: '.color(4).'Failure!')
	assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' apparently has an explosive personality')
	assign(@msg[3], color(@colormsg).'Careful '.color(@colorplayer).@player.color(@colormsg).', '.color(@coloralt).'TNT '.color(@colormsg).'goes boom')
	assign(@msg[4], color(@colorplayer).@player.color(@colormsg).' cut the wrong wire')
	assign(@msg[5], color(@colorplayer).@player.color(@colormsg).' was attempting to exterminate gophers with '.color(@coloralt).'TNT')
	assign(@msg[6], color(@colorplayer).@player.color(@colormsg).' failed at Hot Potato.')
	)


#* Damage caused by being in the area when an entity, such as a Creeper, explodes.
#* Damage: variable
	if(@deathtype == 'ENTITY_EXPLOSION',
		assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' was blown to bits by a '.color(@coloralt).'Creeper!')
		assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' forgot to run away from the '.color(@coloralt).'Creeper!')
		assign(@msg[2], color(@colormsg).'Hugging '.color(@coloralt).'Creepers'.color(@colormsg).' is not recommended, '.color(@colorplayer).@player.'.')
	)



# Damage caused by falling into the void
# Damage: 4 for players
	if(@deathtype == 'VOID',
	assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' fell into the Big Gap')
	assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' ran out of rocket fuel for their RocketBoots')
	assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' tripped and fell...down a BIG cliff')
	assign(@msg[3], color(@colorplayer).@player.color(@colormsg).' can\'t disco.')
	)

# Damage caused by being struck by lightning
# Damage: 5
	if(@deathtype == 'LIGHTNING',
	assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' became '.color(7).'inFamous.')
	assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' has an electrifying personality.')
	assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' made a suitable ground.')
	)

# Damage caused by committing suicide using the command "/kill"
# Damage: 1000
	if(@deathtype == 'SUICIDE',
	assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' died at the hands of ninja assassins.')
	assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' discovered '.color(@coloralt).'Herobrine\'s'.color(@colormsg).' realm. It did not end well.')
	)


# Damage caused by starving due to having an empty hunger bar
# Damage: 1
	if(@deathtype == 'STARVATION',
	assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' threw up the raw pork he just ate.')
	assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' forgot to eat.')
	)

# Damage caused due to an ongoing poison effect
# Damage: 1
	if(@deathtype == 'POISON',
	assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' shouldn\'t have drank that poison.')
	assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' should be more careful.')
	)

# Damage caused by being hit by a damage potion or spell
# Damage: variable
	if(@deathtype == 'MAGIC',
	assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' was killed by a potion.')
	assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' was magically killed')
	)

# Custom damage.
# Damage: variable
	if(@deathtype == 'CUSTOM',
	assign(@msg[0], color(@colorplayer).@player.color(@colormsg).' died from unknown causes.')
	assign(@msg[1], color(@colorplayer).@player.color(@colormsg).' can\'t disco.')
	assign(@msg[2], color(@colorplayer).@player.color(@colormsg).' has been vaporized.')
	assign(@msg[3], color(@colorplayer).@player.color(@colormsg).' went mental.')
	assign(@msg[4], color(@colorplayer).@player.color(@colormsg).' was running with scissors...now he runs no more.')
	assign(@msg[5], color(@colorplayer).@player.color(@colormsg).' was hit by a falling piano!')
	assign(@msg[6], color(@colorplayer).@player.color(@colormsg).' made a trap but could not get out without setting it off.')
	assign(@msg[7], color(@colorplayer).@player.color(@colormsg).' choked on a ham sandwich.')
	assign(@msg[8], color(@colorplayer).@player.color(@colormsg).' died at the hands of ninja assassins.')
	assign(@msg[9], color(@colorplayer).@player.color(@colormsg).' became '.color(@colorplayer).'inFamous.')
	assign(@msg[10], color(@colorplayer).@player.color(@colormsg).' accidentally pulled the pin on his grenade.')
	)



#Choose the message
	if(@msg !== '',
	#How many messages?
	#note: This count starts counting at 1 even though the aray starts counting at 0
		assign(@msgcount, length(@msg))
	#Now that a message group has been assigned, we must choose a message.
		assign(@deathmsg, @msg[rand(@msgcount)])
	,
	#Or we could fail too.
		assign(@deathmsg, color(d).'FAIL (invalid death type)')
	)
#done.
	return(@deathmsg)


)

