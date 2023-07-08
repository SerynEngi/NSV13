
/**
	WIP behaviour:

	Primary goal:

	Locate Targets,
	Engage Targets,
	Flee if necessary
*/

/datum/goap_action/locate_targets
	name = "Locate Targets"
	preconditions = list(
		//Can't already have a target.
		GOAP_PRECONDITION_HAS_ANY_TARGET = FALSE
	)
	effects = list(
		GOAP_PRECONDITION_HAS_ANY_TARGET = TRUE
	)
	cost = GOAP_COST_SMALL

///Return all ships visible to the ship's short band sensors.
/datum/goap_action/locate_targets/proc/get_sensor_visible_ships(datum/component/overmap_ai_agent/agent)
	var/list/L = agent.holder.get_sensor_visible_ships().Copy()
	for(var/datum/overmap/OM in L)
		if(!agent.holder.can_see(OM))
			L -= OM
	return L

/datum/goap_action/proc/filter_valid_targets(list/ships, datum/component/overmap_ai_agent/agent)
	RETURN_TYPE(/list)
	for(var/datum/overmap/OM as() in ships)
		//Don't target friendlies! ... or the moon, for that matter.
		if(OM.test_faction(agent.holder) || IS_OVERMAP_JS_STELLAR_BODY(OM))
			ships -= OM
			continue
		//Don't target bullets that we can't shoot down, such as PDC slugs.
		if(IS_OVERMAP_JS_PROJECTILE(OM))
			var/datum/overmap/projectile/P = OM
			if(!(P.projectile_flags & OVERMAP_PROJECTILE_FLAGS_CAN_BE_SHOT_DOWN))
				ships -= OM
				continue
	return ships

//TODO: Check that the ship has sensors, or that there are targets in system.
//Get a list of all the ships visible to our ship's sensors.
/datum/goap_action/locate_targets/check_procedural_state(datum/component/overmap_ai_agent/agent)
	return filter_valid_targets(get_sensor_visible_ships(agent), agent)?.len

/datum/goap_action/locate_targets/perform(datum/component/overmap_ai_agent/agent)
	agent.targets = filter_valid_targets(get_sensor_visible_ships(agent), agent)
	..()

/*
	Perform a BVR (beyond visual range) scan of all enemies in the system.
	Does NOT require enemies to be visible to the ship, but is a higher cost action as it may alert enemies!
	SEE: overmap_vision.dm
*/
/datum/goap_action/locate_targets/long_range
	name = "Long Range Scan"
	cost = GOAP_COST_MEDIUM

//Return all targets in system, regardless of whether we can actually see them or not!
//TODO: Account for cloaks, stealth, etc.
/datum/goap_action/locate_targets/long_range/get_sensor_visible_ships(datum/component/overmap_ai_agent/agent)
	return agent.holder.get_ships_in_grid()

/datum/goap_action/engage_targets
	name = "Engage Targets"
	preconditions = list(
		//We must have at least one valid target.
		GOAP_PRECONDITION_HAS_ANY_TARGET = TRUE,
		GOAP_PRECONDITION_FLEEING = FALSE
	)
	effects = list(
		//We will end this action in an engagement state. IE, we're fighting!
		GOAP_PRECONDITION_ENGAGING_TARGET = TRUE
	)
	cost = GOAP_COST_HIGH
	//TODO: Change this value based on what weapons the ship has!
	//A fighter will need an engagement range of, for example, 2KM most likely!
	range_requirement = 25 KM

/**
	Precondition: We have any target.
	Procedural precondition: We can actually fire weapons. TODO!
*/
/datum/goap_action/engage_targets/check_procedural_state(datum/component/overmap_ai_agent/agent)
	return TRUE

//We are done engaging ONLY when we can no longer see the primary target, OR it has been destroyed.
/datum/goap_action/engage_targets/is_complete(datum/component/overmap_ai_agent/agent)
	return agent.target == null || QDELETED(agent.target) || !agent.holder.can_see(agent.target)

