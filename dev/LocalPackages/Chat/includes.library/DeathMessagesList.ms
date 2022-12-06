proc _chat_death_msg_list(@player, @ogmsg, @opponent, @weapon) {
	if(@player == '' || @player == null) { return(color('d').'FAIL (no player?)') }
	if(@ogmsg == '' || @ogmsg == null) { return(color('d').'FAIL (what death?)') }
	#Death message colors.
	#Color of victim's name.
	@colorplayer = 7
	#Color of message.
	@colormsg = 'c'
	#Color of alternate item, such as the person/entity who killed the victim.
	@coloralt = 9
	#Color of weapon used in a PvP battle
	@colorweapon = 3	
#just format messages here, decide what to use in caller
@ogmsgarray = parse_args(@ogmsg)

@messages = array(
#The Messages

# Damage notes from:
#https://github.com/EngineHub/CommandHelper/blob/master/src/main/java/com/laytonsmith/abstraction/enums/MCDamageCause.java
#https://github.com/EngineHub/CommandHelper/blob/master/src/main/java/com/laytonsmith/abstraction/enums/MCEntityType.java

/*
ALLAY(true, false, MCVersion.MC1_19),
		AREA_EFFECT_CLOUD,
		ARMOR_STAND,
		ARROW,
		AXOLOTL(true, false, MCVersion.MC1_17),
		BAT,
		BEE(true, false, MCVersion.MC1_15),
		BLAZE,
		BOAT,
		CAT(true, false, MCVersion.MC1_14),
		CAVE_SPIDER,
		CHEST_BOAT(true, false, MCVersion.MC1_19),
		CHICKEN,
		COD,
		COW,
		CREEPER,
		DOLPHIN,
		DRAGON_FIREBALL,
		DROPPED_ITEM,
		DROWNED,
		DONKEY,
		EGG,
		ELDER_GUARDIAN,
		ENDERMAN,
		ENDERMITE,
		ENDER_CRYSTAL,
		ENDER_DRAGON,
		ENDER_EYE,
		ENDER_PEARL,
		EVOKER,
		EVOKER_FANGS,
		EXPERIENCE_ORB,
		FALLING_BLOCK,
		FIREBALL,
		FIREWORK,
		FISHING_HOOK(false),
		FOX(true, false, MCVersion.MC1_14),
		FROG(true, false, MCVersion.MC1_19),
		GHAST,
		GIANT,
		GLOW_ITEM_FRAME(true, false, MCVersion.MC1_17),
		GLOW_SQUID(true, false, MCVersion.MC1_17),
		GOAT(true, false, MCVersion.MC1_17),
		GUARDIAN,
		HOGLIN(true, false, MCVersion.MC1_16),
		HORSE,
		HUSK,
		ILLUSIONER,
		IRON_GOLEM,
		ITEM_FRAME,
		LLAMA,
		LLAMA_SPIT(true, true),
		LEASH_HITCH,
		LIGHTNING,
		MAGMA_CUBE,
		MARKER(true, false, MCVersion.MC1_17),
		MINECART,
		MINECART_CHEST,
		MINECART_COMMAND,
		MINECART_FURNACE,
		MINECART_HOPPER,
		MINECART_MOB_SPAWNER,
		MINECART_TNT,
		MULE,
		MUSHROOM_COW,
		OCELOT,
		PAINTING,
		PANDA(true, false, MCVersion.MC1_14),
		PARROT,
		PHANTOM,
		PIG,
		PIGLIN(true, false, MCVersion.MC1_16),
		PIGLIN_BRUTE(true, false, MCVersion.MC1_16_X),
		PILLAGER(true, false, MCVersion.MC1_14),
		PLAYER(false),
		POLAR_BEAR,
		PRIMED_TNT,
		PUFFERFISH,
		RABBIT,
		RAVAGER(true, false, MCVersion.MC1_14),
		SALMON,
		SHEEP,
		SILVERFISH,
		SKELETON,
		SHULKER,
		SHULKER_BULLET,
		SKELETON_HORSE,
		SLIME,
		SMALL_FIREBALL,
		SNOWBALL,
		SNOWMAN,
		SQUID,
		SPECTRAL_ARROW,
		SPIDER,
		SPLASH_POTION,
		STRAY,
		STRIDER(true, false, MCVersion.MC1_16),
		TADPOLE(true, false, MCVersion.MC1_19),
		THROWN_EXP_BOTTLE,
		TRADER_LLAMA(true, false, MCVersion.MC1_14),
		TRIDENT,
		TROPICAL_FISH,
		TURTLE,
		VEX,
		VILLAGER,
		VINDICATOR,
		WANDERING_TRADER(true, false, MCVersion.MC1_14),
		WARDEN(true, false, MCVersion.MC1_19),
		WITCH,
		WITHER,
		WITHER_SKELETON,
		WITHER_SKULL,
		WOLF,
		ZOGLIN(true, false, MCVersion.MC1_16),
		ZOMBIE,
		ZOMBIE_HORSE,
		ZOMBIE_VILLAGER,
		ZOMBIFIED_PIGLIN(true, false, MCVersion.MC1_16),
*/

# Damage caused when an entity contacts a block such as a Cactus.
# Damage: 1 (Cactus)
	'CONTACT': array(
		color(@colorplayer).@player.color(@colormsg).' poked a '.color(@coloralt).'Cactus'.color(@colormsg).', but the cactus poked back.',
		color(@colorplayer).@player.color(@colormsg).' can\'t disco.',
		color(@colorplayer).@player.color(@colormsg).' mistook the '.color(@coloralt).'Cactus'.color(@colormsg).' for a creeper and went in for a hug. '.color(@coloralt).'Cactus '.color(@colormsg).'won.'
	),
# Damage caused when an entity attacks another entity.
# Damage: variable
    'ENTITY_ATTACK': array(
	#Generic 
		'GENERIC': array(
			color(@colorplayer).@player.color(@colormsg).' got attacked by a ... um, I just forgot.',
			color(@colorplayer).@player.color(@colormsg).' died at the hands of ninja assassins.'
		),
	#Mobs	
		'WOLF': array(
 			color(@colorplayer).@player.color(@colormsg).' became a wolf\'s lunch',
			color(@colorplayer).@player.color(@colormsg).' tried to befriend a wolf with an axe.',
			color(@colorplayer).@player.color(@colormsg).' can\'t disco.'
		),	
		'IRON_GOLEM': array(	
			color(@colorplayer).@player.color(@colormsg).' got stomped on by a '.color(@coloralt).'Iron Golem.',
			color(@colorplayer).@player.color(@colormsg).' forgot to run away from the angry '.color(@coloralt).'Iron Golem.',
			color(@colorplayer).@player.color(@colormsg).' can\'t disco.'
		),
		'SPIDER': array( 
			color(@colorplayer).@player.color(@colormsg).' forgot how to get a spider out of his clothes.',
			color(@colorplayer).@player.color(@colormsg).' is all webbed up.',
			color(@colorplayer).@player.color(@colormsg).' got trampled by arachnids!'
		),
		'CAVE_SPIDER': array(
			color(@colorplayer).@player.color(@colormsg).' got poisoned by a '.color(@coloralt).'Cave Spider.',
			color(@colorplayer).@player.color(@colormsg).' was out treasure hunting but ended up as lunch for a '.color(@coloralt).'Cave Spider.'
		),
		'SILVERFISH': array(
			color(@colorplayer).@player.color(@colormsg).' just got stealth-killed by an ankle-biting '.color(@coloralt).'Silverfish'.color(@colormsg).'. Yikes.',
			color(@colorplayer).@player.color(@colormsg).' mined the wrong block and got ate by '.color(@coloralt).'Silverfish'.color(@colormsg).'.'
		),
		'ZOMBIE': array(
			color(@colorplayer).@player.color(@colormsg).' became breakfast for a hungry '.color(@coloralt).'Zombie!'
		),
		'GIANT': array(
			color(@colorplayer).@player.color(@colormsg).' just got stomped on by a '.color(@coloralt).'Giant!',
			color(@colorplayer).@player.color(@colormsg).' is now a waffle.'
		),
		'ZOMBIFIED_PIGLIN': array(
			color(@colorplayer).@player.color(@colormsg).'angered the '.color(@coloralt).'Pig Zombies!',
			color(@colormsg).'All the Gold in the world could not save '.color(@colorplayer).@player
		),
		'SLIME': array(
			color(@colorplayer).@player.color(@colormsg).' just got Slimed!',
			color(@colorplayer).@player.color(@colormsg).' discovered that '.color(@coloralt).'Slime '.color(@colormsg).'is not something you wear.'
		),
		'MAGMA_CUBE': array(
			color(@colorplayer).@player.color(@colormsg).' introduced himself to the kind and gentle '.color(@coloralt).'Magma Cube. '.color(@colormsg).'Since you are seeing this message, it wasn\'t terribly kind nor gentle.'
		),
		'ENDERMAN': array(
			color(@colorplayer).@player.color(@colormsg).' looked at a '.color(@coloralt).'Enderman'.color(@colormsg).' the wrong way.',
			color(@colorplayer).@player.color(@colormsg).' said Hi to an '.color(@coloralt).'Enderman'.color(@colormsg).', and then was killed by said '.color(@coloralt).'Enderman.',
			color(@colorplayer).@player.color(@colormsg).' was killed by '.color(@coloralt).'Herobrine'.color(@colormsg).'  ... I mean '.color(@coloralt).'Enderman.'
		),
		'ENDER_DRAGON': array(
			color(@colorplayer).@player.color(@colormsg).' met with the lord of the End. The End.'
			color(@colorplayer).@player.color(@colormsg).' tried to steal '.color(@coloralt).'Herobrine\'s'.color(@colormsg).' sweet ride. Turned into lunch.',
			color(@colorplayer).@player.color(@colormsg).' became redstone in the fight against the '.color(@coloralt).' Ender Dragon.'
		),
	#PvP: attack.
		'PVP': array(
			color(@coloralt).@opponent.color(@colormsg).' killed '.color(@colorplayer).@player.color(@colormsg).' wielding '.color(@colorweapon).@weapon,
			color(@coloralt).@opponent.color(@colormsg).' slays '.color(@colorplayer).@player.color(@colormsg).' with a '.color(@colorweapon).@weapon,
			color(@colorplayer).@player.color(@colormsg).' needs more practice and was killed by '.color(@coloralt).@opponent,
			color(@coloralt).@opponent.color(@colormsg).' hunts '.color(@colorplayer).@player.color(@colormsg).' down with a '.color(@colorweapon).@weapon,
			color(@colorplayer).@player.color(@colormsg).' took a leap of faith but landed on '.color(@coloralt).@opponent.color(@colormsg).'\'s '.color(@colorweapon).@weapon,
			color(8).'Score '.color(@coloralt).@opponent.color('a').' +1'.color(f).' - '.color(@colorplayer).@player.color('c').' 0',
			color(@colorplayer).@player.color(@colormsg).' was fragged by '.color(@coloralt).@opponent,
			color(@colorplayer).@player.color(@colormsg).' is now redstone thanks to '.color(@coloralt).@opponent.color(@colormsg).'\'s '.color(@colorweapon).@weapon,
			color(@coloralt).@opponent.color(@colormsg).' slapped '.color(@colorplayer).@player.color(@colormsg).' around a bit too hard.'
		)
	),
# Damage caused when attacked by a projectile.
# Damage: variable
	'PROJECTILE': array(
		#Generic 
		'GENERIC': array(
			color(@colorplayer).@player.color(@colormsg).' can\'t disco.',
			color(@colorplayer).@player.color(@colormsg).' got attacked by a ... um, I just forgot.',
			color(@colorplayer).@player.color(@colormsg).' died at the hands of ninja assassins.'
		),
		'BLAZE': array(
			color(@colorplayer).@player.color(@colormsg).' was set ablaze by a '.color(@coloralt).'Blaze.',
			color(@colorplayer).@player.color(@colormsg).' is smokin\' ... Needs to avoid the '.color(@coloralt).'Blaze.'
		),
		'SKELETON': array(
			color(@colorplayer).@player.color(@colormsg).' just got snipe\'d by a '.color(@coloralt).'Skeleton!',
			color(@colorplayer).@player.color(@colormsg).' was on the wrong end of the bow',
			color(@colorplayer).@player.color(@colormsg).' found out '.color(@coloralt).'Skeletons '.color(@colormsg).'know how to aim their arrows.'
		),
		'ARROW': array( 
			color(@colorplayer).@player.color(@colormsg).' did not see the '.color(@coloralt).'Dispenser '.color(@colormsg).'and is now full of holes.',
			color(@colorplayer).@player.color(@colormsg).' did not need a '.color(@coloralt).'Dispenser '.color(@colormsg).'there.',
			color(@colormsg).'Be careful to not hit stray arrows, '.color(@colorplayer).@player.color(@colormsg).'!'
		),
	#PvP: Bow and arrow.
		'PVP': array(
			color(@coloralt).@opponent.color(@colormsg).' shot '.color(@colorplayer).@player.color(@colormsg).' in the knee.',
			color(@colorplayer).@player.color(@colormsg).' is now redstone thanks to '.color(@coloralt).@opponent.color(@colormsg).'',
			color(@colorplayer).@player.color(@colormsg).' just got snipe\'d by '.color(@coloralt).@opponent.'!',
			color(@colorplayer).@player.color(@colormsg).' needs more practice and was killed by the '.color(@colorweapon).@weapon.color(@colormsg).' of '.color(@coloralt).@opponent,
			color(@colorplayer).@player.color(@colormsg).' can\'t disco.'
		)
	),
# Damage caused by being put in a block
# Damage: 1
	'SUFFOCATION': array(
		color(@colorplayer).@player.color(@colormsg).' suffocated',
		color(@colorplayer).@player.color(@colormsg).' choked on a ham sandwich',
		color(@colorplayer).@player.color(@colormsg).' successfully held his breath until he died! I think we need a new definition for \'success\'.'
	),
# Damage caused when an entity falls a distance greater than 3 blocks
# Damage: fall height - 3.0
	'FALL': array(
		color(@colorplayer).@player.color(@colormsg).' fell to their death',
		color(@colorplayer).@player.color(@colormsg).' tripped and fell...down a cliff',
		color(@colorplayer).@player.color(@colormsg).' leapt before looking',
		color(@colorplayer).@player.color(@colormsg).' forgot to bring a parachute',
		color(@colorplayer).@player.color(@colormsg).' learned to fly...briefly...',
		color(@colorplayer).@player.color(@colormsg).' just experienced physics in action',
		color(@colorplayer).@player.color(@colormsg).' forgot to look out below',
		color(@colorplayer).@player.color(@colormsg).' got a little too close to the edge',
		color(@colorplayer).@player.color(@colormsg).' faceplanted into the ground',
		color(@colorplayer).@player.color(@colormsg).' can\'t disco.',
		color(@colormsg).' Skydiving without a parachute again, '.color(@colorplayer).@player.color(@colormsg).'?',
		color(@colorplayer).@player.color(@colormsg).' forgot about the ejector seat.'
	),
#* Damage caused by direct exposure to fire
#* Damage: 1
	'FIRE': array(
		color(@colorplayer).@player.color(@colormsg).' has a new, slightly charred look!',
		color(@colorplayer).@player.color(@colormsg).' melted.',
		color(@colorplayer).@player.color(@colormsg).' is toast! Literally...',
		color(@colorplayer).@player.color(@colormsg).' just got barbequed',
		color(@colorplayer).@player.color(@colormsg).' forgot to stop, drop, and roll',
		color(@colorplayer).@player.color(@colormsg).' spontaneously combusted'
	),
# Damage caused due to burns caused by fire
# Damage: 1
	'FIRE_TICK': array(
		color(@colorplayer).@player.color(@colormsg).' melted.',
		color(@colorplayer).@player.color(@colormsg).' is toast! Literally...',
		color(@colorplayer).@player.color(@colormsg).' just got barbequed',
		color(@colorplayer).@player.color(@colormsg).' forgot to stop, drop, and roll'
	),
# Damage caused by direct exposure to lava
# Damage: 4
	'LAVA': array(
		color(@colorplayer).@player.color(@colormsg).' just got splattered with '.color(@coloralt).'hot magma.',
		color(@colorplayer).@player.color(@colormsg).' became obsidian',
		color(@colorplayer).@player.color(@colormsg).' was caught in an active volanic eruption',
		color(@colorplayer).@player.color(@colormsg).' found out how to encase himself in carbonite'
	),
# Damage caused by running out of air while in water
# Damage: 2
	'DROWNING': array(
		color(@colorplayer).@player.color(@colormsg).' is swimming with the fishes',
		color(@colorplayer).@player.color(@colormsg).' sunk to the bottom of the ocean',
		color(@colorplayer).@player.color(@colormsg).' went diving but forgot the diving gear',
		color(@colorplayer).@player.color(@colormsg).' took too long of a bath'
	),
# Damage caused by being in the area when a block explodes.
# Damage: variable
	'BLOCK_EXPLOSION': array(
	color(@colorplayer).@player.color(@colormsg).' was blown to bits by a pile of '.color(@coloralt).'TNT!',
	color(@colorplayer).@player.color(@colormsg).' tried to launch himself into orbit using '.color(@coloralt).'TNT'.color(@colormsg).'. Result: '.color(4).'Failure!',
	color(@colorplayer).@player.color(@colormsg).' apparently has an explosive personality',
	color(@colormsg).'Careful '.color(@colorplayer).@player.color(@colormsg).', '.color(@coloralt).'TNT '.color(@colormsg).'goes boom',
	color(@colorplayer).@player.color(@colormsg).' cut the wrong wire',
	color(@colorplayer).@player.color(@colormsg).' was attempting to exterminate gophers with '.color(@coloralt).'TNT',
	color(@colorplayer).@player.color(@colormsg).' failed at Hot Potato.'
	),
# Damage caused by being in the area when an entity, such as a Creeper, explodes.
# Damage: variable
	'ENTITY_EXPLOSION': array(
		color(@colorplayer).@player.color(@colormsg).' was blown to bits by a '.color(@coloralt).'Creeper!',
		color(@colorplayer).@player.color(@colormsg).' forgot to run away from the '.color(@coloralt).'Creeper!',
		color(@colormsg).'Hugging '.color(@coloralt).'Creepers'.color(@colormsg).' is not recommended, '.color(@colorplayer).@player.'.'
	),
# Damage caused by falling into the void
# Damage: 4 for players
	'VOID': array(
		color(@colorplayer).@player.color(@colormsg).' fell into the Big Gap',
		color(@colorplayer).@player.color(@colormsg).' ran out of rocket fuel for their RocketBoots',
		color(@colorplayer).@player.color(@colormsg).' tripped and fell...down a BIG cliff',
		color(@colorplayer).@player.color(@colormsg).' can\'t disco.'
	),
# Damage caused by being struck by lightning
# Damage: 5
	'LIGHTNING': array(
		color(@colorplayer).@player.color(@colormsg).' became '.color(7).'inFamous.',
		color(@colorplayer).@player.color(@colormsg).' has an electrifying personality.',
		color(@colorplayer).@player.color(@colormsg).' made a suitable ground.'
	),
# Damage caused by committing suicide using the command "/kill"
# Damage: 1000
	'SUICIDE': array(
		color(@colorplayer).@player.color(@colormsg).' died at the hands of ninja assassins.',
		color(@colorplayer).@player.color(@colormsg).' discovered '.color(@coloralt).'Herobrine\'s'.color(@colormsg).' realm. It did not end well.'
	),
# Damage caused by starving due to having an empty hunger bar
# Damage: 1
	'STARVATION': array(
		color(@colorplayer).@player.color(@colormsg).' threw up the raw pork he just ate.',
		color(@colorplayer).@player.color(@colormsg).' forgot to eat.'
	),
# Damage caused due to an ongoing poison effect
# Damage: 1
	'POISON': array(
		color(@colorplayer).@player.color(@colormsg).' shouldn\'t have drank that poison.',
		color(@colorplayer).@player.color(@colormsg).' should be more careful.'
	),
# Damage caused by being hit by a damage potion or spell
# Damage: variable
	'MAGIC': array(
		color(@colorplayer).@player.color(@colormsg).' was killed by a potion.',
		color(@colorplayer).@player.color(@colormsg).' was magically killed'
	),
#------	
/*
# Damage caused due to a snowman melting
	'MELTING': array()
# Damage caused by Wither potion effect
	'WITHER': 
# Damage caused by being hit by a falling block which deals damage
	'FALLING_BLOCK':
# Damage caused in retaliation to another attack by the Thorns enchantment.
	'THORNS':
# Damage caused by a dragon breathing fire.
	'DRAGON_BREATH':
# Damage caused when an entity runs into a wall.
	'FLY_INTO_WALL':
# Damage caused when an entity steps on MAGMA.
	'HOT_FLOOR':
# Damage caused when an entity is colliding with too many entities due to the maxEntityCramming game rule.
	'CRAMMING':
# Damage caused when an entity attacks another entity in a sweep attack.
	'ENTITY_SWEEP_ATTACK':
# Damage caused when an entity that should be in water is not.
	'DRYOUT':
# Damage caused from freezing.
	'FREEZE':
# Damage caused by the Sonic Boom attack from Warden
	'SONIC_BOOM':
*/	
	
# Custom damage.
# Damage: variable
	'CUSTOM': array(
	color(@colorplayer).@player.color(@colormsg).' died from unknown causes.',
	color(@colorplayer).@player.color(@colormsg).' can\'t disco.',
	color(@colorplayer).@player.color(@colormsg).' has been vaporized.',
	color(@colorplayer).@player.color(@colormsg).' went mental.',
	color(@colorplayer).@player.color(@colormsg).' was running with scissors...now he runs no more.',
	color(@colorplayer).@player.color(@colormsg).' was hit by a falling piano!',
	color(@colorplayer).@player.color(@colormsg).' made a trap but could not get out without setting it off.',
	color(@colorplayer).@player.color(@colormsg).' choked on a ham sandwich.',
	color(@colorplayer).@player.color(@colormsg).' died at the hands of ninja assassins.',
	color(@colorplayer).@player.color(@colormsg).' became '.color(@colorplayer).'inFamous.',
	color(@colorplayer).@player.color(@colormsg).' accidentally pulled the pin on his grenade.'
	)
)

return(@messages)
}