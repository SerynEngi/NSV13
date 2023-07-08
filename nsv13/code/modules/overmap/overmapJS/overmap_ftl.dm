/datum/component/overmap_ftl_drive
	var/name = "FTL Drive"
	var/datum/overmap/holder
	var/obj/machinery/computer/ship/ftl_core/ftl_drive

/datum/component/overmap_ftl_drive/Initialize()
	src.holder = parent

/datum/overmap/proc/begin_jump(datum/star_system/target_system, force=FALSE)
	return ftl_drive.start_jump(target_system, force)

/datum/overmap/proc/end_jump(datum/star_system/target_system)
	return ftl_drive.end_jump(target_system)

/datum/component/overmap_ftl_drive/proc/start_jump(datum/star_system/target_system, force=FALSE)
	holder.relay(ftl_drive.ftl_start, channel = CHANNEL_IMPORTANT_SHIP_ALERT)
	//desired_angle = 90 //90 degrees AKA face EAST to match the FTL parallax.
	addtimer(CALLBACK(src, PROC_REF(begin_jump), target_system, force), ftl_drive.ftl_startup_time)

/datum/component/overmap_ftl_drive/proc/begin_jump(datum/star_system/target_system, force=FALSE)
	if(ftl_drive?.ftl_state != FTL_STATE_JUMPING)
		if(force)
			ftl_drive.ftl_state = FTL_STATE_JUMPING
		else
			log_runtime("DEBUG: jump_start: aborted jump to [target_system], drive state = [ftl_drive?.ftl_state]")
			return
	if((SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CHECK_INTERDICT, src) & BEING_INTERDICTED) && !force) // Override interdiction if the game is over
		ftl_drive?.radio?.talk_into(ftl_drive, "Warning. Local energy anomaly detected - calculated jump parameters invalid. Performing emergency reboot.", ftl_drive.radio_channel)
		holder.relay('sound/magic/lightning_chargeup.ogg', channel=CHANNEL_IMPORTANT_SHIP_ALERT)
		ftl_drive?.depower()
		log_runtime("DEBUG: jump_start: aborted jump to [target_system] due to interdiction")
		return

	log_runtime("DEBUG: jump_start: jump to [target_system] passed initial checks")
	holder.map?.send_sound(src, 'nsv13/sound/effects/ship/FTL.ogg', FALSE)//Ships just hear a small "crack" when another one jumps

	//TODO: Update parallax on the JS overmap...

	holder.relay(ftl_drive.ftl_loop, loop=TRUE, message="<span class='warning'>You feel the ship lurch forward</span>", channel = CHANNEL_SHIP_ALERT)
	//What the fuck is this, past KMC?
	var/datum/star_system/curr = SSstar_system.ships[holder]["current_system"]
	log_runtime("DEBUG: jump_start: starting jump to [target_system] from [curr]")
	//TODO: This does nothing
	SEND_SIGNAL(holder, COMSIG_SHIP_DEPARTED) // Let missions know we have left the system
	//curr.remove_ship(src)
	var/speed = (curr.dist(target_system) / (ftl_drive.get_jump_speed() * 10)) //TODO: FTL drive speed upgrades.
	SSstar_system.ships[holder]["to_time"] = world.time + speed MINUTES
	//TODO: This does nothing
	SEND_SIGNAL(holder, COMSIG_FTL_STATE_CHANGE)
	if(holder.role == OVERMAP_ROLE_PRIMARY) //Scuffed please fix
		priority_announce("Attention: All hands brace for FTL translation. Destination: [target_system]. Projected arrival time: [station_time_timestamp("hh:mm", world.time + speed MINUTES)] (Local time)","Automated announcement")
	SSstar_system.ships[holder]["target_system"] = target_system
	SSstar_system.ships[holder]["from_time"] = world.time
	SSstar_system.ships[holder]["current_system"] = null
	set_parallax(TRUE)
	addtimer(CALLBACK(src, PROC_REF(end_jump), target_system), speed MINUTES)

/datum/component/overmap_ftl_drive/proc/set_parallax(ftl_start)
	if(!holder.interior)
		return
	var/list/occupying_levels = holder.interior.interior[OVERMAP_INTERIOR_METRIC_Z_LEVELS]
	for(var/datum/space_level/SL as() in occupying_levels)
		if(ftl_start)
			SL.set_parallax("transit", EAST)
		else
			SL.set_parallax(holder.current_system.parallax_property, null)
	SEND_SIGNAL(src, COMSIG_JS_OVERMAP_FTL)


/datum/component/overmap_ftl_drive/proc/end_jump(datum/star_system/target_system)
	holder.jump_to_system(target_system)
	log_runtime("DEBUG: jump_end: exiting hyperspace into [target_system]")
	SSstar_system.ships[holder]["target_system"] = null
	SSstar_system.ships[holder]["current_system"] = target_system
	SSstar_system.ships[holder]["last_system"] = target_system
	SSstar_system.ships[holder]["from_time"] = 0
	SSstar_system.ships[holder]["to_time"] = 0
	SEND_SIGNAL(holder, COMSIG_FTL_STATE_CHANGE)
	holder.relay(ftl_drive.ftl_exit, message="<span class='warning'>You feel the ship lurch to a halt</span>", loop=FALSE, channel = CHANNEL_SHIP_ALERT)
	SEND_SIGNAL(holder, COMSIG_SHIP_ARRIVED) // Let missions know we have arrived in the system
	set_parallax(FALSE)

	/*
	Just like the average SS13 addict, you get NO PULLS.
	var/list/pulled = list()
	for(var/obj/structure/overmap/SOM as() in GLOB.overmap_objects) //Needs to go through global objects due to being in jumpspace not a system.
		if(!SOM.z || SOM.z != reserved_z)
			continue
		if(SOM == src)
			continue
		if(!SOM.z)
			continue
		LAZYADD(pulled, SOM)
	target_system.add_ship(src) //Get the system to transfer us to its location.
	for(var/obj/structure/overmap/SOM in pulled)
		target_system.add_ship(SOM)
	*/
