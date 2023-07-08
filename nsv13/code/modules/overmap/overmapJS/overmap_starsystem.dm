#define STELLARBODY_POSITION_CENTER 0
#define STELLARBODY_POSITION_NORTH 1
#define STELLARBODY_POSITION_SOUTH 2
#define STELLARBODY_POSITION_EAST 3
#define STELLARBODY_POSITION_WEST 4

/datum/star_system
	/**
		Objects that currently inhabit this system's grid.
	*/
	var/list/system_grids = list()
	/**
		Any objects that form this system's grid.
		Format: list(list(type, position_anchor))
	*/
	var/list/preset_grids = list()

/datum/star_system/proc/instance_grid(_name, grid)
	RETURN_TYPE(/datum/overmap_level)
	var/datum/overmap_level/system = new /datum/overmap_level(_name, src)
	system_grids += system
	//Now, instance our subgrids (if we have any!)
	for(var/list/L in grid)
		var/type = L[1]
		var/anchor = L[2]
		var/datum/vec5/pos
		switch(anchor)
			if(STELLARBODY_POSITION_CENTER)
				pos = new /datum/vec5((JS_OVERMAP_TACMAP_SIZE / 2), (JS_OVERMAP_TACMAP_SIZE / 2), system.identifier, 0, 0)
			if(STELLARBODY_POSITION_SOUTH)
				pos = new /datum/vec5((JS_OVERMAP_TACMAP_SIZE / 2), (JS_OVERMAP_TACMAP_SIZE / 1.5), system.identifier, 0, 0)
			if(STELLARBODY_POSITION_NORTH)
				pos = new /datum/vec5((JS_OVERMAP_TACMAP_SIZE / 2), (JS_OVERMAP_TACMAP_SIZE / 2.5), system.identifier, 0, 0)
			if(STELLARBODY_POSITION_EAST)
				pos = new /datum/vec5((JS_OVERMAP_TACMAP_SIZE / 2.5), (JS_OVERMAP_TACMAP_SIZE / 2), system.identifier, 0, 0)
			if(STELLARBODY_POSITION_WEST)
				pos = new /datum/vec5((JS_OVERMAP_TACMAP_SIZE / 1.5), (JS_OVERMAP_TACMAP_SIZE / 2), system.identifier, 0, 0)
		SSJSOvermap.instance(type, system, pos)
	return system


/datum/star_system/proc/instance_js_overmap_components()
	//Stupid hack please ignore.
	if(name == "Sol")
		preset_grids = list(list(/datum/overmap/grid_enabled/stellar_body/star, STELLARBODY_POSITION_CENTER),
		list(/datum/overmap/grid_enabled/stellar_body/planet/earth, STELLARBODY_POSITION_EAST),
		list(/datum/overmap/grid_enabled/stellar_body/planet/moon/exploded, STELLARBODY_POSITION_SOUTH)
		)
	//Stupid hack: Ensure there is always SOMETHING in system to jump to.
	preset_grids += list(/datum/overmap/grid_enabled/stellar_body/jump_beacon, STELLARBODY_POSITION_CENTER)
	//First up.. let's get a map level for ourselves :)
	instance_grid(src.name, preset_grids)

/datum/overmap/proc/jump_to_system(datum/star_system/S)
	update_system(S)
	if(map)
		map.transfer_to(src, S.system_grids[1])

/datum/overmap/proc/update_system(datum/star_system/S)
	current_system = S
	if(!SSstar_system.ships[src])
		SSstar_system.ships[src] = list()
		SSstar_system.ships[src]["target_system"] = null
		SSstar_system.ships[src]["current_system"] = S
		SSstar_system.ships[src]["last_system"] = S
		SSstar_system.ships[src]["from_time"] = 0
		SSstar_system.ships[src]["to_time"] = 0
	SSstar_system.ships[src]["current_system"] = S
//Anomalies, effects, planets, etc..