//We already know that the ship will have targets as the agent must complete the "locate targets" action FIRST.
//If we are lucky enough to have a target, shoot them!
/datum/goap_action/engage_targets/perform(datum/component/overmap_ai_agent/agent)
	//TODO: Needs a signal for a new target entering the battlefield!
	var/datum/overmap/largest_target = null
	var/list/filtered_targets = list()
	for(var/datum/overmap/OM in agent.targets)
		if(!largest_target || OM.mass > largest_target.mass)
			largest_target = OM
		if(!filtered_targets["[OM.mass]"])
			filtered_targets["[OM.mass]"] = list()
		filtered_targets["[OM.mass]"] += OM
	//TODO:
	/*
		Turn to face largest gun's firing arc at largest target.
		Flyswatter anything else that's nearby.
		Then shoot at all the targets in agent.targets :)
	*/
	agent.holder.point_towards(largest_target.position)
	agent.target = largest_target
	//Ultra basic example of target filtering.
	for(var/KL in filtered_targets)
		var/list/L = filtered_targets[KL]
		for(var/datum/overmap/target in L)
			var/target_angle = target.get_angle_to(agent.holder)
			switch(target.mass)
				//We prefer to shoot bullets and flies with PDC.
				if(MASS_PROJECTILE, MASS_TINY)
					agent.holder.fire_projectile(target_angle, /datum/overmap/projectile, 3)
				//Attack smaller ships with shells and slugs.
				if(MASS_SMALL, MASS_MEDIUM, MASS_MEDIUM_LARGE)
					agent.holder.fire_projectile(target_angle, /datum/overmap/projectile/shell)
				//Attack capital ships with missiles.
				if(MASS_LARGE, MASS_TITAN, MASS_IMMOBILE)
					agent.holder.fire_projectile(target_angle, /datum/overmap/projectile/warhead)
	return TRUE

/datum/goap_action/patrol
	name = "Patrol"
	cost = GOAP_COST_SMALL
	preconditions = list(
		//In order to patrol, we do not want to have any targets..?
		GOAP_PRECONDITION_HAS_ANY_TARGET = FALSE
	)
	effects = list(
		GOAP_PRECONDITION_PATROLLING = TRUE
	)
	var/datum/vec5/target_position = null
	//We give it a wide berth.. don't need to be too much closer than this!
	range_requirement = 6 KM

/datum/goap_action/patrol/pre_perform(datum/component/overmap_ai_agent/agent)
	if(!target_position)
		var/dir = rand(1,4)
		//NAIVE: Pick a random direction, and flee that way!
		//TODO: Should check which corner the ship is closest to.
		switch(dir)
			if(1)
				target_position = new /datum/vec5(2000, 2000, agent.holder.map.identifier, 0, 0)
			if(2)
				target_position = new /datum/vec5(JS_OVERMAP_TACMAP_SIZE-2000, 2000, agent.holder.map.identifier, 0, 0)
			if(3)
				target_position = new /datum/vec5(2000, JS_OVERMAP_TACMAP_SIZE-2000, agent.holder.map.identifier, 0, 0)
			if(4)
				target_position = new /datum/vec5(JS_OVERMAP_TACMAP_SIZE-2000, JS_OVERMAP_TACMAP_SIZE-2000, agent.holder.map.identifier, 0, 0)
	agent.target = target_position

/datum/goap_action/flee
	name = "Flee"
	preconditions = list(
		GOAP_PRECONDITION_ENGAGING_TARGET = FALSE
	)
	effects = list(
		GOAP_PRECONDITION_FLEEING = TRUE,
		//We will be at the system's edge by the time we are done here.
		GOAP_PRECONDITION_AT_SYSTEM_EDGE = TRUE
	)
	cost = GOAP_COST_SMALL
	var/datum/vec5/target_position = null
	//Within 1 grid tile of system edge is fine.
	range_requirement = 2 KM

/**
	Precondition: We have any target.
	Procedural precondition: We can actually fire weapons. TODO!
*/
/datum/goap_action/flee/check_procedural_state(datum/component/overmap_ai_agent/agent)
	return TRUE

