proc _chat_death_msg_list(@player2, @ogmsg, @opponent, @weapon) {
	if(@player2 == '' || @player2 == null) { return(color('d').'FAIL (no player?)') }
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
#just format messages here, decide what to use in callerdswads
@ogmsgarray = parse_args(@ogmsg)


@messages = yml_decode(read('Messages.yml'))

/*

 %dm_color_player% took a leap of faith but landed on 's %dm_color_weapon%
*/
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
	


return(@messages)
}