/**
	Any overmap that can, in theory, spawn a subgrid, goes here.
*/
/datum/overmap/grid_enabled
	/**
		Our "subgrid", or, our own point of interest map inside this overmap object.
	*/
	var/datum/overmap_level/subgrid = null
	//If this list is not empty, it will initialise your desired grid.
	//You can nest this as many times as you wish but BE WARNED. This can get messy!
	/**
		Any objects that form this system's grid.
		Format: list(list(type, position_anchor))
		NOTE: Default behaviour is to have the grid_enabled overmap itself in the center of its own grid
		IF you do this, ENSURE you use a decorative subtype with this value set to null!
		OTHERWISE, you will get a shitload of recursion, and see duplicated systems. You have been warned :)
		~Kmc
	*/
	var/list/preset_grids = null

/**
	Intercept a collision IF we have a subgrid.
	This behaviour allows bullets and ships to smoothly fly into the next grid :)
*/
/datum/overmap/grid_enabled/intercept_collision(datum/overmap/OM)
	if(subgrid)
		//TODO: Check the direction of the object flying in, and position it in the subgrid appropriately.
		//Right now, this just teleports you straight up where you were the last time...
		//ALSO TODO: You can't exit a subgrid. Maybe give each subgrid a parent?
		//When you fly off the subgrid's bounds, you shouldn't just continue off into the void.
		OM.map.transfer_to(OM, subgrid)
		return TRUE
	return FALSE

/datum/overmap/grid_enabled/PostInitialize()
	if(!preset_grids)
		return
	//preset_grids += list(/datum/overmap/grid_enabled/stellar_body/jump_beacon, STELLARBODY_POSITION_CENTER)
	to_chat(world, "Instance time: [src.preset_grids.len]")
	subgrid = current_system.instance_grid(src.name, src.preset_grids)
	//Todo: Bit basic but works. All subgrids have their parent star system as origin.
	subgrid.parent = current_system.system_grids[1]
	subgrid.position = position

/datum/overmap/grid_enabled/stellar_body
	icon = 'nsv13/goonstation/icons/effects/overmap_anomalies/stellarbodies.dmi'
	icon_state = "sun"
	name = "Stellar Body"
	integrity = OVERMAP_ARMOUR_THICKNESS_STELLARBODY
	max_integrity = OVERMAP_ARMOUR_THICKNESS_STELLARBODY
	mass = MASS_IMMOBILE
	thermal_signature = THERMAL_SIGNATURE_LARGE

/datum/overmap/grid_enabled/stellar_body/star
	name = "Sun"
	thermal_signature = THERMAL_SIGNATURE_STAR

/datum/overmap/grid_enabled/stellar_body/planet
	icon = 'nsv13/icons/overmap/stellarbodies/planets.dmi'
	icon_state = "planet_rocky"
	name = "Planet"

/datum/overmap/grid_enabled/stellar_body/planet/earth
	icon_state = "planet_earth"
	name = "The Earth"

/datum/overmap/grid_enabled/stellar_body/planet/moon
	icon_state = "planet_rocky"
	name = "Moon"

/datum/overmap/grid_enabled/stellar_body/planet/moon/exploded
	icon_state = "planet_exploded"
	name = "The Moon"
	//The moon's grid.
	//Contains the moon itself (center) and an evil bad guy! oh no!
	preset_grids = list(
		list(/datum/overmap/grid_enabled/stellar_body/planet/moon/exploded/subgrid, STELLARBODY_POSITION_CENTER)
	)

/**
	A decorative version of the moon that does NOT have, for example, a planetary interior. Sits in the middle of the moon's own subgrid.
*/
/datum/overmap/grid_enabled/stellar_body/planet/moon/exploded/subgrid
	preset_grids = null

//This is a really stupid hack because I can't think of a sane way to handle a system with NOTHING in it.
//Please forgive me in the afterlife!
/datum/overmap/grid_enabled/stellar_body/jump_beacon
	name = "Jump Beacon"
	icon_state = ""
	//TODO: make this bullet and everything immune..!
