#define COMSIG_JS_OVERMAP_UPDATE "js_overmap_mark_dirty"
#define COMSIG_JS_OVERMAP_STATIC_DATA_UPDATE "js_overmap_static_data_update"
#define OVERMAP_FACTION_NANOTRASEN 1 << 0
#define OVERMAP_FACTION_SOLGOV 1 << 1
#define OVERMAP_FACTION_CIVILIAN 1 << 2
#define OVERMAP_FACTION_SYNDICATE 1 << 3
#define OVERMAP_FACTION_PIRATE 1 << 4
#define OVERMAP_FACTION_PLAYER OVERMAP_FACTION_NANOTRASEN | OVERMAP_FACTION_SOLGOV | OVERMAP_FACTION_CIVILIAN
#define IS_OVERMAP_JS_COLLISION_RESPONSE_ELIGIBLE(O) !istype(O, /datum/overmap/projectile)
#define IS_OVERMAP_JS_PROJECTILE(O) istype(O, /datum/overmap/projectile)
#define IS_OVERMAP_JS_STELLAR_BODY(O) istype(O, /datum/overmap/grid_enabled/stellar_body)

#define OVERMAP_PROJECTILE_FLAGS_NONE 0
#define OVERMAP_PROJECTILE_FLAGS_CAN_BE_SHOT_DOWN 1 << 0

//Overmap damage types. Any kind of weapon you can think of goes here.
#define OVERMAP_DAMAGE_TYPE_KINETIC_SUBCAPITAL 1
#define OVERMAP_DAMAGE_TYPE_KINETIC_CAPITAL 2
#define OVERMAP_DAMAGE_TYPE_ENERGY 3
#define OVERMAP_DAMAGE_TYPE_EXPLOSIVE 4

#define THROW_NEW_NOTIMPLEMENTED_EXCEPTION CRASH("TODO: Not implemented!")

#define OVERMAP_INTERIOR_TYPE_CAPITAL 1
#define OVERMAP_INTERIOR_TYPE_TINY 2

//#define OVERMAP_INTERIOR_METRIC_MOBS "mobs"
#define OVERMAP_INTERIOR_METRIC_Z_LEVELS "Zs"
#define OVERMAP_INTERIOR_METRIC_AREAS "areas"

#define ARMOUR_QUADRANT_NORTH_EAST 4
#define ARMOUR_QUADRANT_NORTH_WEST 3
#define ARMOUR_QUADRANT_SOUTH_WEST 2
#define ARMOUR_QUADRANT_SOUTH_EAST 1
//This ship is assigned to a chosen map layout. No need to load any interior.
#define OVERMAP_ROLE_PRIMARY 1
//This ship needs its interior loading in manually.
#define OVERMAP_ROLE_SECONDARY 2

#define OVERMAP_ARMOUR_THICKNESS_NONE 0
#define OVERMAP_ARMOUR_THICKNESS_LIGHT 250
#define OVERMAP_ARMOUR_THICKNESS_MEDIUM 500
#define OVERMAP_ARMOUR_THICKNESS_HEAVY 1000
#define OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY 1500
#define OVERMAP_ARMOUR_THICKNESS_ABLATIVE 2000
#define OVERMAP_ARMOUR_THICKNESS_GIGA 2500
#define OVERMAP_ARMOUR_THICKNESS_STELLARBODY 9999999

#define SENSOR_MODE_IR 0
#define SENSOR_MODE_GRAVIMETRIC 1

/*
Very basic (and likely temporary) signature defines to serve as a guideline.
Generally, objects should not have *too* strong of a signature as to not make detection trivial.
Very high signatures can however also serve to drown out weak ones, which is a neat trait especially on "passive" bodies like planets, stars, or minor oddities.
small but discernible spikes tend to do best for things-that-are-here-to-look-for, though many do not actively try to remain off your eyes either.
Play around with the ITS yourself and see what fits your vessel.
*/
#define THERMAL_SIGNATURE_NONE 0
#define THERMAL_SIGNATURE_MINISCULE 5 		//Very small things. Fighters, lifeboats in floaty mode, mothballed objects, things trying to sneak up on you.
#define THERMAL_SIGNATURE_SMALL 10	//100?	//Small ships, badly insulated lifeboats, minor objects.
#define THERMAL_SIGNATURE_MEDIUM 30 //150?	//Bigger ships, some stations and settled objectes.
#define THERMAL_SIGNATURE_LARGE 60 //200?	//Some planets or very big sapient-made objects
#define THERMAL_SIGNATURE_STAR 400 //400?	//Stars, or something actively trying to blind your sensors.
/*
Things that are actively generating lots of heat (anything with an active engine, especially high-yield ones), especially warships,
tend to class well above the thermal specs their mass would suggest. Especially when actively engaging, or venting heat.
*/

#define COMSIG_JS_OVERMAP_SYSTEM_RELAY_SOUND "js_system_relay_sound"

#define COMSIG_JS_OVERMAP_SEND_SOUND "js_overmap_sound"
#define COMSIG_JS_OVERMAP_FTL "js_overmap_ftl"
#define COMSIG_JS_OVERMAP_STOP_SEND_SOUND "js_overmap_stop_sound"

/**
	Automatically subscribe mobs to these signals, as it affects them.
	Keep this up to date, please!
*/
#define COMSIG_JS_SIGNALS_TO_SUBSCRIBE_TO list(list(COMSIG_JS_OVERMAP_SEND_SOUND, (.proc/on_overmap_sound)), \
	list(COMSIG_JS_OVERMAP_FTL, (.proc/on_overmap_ftl)),\
	list(COMSIG_JS_OVERMAP_STOP_SEND_SOUND, (.proc/on_sound_cancelled))\
	)
