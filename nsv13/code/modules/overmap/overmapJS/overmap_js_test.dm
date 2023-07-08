/obj/machinery/computer/ship/js_overmap
	name = "HAHA"
	var/datum/overmap/ship/active_ship

//obj/machinery/computer/ship/js_overmap/process()

/obj/machinery/computer/ship/js_overmap/Initialize(mapload)
	. = ..()
	active_ship = SSJSOvermap.get_overmap(z)//SSJSOvermap.register(new /datum/overmap/ship/player(600,200, 1, 0, 0))
	//SSJSOvermap.register(new /datum/overmap/ship/syndicate(450,100, 1, 180, 0))
	//SSJSOvermap.register(new /datum/overmap/ship/syndicate/frigate(800,100, 1, 180, 0.05))
	//SSJSOvermap.register(new /datum/overmap/ship/syndicate/cruiser(1500,1000, 1, 90, 0))

/obj/machinery/computer/ship/js_overmap/attack_hand(mob/user)
	. = ..()
	if(.)
		ui_interact(user)

/obj/machinery/computer/ship/js_overmap/can_interact(mob/user) //Override this code to allow people to use consoles when flying the ship.
	if(!user.can_interact_with(src)) //Theyre too far away and not flying the ship
		return FALSE
	if((interaction_flags_atom & INTERACT_ATOM_REQUIRES_DEXTERITY) && !user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>You don't have the dexterity to do this!</span>")
		return FALSE
	if(!(interaction_flags_atom & INTERACT_ATOM_IGNORE_INCAPACITATED) && user.incapacitated((interaction_flags_atom & INTERACT_ATOM_IGNORE_RESTRAINED), !(interaction_flags_atom & INTERACT_ATOM_CHECK_GRAB)))
		return FALSE
	return TRUE

/obj/machinery/computer/ship/js_overmap/ui_state(mob/user)
	return GLOB.always_state

/obj/machinery/computer/ship/js_overmap/ui_interact(mob/user, datum/tgui/ui)
	//TODO: need a UI handler for this to REMOVE their piloting component!
	if(!active_ship)
		active_ship = SSJSOvermap.get_overmap(z)
		if(!active_ship)
			visible_message("<span class='danger'>[icon2html(src, viewers(src))] Microcontrollers corrupt. Unable to locate compatible ship.</span>")

	//to_chat(world, "Overmap: UI update...")
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "JSOvermap")
		ui.open()
		user.AddComponent(/datum/component/overmap_piloting, active_ship, ui)
		//TODO: Do we actually _NEED_ autoupdate?
		//We can guarantee a certain degree of precision between the client and server..
		//When the list of overmap ships changes, or a collision occurs etc, we can always update the clients.
		//ui.set_autoupdate(TRUE) // Contact positions

/obj/machinery/computer/ship/js_overmap/ui_data(mob/user)
	. = SSJSOvermap.ui_data_for(user, active_ship)

/obj/machinery/computer/ship/js_overmap/ui_static_data(mob/user)
	. = SSJSOvermap.ui_static_data_for(user)

/obj/machinery/computer/ship/js_overmap/ui_act(action, list/params)
	. = ..()
	if (.)
		return
	var/datum/component/overmap_piloting/C = usr.GetComponent(/datum/component/overmap_piloting)
	//to_chat(world, action)
	//to_chat(world, params)
	//to_chat(world, params["key"])
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
			C.mark_dirty(SSJSOvermap, C.target, params["fps"])
			return
	//active_ship.position.x += 0.1;