/**
	The AI is done "fleeing" when it is no longer on a subgrid.
	When this is the case, it should eventually plan a route to the nearest friendly shipyard to repair.
	Then, FTL through the jump route to get there.
*/
/datum/goap_action/flee/is_complete(datum/component/overmap_ai_agent/agent)
	//When we have reached the edge of the map...
	//We must also HAVE a map edge chosen.
	return !(agent.holder.map?.parent)

/datum/goap_action/flee/pre_perform(datum/component/overmap_ai_agent/agent)
	if(!target_position)
		var/dir = rand(1,4)
		//NAIVE: Pick a random direction, and flee that way!
		//TODO: Should check which corner the ship is closest to.
		switch(dir)
			if(1)
				target_position = new /datum/vec5(0, 0, agent.holder.map.identifier, 0, 0)
			if(2)
				target_position = new /datum/vec5(JS_OVERMAP_TACMAP_SIZE, 0, agent.holder.map.identifier, 0, 0)
			if(3)
				target_position = new /datum/vec5(0, JS_OVERMAP_TACMAP_SIZE, agent.holder.map.identifier, 0, 0)
			if(4)
				target_position = new /datum/vec5(JS_OVERMAP_TACMAP_SIZE, JS_OVERMAP_TACMAP_SIZE, agent.holder.map.identifier, 0, 0)
	agent.target = target_position


/datum/goap_action/ftl_jump
	name = "FTL Jump"
	preconditions = list(
		//Must be at the edge of a system (not in a grid), by, for example, fleeing first.
		GOAP_PRECONDITION_AT_SYSTEM_EDGE = TRUE
	)
	effects = list(
		//When we're done, we will be FTL jumping away from trouble...
		GOAP_PRECONDITION_FTL_JUMPING = TRUE
	)
	cost = GOAP_COST_SMALL
	var/datum/star_system/last_system = null

/datum/goap_action/ftl_jump/is_complete(datum/component/overmap_ai_agent/agent)
	//When we have reached the edge of the map...
	return !(agent.holder.current_system != last_system)

/**
	Get a random, friendly system in the agent's system's adjacency list.
	Can return nothing IF there is no friendly system nearby.
	In that case, use get_random_system as a fallback!
*/
/datum/goap_action/proc/get_friendly_system(datum/component/overmap_ai_agent/agent)
	for(var/datum/star_system/S in agent.holder.current_system.adjacency_list)
		if((agent.holder.faction & FACTION_ID_NT || agent.holder.faction & FACTION_ID_NT) && (S.alignment == "nanotrasen" ||  S.alignment == "solgov"))
			return SSstar_system.system_by_id(S)
		if((agent.holder.faction & FACTION_ID_SYNDICATE || agent.holder.faction & FACTION_ID_PIRATES) && (S.alignment == "syndicate" ||  S.alignment == "unaligned"))
			return SSstar_system.system_by_id(S)
	return null

/datum/goap_action/proc/get_random_system(datum/component/overmap_ai_agent/agent)
	return SSstar_system.system_by_id(pick(agent.holder.current_system.adjacency_list))

/**
	TODO: Check we have an FTL drive, that engines are enabled, etc.
*/
/datum/goap_action/ftl_jump/check_procedural_state(datum/component/overmap_ai_agent/agent)
	return TRUE

/datum/goap_action/ftl_jump/perform(datum/component/overmap_ai_agent/agent)
	//TODO: check FTL is spooled!
	if(last_system)
		return
	last_system = agent.holder.current_system
	//Prepare for FTL translation...
	/**
	TODO: We should prepare a jump plan based on the intended action of the AI.
	If we are fleeing, jump to any random system, preferring friendly ones.
	IF we are in a convoy, go to the next target system in the route.
	If we are exploring, prefer brasil systems.

	*/
	var/datum/star_system/target_system = get_friendly_system(agent)
	if(!target_system)
		target_system = get_random_system(agent)
		if(!target_system)
			//We're trapped, doomed even.
			return
	//FTL translation initiated.. beep boop.
	agent.holder.jump_to_system(target_system)
	//Reset the combat timer so they don't immediately try and flee again!
	agent.holder.last_combat_entered = 0
