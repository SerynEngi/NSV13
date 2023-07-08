/**
	The overmap JS subsystem. Not to be confused with overmap!
	Why? because it's WIP!, experimental, WIPPPP
*/
PROCESSING_SUBSYSTEM_DEF(JSOvermap)
	name = "JS Overmap"
	wait = 0.2 SECONDS
	stat_tag = "JS"
	init_order = INIT_ORDER_JS_OVERMAP
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING
	/// A list of the created overmap levels
	var/list/datum/overmap_level/overmap_levels = list()
	/// A map-level that exists fore debugging purposes.
	var/datum/overmap_level/debug_level
	var/list/overmap_icons = list()
	var/list/key_overmaps = list(
		"player"=null,
		"miner"=null,
		"PVP"=null
	)

/datum/controller/subsystem/processing/JSOvermap/New()
	. = ..()
	debug_level = new /datum/overmap_level/debug_level()

/datum/controller/subsystem/processing/JSOvermap/Initialize(start_timeofday)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(setup_player_ship)), 5 SECONDS)

/datum/controller/subsystem/processing/JSOvermap/proc/setup_player_ship()
	var/datum/overmap/OM = key_overmaps["player"]
	var/datum/star_system/starter = SSstar_system.system_by_id(OM.starting_system)
	if(!starter)
		CRASH("Cannot find starting system: [OM.starting_system]")
	OM.jump_to_system(starter)

/datum/controller/subsystem/processing/JSOvermap/proc/batch_initial()
	//instance(/datum/overmap/ship/player/cruiser, debug_level, new /datum/vec5(200, 200, 1, 0, 0))
	instance(/datum/overmap/ship/syndicate, debug_level, new /datum/vec5(1000, 400, debug_level.identifier, 0, 0))
	instance(/datum/overmap/ship/syndicate/cruiser, debug_level, new /datum/vec5(400, 1000, debug_level.identifier, 90, 0))

/datum/controller/subsystem/processing/JSOvermap/proc/batch_grid()
	for (var/i=0, i<3, i++)
		for(var/j=0, j<3, j++)
			if (i % 2)
				instance(/datum/overmap/ship/player/cruiser, debug_level, new /datum/vec5((i+1) * 800, (j+1) * 800, 1, 90, 0))
			else
				instance(/datum/overmap/ship/syndicate/cruiser, debug_level, new /datum/vec5((i+1) * 800, (j+1) * 800, 1, 90, 0))



/datum/controller/subsystem/processing/JSOvermap/proc/instance(type, datum/overmap_level/map, datum/vec5/position)
	var/datum/overmap/OM = new type(map, position.x, position.y, map.identifier, position.angle, position.velocity.x, position.velocity.y)
	if(map.current_system)
		OM.update_system(map.current_system)
	OM.PostInitialize()
	return OM

/datum/controller/subsystem/processing/JSOvermap/proc/get_overmap(z)
	var/datum/space_level/SL = SSmapping.z_list[z] // Overmaps linked to Zs, like the main ship
	if(SL?.occupying_overmap)
		return SL.occupying_overmap

/datum/controller/subsystem/processing/JSOvermap/proc/ui_static_data_for(mob/user)
	var/list/data = list()
	data["icon_cache"] = list()
	for(var/key in overmap_icons)
		data["icon_cache"][key] = "data:image/jpeg;base64,[overmap_icons[key]]"
	return data

/datum/controller/subsystem/processing/JSOvermap/proc/ui_data_for(mob/user, datum/overmap/target)
	. = list()
	.["map_id"] = target?.map?.identifier || 0
	.["physics_world"] = list()
	var/datum/component/overmap_piloting/OP = user.GetComponent(/datum/component/overmap_piloting)
	//Broadcast this particular client's cached overmap Zoom level.
	var/zoom = 1000
	if(OP != null)
		zoom = OP.zoom_distance
	.["client_zoom"] = zoom
	.["can_pilot"] = OP.rights & OVERMAP_CONTROL_RIGHTS_HELM
	.["control_scheme"] = OP.rights
	.["fps_capability"] = OP.fps_capability
	.["keys"] = target.keys
	.["sensor_mode"] = target.sensor_mode
	for(var/datum/overmap/O in (target?.map?.physics_objects || list(target)))
		var/list/quads = list()
		if(O.armour_quadrants)
			quads = new(4)
			for(var/I = 1; I <=4; I++)
				quads[I] = list(O.armour_quadrants[I].integrity, O.armour_quadrants[I].max_integrity)
		var/list/data = list(
			//icon = O.icon_base64,
			type = O.type,
			active = (target == O),
			thruster_power = O.thruster_power,
			rotation_power = O.rotation_power,
			sensor_range = O.get_sensor_range(),
			armour_quadrants = quads,
			inertial_dampeners = O.inertial_dampeners,
			thermal_signature = O.thermal_signature,
			position = list(O.position.x, O.position.y, O.position.z, O.position.angle, O.position.velocity.ln(), O.position.velocity.x, O.position.velocity.y)
		)
		.["physics_world"] += list(data)

