

/mob
	var/datum/overmap/current_overmap = null
	var/datum/overmap/last_overmap_src = null

/mob/proc/get_or_update_overmap(datum/overmap/new_overmap=null)
	SIGNAL_HANDLER
	if(!new_overmap)
		new_overmap = get_overmap()
	//Update signals. We have a new overmap!
	//Only do this if there are signals attached anyway...
	if(last_overmap_src && last_overmap_src != current_overmap)
		for(var/list/sig in COMSIG_JS_SIGNALS_TO_SUBSCRIBE_TO)
			UnregisterSignal(last_overmap_src, sig[1])
	//Force a new overmap.
	if(new_overmap)
		current_overmap = new_overmap
	//Batch a subscription to all new signals.
	for(var/list/sig in COMSIG_JS_SIGNALS_TO_SUBSCRIBE_TO)
		RegisterSignal(current_overmap, sig[1], sig[2])

/datum/overmap/proc/on_sound_relayed(datum/overmap/OM, sound, message=null, loop=FALSE, channel=null, ignore_self=TRUE)
	if(ignore_self && OM == src)
		return
	relay(sound, loop=loop, message=message, channel=channel, ignore_self=ignore_self)

//Handler procs.
/mob/proc/on_overmap_sound(datum/source, sound, loop, message, channel)
	SIGNAL_HANDLER
	if(message)
		to_chat(src, message)
	if(sound)
		if(can_hear())
			if(channel) //Doing this forbids overlapping of sounds
				SEND_SOUND(src, sound(sound, repeat = loop, wait = 0, volume = 100, channel = channel))
			else
				SEND_SOUND(src, sound(sound, repeat = loop, wait = 0, volume = 100))

/mob/proc/on_sound_cancelled(datum/source, channel)
	stop_sound_channel(channel)

/**
	Handle overmap FTL.
	Updates our parallax.
*/
/mob/proc/on_overmap_ftl(datum/source)
	SIGNAL_HANDLER
	if(client && hud_used && length(client.parallax_layers))
		hud_used.update_parallax(force=TRUE)
	//Handle seasickness, etc.
	var/mob/M = src
	var/nearestDistance = INFINITY
	var/obj/machinery/inertial_dampener/nearestMachine = null

	// Going to helpfully pass this in after seasickness checks, to reduce duplicate machine checks
	for(var/obj/machinery/inertial_dampener/machine as anything in GLOB.inertia_dampeners)
		var/dist = get_dist( M, machine )
		if ( dist < nearestDistance && machine.on )
			nearestDistance = dist
			nearestMachine = machine

	if(iscarbon(M))
		var/mob/living/carbon/L = M
		if(HAS_TRAIT(L, TRAIT_SEASICK))
			if ( nearestMachine )
				var/newNausea = nearestMachine.reduceNausea( nearestDistance, 70 )
				if ( newNausea > 10 )
					to_chat(L, "<span class='warning'>You can feel your head start to swim...</span>")
				L.adjust_disgust( newNausea )
			else
				to_chat(L, "<span class='warning'>You can feel your head start to swim...</span>")
				L.adjust_disgust(pick(70, 100))
	shake_with_inertia(M, 4, 1, list(distance=nearestDistance, machine=nearestMachine))
