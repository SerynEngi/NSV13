/**
	Component declaring the interior of an overmap ship.
	The mere existence of this denotes that a ship uses the SUPER_LEGIT_DAMAGE system.
*/
/datum/component/overmap_interior
	var/datum/overmap/holder = null
	var/list/interior = list(
		OVERMAP_INTERIOR_METRIC_MOBS = list(),\
		OVERMAP_INTERIOR_METRIC_Z_LEVELS = list(),\
		OVERMAP_INTERIOR_METRIC_AREAS = list()
	)
	var/interior_type = OVERMAP_INTERIOR_TYPE_CAPITAL
	var/interior_json_file = null

/datum/component/overmap_interior/Initialize()
	. = ..()
	holder = parent
	if(!istype(holder))
		return COMPONENT_INCOMPATIBLE //Precondition: This is a subtype of overmap.
	if(interior_json_file)
		load_interior()
	if(holder.role == OVERMAP_ROLE_PRIMARY)
		link_to(SSmapping.levels_by_trait(ZTRAIT_STATION))

/datum/component/overmap_interior/proc/link_to(list/z_levels)
	for(var/z in z_levels)
		var/datum/space_level/SL = SSmapping.z_list[z]
		SL.occupying_overmap = holder
		interior[OVERMAP_INTERIOR_METRIC_Z_LEVELS] += z

/datum/component/overmap_interior/proc/load_interior()
	if(!interior_json_file)
		message_admins("Error loading ship, null file passed in.")
		return
	if(!isfile(interior_json_file))
		message_admins("Error loading ship from JSON. Check that the file exists.")
		return
	var/list/json = json_decode(file2text(interior_json_file))
	if(!json)
		return
	//var/shipName = json["map_name"]
	//var/shipType = text2path(json["ship_type"])
	var/mapPath = json["map_path"]
	var/mapFile = json["map_file"]
	var/list/traits = json["traits"]
	if (istext(mapFile))
		if (!fexists("_maps/[mapPath]/[mapFile]"))
			log_world("Map file ([mapPath]/[mapFile]) does not exist!")
			return
	else if (islist(mapFile))
		for (var/file in mapFile)
			if (!fexists("_maps/[mapPath]/[file]"))
				log_world("Map file ([mapPath]/[file]) does not exist!")
				return
	//TODO: Actually load the map file, here!
	//TODO: Use link_to once we get the actual map files...
	THROW_NEW_NOTIMPLEMENTED_EXCEPTION

///Convert an overmap projectile into a physical projectile.
/datum/component/overmap_interior/proc/take_damage(datum/overmap/projectile/P, angle)
	var/theZ = pick(interior[OVERMAP_INTERIOR_METRIC_Z_LEVELS])
	var/startside = pick(GLOB.cardinals)
	var/turf/pickedstart = spaceDebrisStartLoc(startside, theZ)
	var/turf/pickedgoal = locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), theZ)
	var/obj/item/projectile/proj = new P.physical_projectile_type(pickedstart)
	proj.starting = pickedstart
	proj.firer = null
	proj.def_zone = "chest"
	proj.original = pickedgoal
	spawn()
		proj.fire(get_angle(pickedstart,pickedgoal))
		proj.set_pixel_speed(P.position.velocity)
		qdel(P)

/**
	Ships with tiny interiors use the standard damage system, but with added effects.
	We may add certain effects like a chance to smack the pilot with a bullet (through canopy?)
*/
/datum/component/overmap_interior/tiny
	interior_type = OVERMAP_INTERIOR_TYPE_TINY