//datum/controller/subsystem/processing/JSOvermap/proc/start_piloting(mob/user, datum/overmap/OM)

//TODO MAP STAYS SAME WHEN JUMPING!!
/datum/overmap_js_panel
	var/datum/overmap_level/selected_level
	var/datum/overmap/active_ship = null
	var/hide_bullets = TRUE
	var/spawn_type = /datum/overmap
	var/spawn_z = 1

/datum/overmap_js_panel/ui_data(mob/user)
	. = SSJSOvermap.ui_data_for(user, active_ship)
	var/list/ships = list()
	for(var/datum/overmap/OM in (selected_level?.physics_objects || list(active_ship)))
		if(hide_bullets && IS_OVERMAP_JS_PROJECTILE(OM))
			continue
		var/list/ship_data = list()
		ship_data["active"] = OM == active_ship
		ship_data["name"] = OM.name
		ship_data["faction"] = OM.faction
		ship_data["type"] = OM.type
		//ship_data["icon"] = OM.icon_base64
		ship_data["datum"] = "\ref[OM]"
		ships[++ships.len] = ship_data
	.["ships"] = ships
	.["spawn_type"] = "[spawn_type]"
	.["spawn_z"] = spawn_z
	.["hide_bullets"] = hide_bullets

/datum/overmap_js_panel/ui_static_data(mob/user)
	var/list/data = SSJSOvermap.ui_static_data_for(user)
	data["static_levels"] = list()
	for (var/datum/overmap_level/level in SSJSOvermap.overmap_levels)
		data["static_levels"] += list(list(
			"id" = level.identifier,
			"datum" = "\ref[level]",
			"name" = level.name,
			"object_count" = length(level.physics_objects),
		))
	return data

/datum/overmap_js_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/overmap_js_panel/ui_interact(mob/user, datum/tgui/ui)
	//sometimes this is called by the physics engine, which means it won't have a usr
	//other times it's called by a string of procs that results in the usr being the panel itself
	if((usr != src) && !check_rights(0, 1, TRUE))
		return
	if (!selected_level)
		selected_level = SSJSOvermap.debug_level
	if(!active_ship)
		active_ship = length(selected_level.physics_objects) ? selected_level.physics_objects[1] : null
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		log_admin_private("[user.ckey] opened the JS overmap panel.")
		ui = new(user, src, "JSOvermapPanel", "JS Overmap Panel")
		user.AddComponent(/datum/component/overmap_piloting/observer, active_ship, ui)
		ui.open()

/datum/overmap_js_panel/ui_act(action, list/params)
	. = ..()
	if (.)
		return
	var/datum/component/overmap_piloting/C = usr.GetComponent(/datum/component/overmap_piloting)
	switch(action)
		if("scroll")
			C.zoom(params["key"])
			return
		if("set_zoom")
			C.set_zoom(params["key"])
			return
		if("fire")
			C.process_fire(params["weapon"], params["coords"])
			return;
		if("keyup")
			C.process_input(params["key"], FALSE)
			return
		if("keydown")
			C.process_input(params["key"], TRUE)
			return
		if("ui_mark_dirty")
			C.mark_dirty(C.target, C.target, params["fps"])
			return
		if("view_vars")
			usr.client.debug_variables(locate(params["target"]))
			return
		// Swap map level - Debugging action
		if ("set_map_level")
			var/target_identifier = params["id"]
			for (var/datum/overmap_level/level in SSJSOvermap.overmap_levels)
				if (level.identifier == target_identifier)
					selected_level = level
					active_ship = length(selected_level.physics_objects) ? selected_level.physics_objects[1] : null
					return TRUE
		//Swap ship. TODO: Remote piloting is also doable here!
		if("track")
			active_ship = locate(params["target"])
			C.target = active_ship
			ui_interact(usr)
			return
		if("swap_control_scheme")
			C.rights = params["target"]
			ui_interact(usr)
		if("toggle_hide_bullets")
			hide_bullets = !hide_bullets
			ui_interact(usr)
	//TODO: spawney buttons to add enemies?
		if("set_spawn_type")
			spawn_type = params["target"]
			ui_interact(usr)
		if("set_spawn_z")
			spawn_z = params["target"]
			ui_interact(usr)
		if("spawn_ship")
			SSJSOvermap.instance(spawn_type, SSJSOvermap.debug_level, new /datum/vec5(rand(0, JS_OVERMAP_TACMAP_SIZE), rand(0, JS_OVERMAP_TACMAP_SIZE), spawn_z, 0))
			ui_interact(usr)
		if("log")
			to_chat(usr, "<span class='notice'>Overmap debug: [params["text"]]</span>")

/client/proc/js_overmap_panel() //Admin Verb for the Overmap Gamemode controller
	set name = "JS Overmap Panel"
	set desc = "Manage the JS overmap"
	set category = "Adminbus"
	var/datum/overmap_js_panel/JS = new()
	JS.ui_interact(usr)
